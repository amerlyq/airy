if status is-interactive
    # Commands to run in interactive sessions can go here
end
set -g fish_greeting

function _ranger_cwd --on-event fish_exit
  # set --local tmp ${RANGER_TMPDIR:-${XDG_RUNTIME_DIR:-/tmp}/ranger}
  set --local tmp /run/user/1000/ranger
  builtin test -d "$tmp" || command mkdir -p "$tmp"
  # (set +C && printf "%s" "$PWD" > "$tmp/cwd")
  printf "%s" "$PWD" > "$tmp/cwd"
end
