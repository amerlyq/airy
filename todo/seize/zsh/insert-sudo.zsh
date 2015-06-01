# insert sudo infront of command
insert_sudo () {
  [[ -z $BUFFER ]] && zle up-history
  if [[ $BUFFER != sudo\ * ]]; then
    zle beginning-of-line
    zle -U "sudo "
  fi
}
zle -N insert-sudo insert_sudo
