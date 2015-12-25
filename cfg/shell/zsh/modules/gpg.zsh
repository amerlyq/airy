### SSH-agent ###
(( $+commands[gpg-agent] )) || return


export GPG_TTY=$(tty)

# Start the gpg-agent if not already running
if ! pgrep -x -u "$USER" gpg-agent >/dev/null 2>&1; then
    gpg-connect-agent /bye >/dev/null 2>&1
fi
unset SSH_AGENT_PID

# SSH_AUTH_SOCK=$(gpg-connect-agent 'getinfo ssh_socket_name' /bye | awk '/^D/{print $2}')
# [[ -S "$SSH_AUTH_SOCK" ]] && export SSH_AUTH_SOCK
if [[ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]]; then
    export SSH_AUTH_SOCK=~/.gnupg/S.gpg-agent.ssh
fi

# Refresh gpg-agent tty in case user switches into an X session
gpg-connect-agent updatestartuptty /bye >/dev/null

#ALT# Updates the GPG-Agent TTY before every command since SSH does not set it.
# function _gpg-agent-update-tty {
#   gpg-connect-agent UPDATESTARTUPTTY /bye >/dev/null
# }
# add-zsh-hook preexec _gpg-agent-update-tty

# Disable GUI prompts inside SSH.
[[ -n "$SSH_CONNECTION" ]] || export PINENTRY_USER_DATA='USE_CURSES=1'
