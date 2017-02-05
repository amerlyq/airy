# press "ctrl-e d" to insert the actual date in the form yyyy-mm-dd
insert-datestamp() { LBUFFER+=${(%):-'%D{%Y-%m-%d}'}; }
zle -N insert-datestamp

#k# Insert a timestamp on the command line (yyyy-mm-dd)
bindkey '^ed' insert-datestamp
