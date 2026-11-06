
_fzf_ctrl-t() {
  local FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --height=$(( LINES - 2 < 40 ? LINES - 2 : 40 ))"

  setopt localoptions pipefail no_aliases 2>/dev/null
  local raw
  raw=$(
    FZF_DEFAULT_COMMAND=${FZF_CTRL_T_COMMAND:-} \
    FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --walker=file,dir,follow,hidden --scheme=path" "${FZF_CTRL_T_OPTS-} -m") \
    FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) < /dev/tty
  )

  [[ -z "$raw" ]] && return 1

  local item
  while IFS= read -r item; do
    [[ -n "$item" ]] && echo -n -E "${(q)item} "
  done <<< "$raw"
  echo
}

_fzf_git_log() {
  git rev-parse > /dev/null 2>&1 || return

  git log --date=relative --format="%C(yellow)%h %C(blue)%<(15,trunc)%ad %C(green)%<(15,trunc)%an %C(reset)%C(white)%s %C(reset)%C(auto)%d%C(reset)" --color=always "$@" |
  fzf \
    --layout reverse \
    --multi \
    --ansi \
    --no-sort \
    --height=-2 \
    --bind "ctrl-o:transform:[[ \$(cat {+f} | wc -l) -eq 1 ]] && hash=\$(grep -o '[a-f0-9]\\{7,\\}' <<< {} | head -n 1) && echo \"become:nvim -c 'lua vim.g.diffview_replace_tab = true' -c \\\"DiffviewOpen \$hash^!\\\" > /dev/tty\"" \
    --bind "ctrl-y:execute-silent(cat {+f} | while IFS= read -r line; do grep -o '[a-f0-9]\{7,\}' <<< \"\$line\" | head -n 1; done | tr '\n' ' ' | sd ' $' '' | tee >($FZF_DIR/lib/recents-add.sh git_log) | ucopy)+abort" \
    --prompt '󰄾 ' \
    --bind 'space:put( )' \
    --preview-window down,50%,hidden \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -n 1 | xargs git show --format=full --stat --color=always' |
  while IFS= read -r line; do grep -o "[a-f0-9]\{7,\}" <<< "$line" | head -n 1; done
}

_fzf_git_log_all() {
  _fzf_git_log --all "$@"
}

_fzf_ripgrep() {
  "$FZF_DIR/lua/pickers/ripgrep.sh" "$@"
}

_fzf_processes() {
  local header=$(ps -eo pid,ppid,user,%cpu,%mem,stat,start,time,command | head -n 1)
  ps -eo pid,ppid,user,%cpu,%mem,stat,start,time,command | tail -n +2 |
  fzf "$@" \
    --header "$header" \
    --multi \
    --bind 'ctrl-y:execute-silent(cat {+f} | awk "{print \$1}" | sd "\n" " " | tee >($FZF_DIR/lib/recents-add.sh processes) | ucopy)+abort' \
    --ansi |
  awk '{print $1}'
}

_fzf_docker_images() {
  local header=$(docker images | head -n 1)
  docker images | tail -n +2 |
  fzf "$@" \
    --header "$header" \
    --multi \
    --bind 'ctrl-y:execute-silent(cat {+f} | awk "{print \$1 \":\" \$2}" | sd "\n" " " | tee >($FZF_DIR/lib/recents-add.sh docker_images) | ucopy)+abort' \
    --ansi |
  awk '{print $1":"$2}'
}

_fzf_docker_containers() {
  local header=$(docker ps -a | head -n 1)
  docker ps -a | tail -n +2 |
  fzf "$@" \
    --header "$header" \
    --multi \
    --bind 'ctrl-y:execute-silent(cat {+f} | awk "{print \$NF}" | sd "\n" " " | tee >($FZF_DIR/lib/recents-add.sh docker_containers) | ucopy)+abort' \
    --ansi |
  awk '{print $NF}'
}

_fzf_docker_networks() {
  local header=$(docker network ls | head -n 1)
  docker network ls | tail -n +2 |
  fzf "$@" \
    --header "$header" \
    --multi \
    --bind 'ctrl-y:execute-silent(cat {+f} | awk "{print \$2}" | sd "\n" " " | tee >($FZF_DIR/lib/recents-add.sh docker_networks) | ucopy)+abort' \
    --ansi |
  awk '{print $2}'
}

_fzf_docker_volumes() {
  local header=$(docker volume ls | head -n 1)
  docker volume ls | tail -n +2 |
  fzf "$@" \
    --header "$header" \
    --multi \
    --bind 'ctrl-y:execute-silent(cat {+f} | awk "{print \$2}" | sd "\n" " " | tee >($FZF_DIR/lib/recents-add.sh docker_volumes) | ucopy)+abort' \
    --ansi |
  awk '{print $2}'
}
