local wezterm = require("wezterm")
local io = require("io")
local os = require("os")
local act = wezterm.action
local config = wezterm.config_builder()

config.default_prog = { "/usr/bin/env", "zsh", "-l" }
config.harfbuzz_features = { "calt=0" }

config.font = wezterm.font("Liga SFMono Nerd Font")
config.show_close_tab_button_in_tabs = false
config.switch_to_last_active_tab_when_closing_tab = true
config.warn_about_missing_glyphs = false
config.default_cursor_style = "SteadyBar"
config.line_height = 1.1
config.window_padding = { bottom = 0 }

config.term = "wezterm"

wezterm.on("gui-startup", function(cmd)
  local _, pane, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

local colorscheme_path = os.getenv("HOME") .. "/.local/share/foxglove/colorscheme.lua"
local colorscheme_file = io.open(colorscheme_path, "r")
local palette = {}
if colorscheme_file then
  colorscheme_file:close()
  palette = dofile(colorscheme_path)
end

config.colors = {
  background = palette.base1,
  foreground = palette.text1,
  cursor_bg = palette.text1,
  cursor_fg = palette.base1,
  cursor_border = palette.text2,
  compose_cursor = palette.red0,
  selection_fg = palette.text2,
  selection_bg = palette.base3,
  quick_select_label_bg = palette.base3 and { Color = palette.base3 } or nil,
  quick_select_match_bg = palette.base3 and { Color = palette.base3 } or nil,
  split = palette.base2,
}

if palette.base1 then
  config.colors.ansi = {
    palette.base2,
    palette.red1,
    palette.green1,
    palette.yellow1,
    palette.blue1,
    palette.magenta1,
    palette.cyan1,
    palette.text1,
  }
  config.colors.brights = {
    palette.subtext1,
    palette.red0,
    palette.green0,
    palette.yellow0,
    palette.blue0,
    palette.magenta0,
    palette.cyan0,
    palette.text0,
  }
end

local function luminance(hex)
  if type(hex) ~= "string" then
    return 0
  end
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  if not (r and g and b) then
    return 0
  end
  return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
end

if palette.dark then
  local t = math.min(luminance(palette.base1) / 0.3, 1.0)
  config.inactive_pane_hsb = {
    saturation = 0.8 + (0.92 - 0.8) * t,
    brightness = 0.7 + (0.88 - 0.7) * t,
  }
else
  config.inactive_pane_hsb = {
    saturation = 0.95,
    brightness = 0.95,
  }
end

local active_bg = palette.base1
local active_fg = palette.text2
local inactive_fg = palette.subtext1

config.window_frame = {
  font_size = 10.5,
  active_titlebar_bg = active_bg,
  inactive_titlebar_bg = active_bg,
}

if palette.base1 then
  config.colors.tab_bar = {
    background = active_bg,
    active_tab = {
      bg_color = active_bg,
      fg_color = active_fg,
    },
    inactive_tab = {
      bg_color = active_bg,
      fg_color = inactive_fg,
    },
    new_tab_hover = {
      bg_color = active_bg,
      fg_color = active_bg,
    },
    new_tab = {
      bg_color = active_bg,
      fg_color = active_bg,
    },
    inactive_tab_edge = active_bg,
  }
end

local function tab_title(tab)
  local pane = tab.active_pane
  local proc_name = string.gsub(pane.foreground_process_name, ".*/", "")
  local cwd = string.gsub(string.gsub(pane.current_working_dir.path, "^/home/[^/]*", "~"), "/$", "")
  local function is_valid_description(title)
    return title and #title > 0 and title ~= "atch"
  end
  local description
  if is_valid_description(tab.tab_title) then
    description = tab.tab_title
  elseif is_valid_description(pane.title) then
    description = pane.title
  end
  return cwd .. ": " .. (description or proc_name)
end

wezterm.on("format-tab-title", function(tab)
  local title = tab_title(tab)
  local domain = tab.active_pane.domain_name
  if domain ~= "local" then
    title = domain .. "://" .. title
  end
  return {
    { Text = tostring(tab.tab_index + 1) .. " " .. title },
  }
end)

wezterm.on("update-status", function(window)
  local workspaces = wezterm.mux.get_workspace_names()
  if #workspaces > 1 then
    local active = window:active_workspace()
    local elements = { { Text = "  " } }
    for i, ws in ipairs(workspaces) do
      local color = ws == active and palette.blue1 or palette.subtext1
      if color then
        table.insert(elements, { Foreground = { Color = color } })
      end
      table.insert(elements, { Text = ws })
      if i < #workspaces then
        table.insert(elements, { Text = "    " })
      end
    end
    table.insert(elements, { Text = "    " })
    window:set_right_status(wezterm.format(elements))
  else
    window:set_right_status("")
  end
end)

config.keys = {
  {
    key = "Enter",
    mods = "SHIFT",
    action = wezterm.action({
      SendString = "\x1b\r",
    }),
  },
  {
    key = "M",
    mods = "CTRL",
    action = wezterm.action({
      SendString = "\x1b\r",
    }),
  },
  {
    key = "z",
    mods = "ALT",
    action = act.TogglePaneZoomState,
  },
  {
    key = "/",
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      local tab = win:active_tab()
      local panes = tab:panes_with_info()

      local current_idx = 1
      for i, p in ipairs(panes) do
        if p.pane:pane_id() == pane:pane_id() then
          current_idx = i
          break
        end
      end

      local prev_idx = current_idx - 1
      if prev_idx < 1 then
        prev_idx = #panes
      end
      panes[prev_idx].pane:activate()
    end),
  },
  {
    key = "?",
    mods = "ALT|SHIFT",
    action = wezterm.action_callback(function(win, pane)
      local tab = win:active_tab()
      local panes = tab:panes_with_info()

      local current_idx = 1
      for i, p in ipairs(panes) do
        if p.pane:pane_id() == pane:pane_id() then
          current_idx = i
          break
        end
      end

      local next_idx = current_idx + 1
      if next_idx > #panes then
        next_idx = 1
      end
      panes[next_idx].pane:activate()
    end),
  },
  {
    key = "9",
    mods = "CTRL",
    action = wezterm.action_callback(function(win, pane)
      local proc = pane:get_foreground_process_info()
      pane:split({
        cwd = proc and proc.cwd or nil,
        direction = "Bottom",
      })
    end),
  },
  {
    key = "0",
    mods = "CTRL",
    action = wezterm.action_callback(function(win, pane)
      local proc = pane:get_foreground_process_info()
      pane:split({
        cwd = proc and proc.cwd or nil,
        direction = "Right",
      })
    end),
  },
  {
    key = "q",
    mods = "ALT",
    action = act.CloseCurrentPane({ confirm = false }),
  },
  {
    key = "N",
    mods = "CTRL",
    action = wezterm.action_callback(function(_, pane)
      local proc = pane:get_foreground_process_info()
      wezterm.mux.spawn_window({
        cwd = proc and proc.cwd or nil,
      })
    end),
  },
  {
    key = "w",
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      local proc = pane:get_foreground_process_info()
      local mux_window = win:mux_window()
      local current_tab_id = win:active_tab():tab_id()
      local current_index = 0
      for i, tab in ipairs(mux_window:tabs()) do
        if tab:tab_id() == current_tab_id then
          current_index = i - 1
          break
        end
      end
      local _, new_pane, _ = mux_window:spawn_tab({
        cwd = proc and proc.cwd or nil,
        domain = { DomainName = "local" },
      })
      win:perform_action(act.MoveTab(current_index + 1), new_pane)
    end),
  },
  {
    key = "Q",
    mods = "ALT",
    action = act.CloseCurrentTab({ confirm = false }),
  },
  {
    key = "Space",
    mods = "CTRL|SHIFT",
    action = act.DisableDefaultAssignment,
  },
  {
    key = "phys:Slash",
    mods = "CTRL|SHIFT",
    action = act.QuickSelect,
  },
  {
    key = "LeftArrow",
    mods = "CTRL|SHIFT",
    action = act.DisableDefaultAssignment,
  },
  {
    key = "RightArrow",
    mods = "CTRL|SHIFT",
    action = act.DisableDefaultAssignment,
  },
  {
    key = "U",
    mods = "CTRL",
    action = act.ScrollByPage(-0.5),
  },
  {
    key = "D",
    mods = "CTRL",
    action = act.ScrollByPage(0.5),
  },
  {
    key = "B",
    mods = "CTRL",
    action = act.ScrollByPage(-1),
  },
  {
    key = "F",
    mods = "CTRL",
    action = act.ScrollByPage(1),
  },
  {
    key = "J",
    mods = "CTRL",
    action = act.ScrollByLine(2),
  },
  {
    key = "K",
    mods = "CTRL",
    action = act.ScrollByLine(-2),
  },
  {
    key = "p",
    mods = "ALT",
    action = act.PasteFrom("Clipboard"),
  },
  {
    key = ",",
    mods = "ALT",
    action = act.ActivateTabRelative(-1),
  },
  {
    key = ".",
    mods = "ALT",
    action = act.ActivateTabRelative(1),
  },
  {
    key = "<",
    mods = "ALT|SHIFT",
    action = act.MoveTabRelative(-1),
  },
  {
    key = ">",
    mods = "ALT|SHIFT",
    action = act.MoveTabRelative(1),
  },
  {
    key = "S",
    mods = "CTRL",
    action = wezterm.action_callback(function(win, pane)
      local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
      os.execute("mkdir -p /tmp/scrollback")
      local name = string.format("/tmp/scrollback/%08x", math.random(0, 0xFFFFFFFF))
      local f = io.open(name, "w+")
      f:write(text)
      f:flush()
      f:close()

      win:copy_to_clipboard(name)
    end),
  },
  {
    key = "E",
    mods = "CTRL",
    action = act.EmitEvent("trigger-nvim-with-scrollback"),
  },
  {
    key = "U",
    mods = "CTRL|ALT",
    action = act.CharSelect,
  },
  {
    key = "P",
    mods = "ALT",
    action = wezterm.action_callback(function(_, pane)
      local handle = io.popen("$HOME/.local/bin/upaste")
      local clip = handle:read("*a")
      handle:close()
      local hash = 5381
      for i = 1, #clip do
        hash = ((hash * 33) + string.byte(clip, i)) % 0xFFFFFFFF
      end
      os.execute("mkdir -p /tmp/clip")
      local name = string.format("/tmp/clip/%08x", hash)
      local f = io.open(name, "w+")
      f:write(clip)
      f:flush()
      f:close()
      pane:send_text(name)
    end),
  },
  {
    key = "S",
    mods = "ALT|SHIFT",
    action = wezterm.action_callback(function(win, pane)
      local target_pane_id = pane:pane_id()
      local proc = pane:get_foreground_process_info()
      pane:split({
        cwd = proc and proc.cwd or nil,
        direction = "Bottom",
        size = 0.4,
        args = {
          "zsh",
          "-lic",
          string.format("${XDG_CONFIG_HOME:-$HOME/.config}/fzf/wezterm/pickers.sh %d", target_pane_id),
        },
      })
    end),
  },
  {
    key = "E",
    mods = "ALT|SHIFT",
    action = wezterm.action_callback(function(win, pane)
      local target_pane_id = pane:pane_id()
      local proc = pane:get_foreground_process_info()
      pane:split({
        cwd = proc and proc.cwd or nil,
        direction = "Bottom",
        size = 0.4,
        args = {
          "zsh",
          "-lic",
          string.format("${XDG_CONFIG_HOME:-$HOME/.config}/fzf/wezterm/recents.sh %d", target_pane_id),
        },
      })
    end),
  },
  {
    key = "T",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(win, pane)
      local target_pane_id = pane:pane_id()
      local proc = pane:get_foreground_process_info()
      pane:split({
        cwd = proc and proc.cwd or nil,
        direction = "Bottom",
        size = 0.4,
        args = {
          "zsh",
          "-lic",
          string.format("${XDG_CONFIG_HOME:-$HOME/.config}/fzf/wezterm/select.sh %d", target_pane_id),
        },
      })
    end),
  },
  {
    key = "C",
    mods = "ALT|SHIFT",
    action = wezterm.action_callback(function(win, pane)
      local target_pane_id = pane:pane_id()
      local proc = pane:get_foreground_process_info()
      pane:split({
        cwd = proc and proc.cwd or nil,
        direction = "Bottom",
        size = 0.4,
        args = {
          "zsh",
          "-lic",
          string.format("${XDG_CONFIG_HOME:-$HOME/.config}/fzf/wezterm/dirs.sh %d", target_pane_id),
        },
      })
    end),
  },
}

