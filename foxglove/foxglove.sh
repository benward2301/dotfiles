foxglove() {
  case "${1:-}" in
    palette|dark|tmtheme) return 1 ;;
    *) printf 'usage: foxglove {palette <hue>|dark|tmtheme}\n' >&2; return 2 ;;
  esac
}
