#!/bin/bash

SESSION="jarvis"

# Start a new tmux session
tmux new-session -d -s $SESSION

# Create windows and run commands
tmux rename-window -t $SESSION:0 'local'
tmux send-keys -t $SESSION:0 'bash; clear' C-m

tmux new-window -t $SESSION:1 -n 'unraid'
tmux send-keys -t $SESSION:1 'ssh -i ~/.ssh/id_rsa_unraid root@itg01' C-m
tmux send-keys -t $SESSION:1 'clear' C-m

tmux new-window -t $SESSION:2 -n 'rhel'
tmux send-keys -t $SESSION:2 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel09a' C-m
tmux split-window -t $SESSION:2 -v
tmux send-keys -t $SESSION:2.1 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel09b' C-m
tmux split-window -t $SESSION:2.1 -h
tmux send-keys -t $SESSION:2.2 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel08a' C-m
tmux split-window -t $SESSION:2.2 -v
tmux send-keys -t $SESSION:2.3 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel08b' C-m

# Add the clear command for each pane after SSH
tmux send-keys -t $SESSION:2 'clear' C-m
tmux send-keys -t $SESSION:2.1 'clear' C-m
tmux send-keys -t $SESSION:2.2 'clear' C-m
tmux send-keys -t $SESSION:2.3 'clear' C-m

tmux new-window -t $SESSION:3 -n 'k8s'
tmux send-keys -t $SESSION:3 'cd ~/git/itg/kube; bash; clear' C-m

# Attach to the session
tmux attach-session -t $SESSION
