# vim:ft=sh
# /etc/profile
## WARN: relative ordering inside /etc/profile


### Bell ###
case "$TERM" in linux)
  setterm --blank 0    # Disable blanking for virtual consoles
  setterm --blength    # Disable bell
  # setterm --msg on --msglevel 0  # Show debug printk() in console
esac


### Temp ###
# CHG:USE:(pam-tmpdir) https://sources.debian.net/src/pam-tmpdir/
#   BUG: sourced only into 'tmux -s $USER' session
#     => $TMPDIR not present in other vte->tmux->xmonad
#     => BUG: even PATH is not sourced when splitting tmux pane
# zsh vs sh compatibility
#   * usual zsh startup/shutdown scripts are not executed
#   * Login shells source /etc/profile followed by $HOME/.profile
if ! test -d "${TMPDIR-}"; then
  TMPDIR=/tmp/"${LOGNAME-}"
  mkdir -p -m 700 "$TMPDIR"
  export TMPDIR
fi


### Path ###
# DFL path defined in /etc/profile, package extensions are at /etc/profile.d/*
# TODO: distribute to ./env inside |airy/{ruby,cabal}| similar to /etc/profile.d/*
#   => symlink into ~/.config/airy/env/<group.mod> -- to source by all
hash ruby 2>/dev/null && PATH=$PATH:$(ruby -e 'print Gem.user_dir')/bin
hash cabal 2>/dev/null && PATH=~/.cabal/bin:$PATH
PATH=~/.local/bin:$PATH
export PATH
# Deduplicate
# if hash awk 2>/dev/null; then
#   PATH=$(awk -vRS=: '!a[$0]++{printf(NR>1?":%s":"%s"),$a[$1]}' <<<"$PATH")
# fi
