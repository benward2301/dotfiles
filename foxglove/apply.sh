#!/usr/bin/env bash

set -euo pipefail

XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

if [ ! -f "$HOME/.local/share/nvim/foxglove.sh" ]; then
  echo "apply.sh: no integration file at $HOME/.local/share/nvim/foxglove.sh; switch a palette first" >&2
  exit 1
fi
. "$HOME/.local/share/nvim/foxglove.sh"

apply_downstream() {
  local rendered
  rendered=$(foxglove tmtheme) || true
  if [ -z "$rendered" ]; then
    echo "apply.sh: foxglove tmtheme produced nothing; integration script stale?" >&2
    exit 1
  fi
  local tmtheme="$HOME/.local/share/foxglove/tmtheme/foxglove.tmTheme"
  mkdir -p "$(dirname "$tmtheme")"
  printf '%s\n' "$rendered" >"$tmtheme"

  mkdir -p "$HOME/.config/aichat"
  ln -sf "$tmtheme" "$HOME/.config/aichat/dark.tmTheme"
  ln -sf "$tmtheme" "$HOME/.config/aichat/light.tmTheme"
  ln -sf "$tmtheme" "$XDG_CONFIG/bat/themes/foxglove.tmTheme"
  bat cache --build >/dev/null 2>&1 || true
  local lnav_vars="$HOME/.local/share/foxglove/lnav/foxglove-palette.json"
  if [ -f "$lnav_vars" ]; then
    mkdir -p "$HOME/.config/lnav/configs/installed"
    ln -sf "$lnav_vars" "$HOME/.config/lnav/configs/installed/20-foxglove-palette.json"
  fi

  local variant=dark
  foxglove dark || variant=light
  ln -sf "theme-${variant}.yml" "$XDG_CONFIG/eza/theme.yml"
  touch "$HOME/.wezterm.lua"

  local bg bg_inactive fg fg_inactive
  bg=$(foxglove palette base1); bg_inactive=$(foxglove palette base2)
  fg=$(foxglove palette text1); fg_inactive=$(foxglove palette subtext0)

  local gtk_css="$HOME/.config/gtk-3.0/gtk.css"
  if [ -e "$gtk_css" ]; then
    sd "@define-color active_window_bg_color.*" "@define-color active_window_bg_color $bg;" "$gtk_css"
    sd "@define-color inactive_window_bg_color.*" "@define-color inactive_window_bg_color $bg_inactive;" "$gtk_css"
    sd "@define-color active_window_fg_color.*" "@define-color active_window_fg_color $fg;" "$gtk_css"
    sd "@define-color inactive_window_fg_color.*" "@define-color inactive_window_fg_color $fg_inactive;" "$gtk_css"
  fi

  if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    local kde_scheme="$HOME/.local/share/color-schemes/Foxglove.colors"
    mkdir -p "$HOME/.local/share/color-schemes"
    local active_scheme
    active_scheme=$(awk '/^ColorScheme=/ { sub(/^ColorScheme=/, ""); print; exit }' \
      "$HOME/.config/kdeglobals" 2>/dev/null || true)
    [ "$active_scheme" = Foxglove ] && active_scheme=
    local base_scheme=
    local _name="${active_scheme:-BreezeLight}.colors"
    IFS=: read -ra _xdg_dirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for _dir in "$HOME/.local/share" "${_xdg_dirs[@]}"; do
      if [ -f "$_dir/color-schemes/$_name" ]; then
        base_scheme="$_dir/color-schemes/$_name"
        break
      fi
    done
    if [ -n "$base_scheme" ]; then
      cp -f "$base_scheme" "$kde_scheme"
      chmod u+w "$kde_scheme"
      local hex_to_rgb
      hex_to_rgb() { printf '%d,%d,%d' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }
      python3 - "$kde_scheme" \
        "$(hex_to_rgb "$bg")" "$(hex_to_rgb "$bg_inactive")" \
        "$(hex_to_rgb "$fg")" "$(hex_to_rgb "$fg_inactive")" <<'PYEOF'
import sys, configparser
path, bg, bg_inactive, fg, fg_inactive = sys.argv[1:6]
cfg = configparser.RawConfigParser()
cfg.optionxform = str
cfg.read(path)
cfg.set('General', 'Name', 'Foxglove')
for section, sbg, sfg in [('Colors:Header', bg, fg), ('Colors:Header][Inactive', bg_inactive, fg_inactive)]:
    if cfg.has_section(section):
        cfg.set(section, 'BackgroundNormal', sbg)
        cfg.set(section, 'BackgroundAlternate', sbg)
        cfg.set(section, 'ForegroundNormal', sfg)
if cfg.has_section('WM'):
    cfg.set('WM', 'activeBackground', bg)
    cfg.set('WM', 'inactiveBackground', bg_inactive)
    cfg.set('WM', 'activeForeground', fg)
    cfg.set('WM', 'inactiveForeground', fg_inactive)
with open(path, 'w') as f:
    cfg.write(f, space_around_delimiters=False)
PYEOF
      plasma-apply-colorscheme BreezeLight 2>/dev/null || true
      plasma-apply-colorscheme Foxglove
      local _key
      for _key in BackgroundNormal BackgroundAlternate; do
        kwriteconfig6 --notify --file kdeglobals --group Colors:Header --group Inactive \
          --key "$_key" "$(hex_to_rgb "$bg_inactive")"
      done
      kwriteconfig6 --notify --file kdeglobals --group Colors:Header --group Inactive \
        --key ForegroundNormal "$(hex_to_rgb "$fg_inactive")"
      plasma-apply-desktoptheme breeze-dark
    fi
  fi
}

apply_downstream
