exec 'r!mpc -f "\%title\%"|head -1' | norm!>>>>
g/^\ze#\d\+/s//\r/
%!awk '/^$/{a=0}{print(a?"  ":"")$0}/^nick/{a=1}'
