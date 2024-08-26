#!/bin/bash

SESSION="jarvis"

# Start a new tmux session
tmux new-session -d -s $SESSION

# Create windows and run commands
tmux rename-window -t $SESSION:0 'local'
tmux send-keys -t $SESSION:0 'bash; clear' C-m

tmux new-window -t $SESSION:1 -n 'unraid'
tmux send-keys -t $SESSION:1 'ssh -i ~/.ssh/id_rsa_unraid root@itg01; clear' C-m

tmux new-window -t $SESSION:2 -n 'rhel'
tmux send-keys -t $SESSION:2 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel09a; clear' C-m
tmux split-window -t $SESSION:2 -v
tmux send-keys -t $SESSION:2.1 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel09b; clear' C-m
tmux split-window -t $SESSION:2.0 -h
tmux send-keys -t $SESSION:2.2 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel08a; clear' C-m
tmux split-window -t $SESSION:2.2 -v
tmux send-keys -t $SESSION:2.3 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel08b; clear' C-m

# Set the layout to tiled (2x2 grid)
tmux select-layout -t $SESSION:2 tiled

tmux new-window -t $SESSION:3 -n 'k8s'
tmux send-keys -t $SESSION:3 'cd ~/git/itg/kube; bash; clear' C-m

# Attach to the session
tmux attach-session -t $SESSION
