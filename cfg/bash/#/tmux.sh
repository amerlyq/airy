#!/bin/sh
SESSION_NAME='dashboard'

tmux has-session -t $SESSION_NAME
if [ $? -ne 0 ]
then
  tmux new-session -d -s $SESSION_NAME -n logs 'sudo tail -f /var/log/messages'
  tmux split-window -t $SESSION_NAME 'sudo tail -f /var/log/daemon.log'
  tmux new-window -c ~               -n update  -t $SESSION_NAME
  tmux new-window                    -n htop    -t $SESSION_NAME htop
  tmux set-window-option -t $SESSION_NAME:update  allow-rename     off
  tmux set-window-option -t $SESSION_NAME:update  monitor-activity off
  tmux set-window-option -t $SESSION_NAME:update  monitor-silence  30
  tmux set-window-option -t $SESSION_NAME:htop    monitor-activity off
fi

tmux attach -t $SESSION_NAME
