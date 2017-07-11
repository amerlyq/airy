### SSH-agent ###
(( $+commands[gpg-agent] )) || return

# DISABLED:(use gpg.service instead)
# Start the gpg-agent if not already running
# if ! pgrep -x -u "$USER" gpg-agent >/dev/null 2>&1; then
#     gpg-connect-agent /bye >/dev/null 2>&1
# fi
# unset SSH_AGENT_PID

# SSH_AUTH_SOCK=$(gpg-connect-agent 'getinfo ssh_socket_name' /bye | awk '/^D/{print $2}')
# [[ -S "$SSH_AUTH_SOCK" ]] && export SSH_AUTH_SOCK
if [[ ${gnupg_SSH_AUTH_SOCK_by:-0} -ne $$ ]]; then
  SSH_AUTH_SOCK=/run/user/${UID:-1000}/gnupg/S.gpg-agent.ssh
  [[ -S $SSH_AUTH_SOCK ]] || SSH_AUTH_SOCK=~/.gnupg/S.gpg-agent.ssh
  export SSH_AUTH_SOCK
fi

if tty -s; then
  # Refresh gpg-agent tty in case user switches into an X session
  export GPG_TTY=$(tty)
  # Disable GUI prompts inside SSH.
  # [[ -n $SSH_CONNECTION ]] ||
  export PINENTRY_USER_DATA='USE_CURSES=1'

  # CHECK:BUG: correctly work only for last logined ssh
  #   MAYBE:FIX: use 'add-zsh-hook preexec ...' to update before every command?
  # https://unix.stackexchange.com/questions/280879/how-to-get-pinentry-curses-to-start-on-the-correct-tty
  gpg-connect-agent updatestartuptty /bye >/dev/null
fi
