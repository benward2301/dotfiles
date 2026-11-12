#!/usr/bin/env bash

__fzf_preview() {
  local path="$1"

  if [[ -d "$path" ]]; then
    __fzf_preview_directory "$path"
  elif [[ -f "$path" ]]; then
    __fzf_preview_file "$path"
  fi
}

__fzf_preview_directory() {
  local path="$1"

  if command -v eza &>/dev/null; then
    eza -1 --no-quotes --group-directories-first --color=always --icons=always "$path"
  else
    ls -1 "$path"
  fi
}

__fzf_preview_file() {
  local path="$1"

  case "${path##*.}" in
    md|markdown|mdx)
      __fzf_preview_markdown "$path"
      return
      ;;
    json|jsonl)
      __fzf_preview_text "$path"
      return
      ;;
    png|jpg|jpeg|gif|bmp|webp|svg|tiff|ico)
      __fzf_preview_image "$path"
      return
      ;;
    pdf)
      __fzf_preview_pdf "$path"
      return
      ;;
  esac

  if __fzf_preview_is_binary "$path"; then
    __fzf_preview_binary "$path"
  else
    __fzf_preview_text "$path"
  fi
}

__fzf_preview_is_binary() {
  local path="$1"
  local mime
  mime=$(file -bL --mime-encoding "$path" 2>/dev/null)
  [[ "$mime" == "binary" ]]
}

__fzf_preview_markdown() {
  local path="$1"

  if command -v glow &>/dev/null; then
    __fzf_preview_markdown_with_frontmatter "$path" |
      CLICOLOR_FORCE=3 glow -s "${GLAMOUR_STYLE:-dark}" -
  else
    __fzf_preview_text "$path"
  fi
}

__fzf_preview_markdown_with_frontmatter() {
  local path="$1"
  local first_line
  first_line=$(head -n 1 "$path")

  if [[ "$first_line" == "---" ]]; then
    awk '
      NR == 1 && /^---$/ { print "```yaml"; in_frontmatter = 1; next }
      in_frontmatter && /^---$/ { print "```"; in_frontmatter = 0; next }
      { print }
    ' "$path"
  else
    cat "$path"
  fi
}


__fzf_preview_image_format() {
  if [[ -n "${WEZTERM_PANE-}" ]]; then
    echo iterm
  else
    echo symbols
  fi
}

__fzf_preview_image() {
  local path="$1"
  local size="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}"

  if command -v chafa &>/dev/null; then
    local format
    format=$(__fzf_preview_image_format)
    if [[ "$format" != symbols ]] &&
      chafa -f "$format" -s "$size" "$path" 2>/dev/null; then
      return
    fi
    chafa -f symbols -s "$size" "$path"
  elif command -v timg &>/dev/null; then
    timg -g "$size" "$path"
  else
    echo "Install chafa or timg for image preview"
    __fzf_preview_binary "$path"
  fi
}

__fzf_preview_pdf() {
  local path="$1"
  local tmp="/tmp/fzf-preview-pdf-$$"

  if command -v pdftoppm &>/dev/null; then
    pdftoppm -jpeg -f 1 -singlefile "$path" "$tmp" 2>/dev/null &&
      __fzf_preview_image "$tmp.jpg"
    rm -f "$tmp.jpg"
  elif command -v pdftotext &>/dev/null; then
    pdftotext -f 1 -l 1 "$path" -
  else
    echo "Install poppler-utils for PDF preview"
  fi
}

__fzf_preview_binary() {
  local path="$1"

  if command -v xxd &>/dev/null; then
    xxd "$path" | head -500
  elif command -v hexdump &>/dev/null; then
    hexdump -C "$path" | head -500
  else
    od -A x -t x1z -v "$path" | head -500
  fi
}

__fzf_preview_text() {
  local path="$1"

  if command -v bat &>/dev/null; then
    bat --color=always --style=plain "$path"
  else
    cat "$path"
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  __fzf_preview "$@"
fi