local function open_nvim_with_scrollback(window, pane)
  local text = pane:get_text_from_region(0, 0, 99999, 99999)
  text = text:gsub("\n[^\n]*$", "")

  local name = string.format("/tmp/scrollback-%08x", math.random(0, 0xFFFFFFFF))
  local f = io.open(name, "w+")
  f:write(text)
  f:flush()
  f:close()

  local mux_window = window:mux_window()
  local current_tab_id = window:active_tab():tab_id()
  local current_index = 0
  for i, tab in ipairs(mux_window:tabs()) do
    if tab:tab_id() == current_tab_id then
      current_index = i - 1
      break
    end
  end

  local _, new_pane, _ = mux_window:spawn_tab({
    args = {
      "zsh",
      "-lic",
      'exec nvim "$@"',
      "nvim",
      "--cmd",
      "lua vim.g.term_scratch = true",
      "-c",
      "set nowrap",
      "-c",
      "set laststatus=0 noruler",
      "-c",
      "set signcolumn=no",
      "+$",
      name,
    },
  })
  window:perform_action(act.MoveTab(current_index + 1), new_pane)
end

wezterm.on("trigger-nvim-with-scrollback", function(window, pane)
  open_nvim_with_scrollback(window, pane)
end)

for i = 1, 8 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "ALT",
    action = act.ActivateTab(i - 1),
  })
end

local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
smart_splits.apply_to_config(config, {
  modifiers = {
    move = "ALT",
    resize = "ALT|SHIFT",
  },
})

config.quick_select_patterns = {}

table.insert(config.keys, { key = "[", mods = "ALT", action = act.SwitchWorkspaceRelative(-1) })
table.insert(config.keys, { key = "]", mods = "ALT", action = act.SwitchWorkspaceRelative(1) })
table.insert(config.keys, {
  key = "W",
  mods = "ALT",
  action = wezterm.action_callback(function(win, pane)
    local handle = io.popen("$HOME/.local/bin/randname")
    local name = handle:read("*a"):gsub("\n$", "")
    handle:close()
    win:perform_action(
      act.SwitchToWorkspace({
        name = name,
        spawn = { domain = { DomainName = "local" } },
      }),
      pane
    )
  end),
})

return config
