#!/bin/bash

SESSION="jarvis"

# Start a new tmux session
tmux new-session -d -s $SESSION

# 0:local
tmux rename-window -t $SESSION:0 'local'
tmux send-keys -t $SESSION:0 'bash; clear' C-m

# 1:unraid
tmux new-window -t $SESSION:1 -n 'unraid'
tmux send-keys -t $SESSION:1 'ssh -i ~/.ssh/id_rsa_unraid root@itg01; clear' C-m

# 2:rhel
tmux new-window -t $SESSION:2 -n 'rhel'
tmux send-keys -t $SESSION:2 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel09a; clear' C-m
tmux split-window -t $SESSION:2 -h
tmux send-keys -t $SESSION:2.1 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel09b; clear' C-m
tmux split-window -t $SESSION:2.0 -v
tmux send-keys -t $SESSION:2.2 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel08a; clear' C-m
tmux split-window -t $SESSION:2.2 -v
tmux send-keys -t $SESSION:2.3 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel08b; clear' C-m

# Manually enforce the layout to even-horizontal for 2x2 grid
tmux select-layout -t $SESSION:2 even-horizontal

# 3:k8s
tmux new-window -t $SESSION:3 -n 'k8s'
tmux send-keys -t $SESSION:3 'cd ~/git/itg/kube; bash; clear' C-m

# Attach to the session
tmux attach-session -t $SESSION
