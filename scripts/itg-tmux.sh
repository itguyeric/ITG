#!/bin/bash

SESSION="jarvis"

# Check if the session already exists
if ! tmux has-session -t $SESSION 2>/dev/null; then
    # Start a new tmux session
    tmux new-session -d -s $SESSION

    # 0: local
    tmux rename-window -t $SESSION:0 'local'
    tmux send-keys -t $SESSION:0 'clear' C-m

    # 1: unraid
    tmux new-window -t $SESSION:1 -n 'unraid'
    tmux send-keys -t $SESSION:1 'ssh itg01' C-m 'clear' C-m

    # 2: itg03
    tmux new-window -t $SESSION:2 -n 'itg03'
    tmux send-keys -t $SESSION:2 'ssh -i ~/.ssh/id_rsa_ans ansible@itg03' C-m 'clear' C-m
    #
    ## Pane for rhel09a (top-left)
    #tmux send-keys -t $SESSION:2 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel09a' C-m 'clear' C-m
    #
    ## Pane for rhel08a (bottom-left)
    #tmux split-window -t $SESSION:2 -v
    #tmux send-keys -t $SESSION:2.1 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel08a' C-m 'clear' C-m
    #
    ## Pane for rhel09b (top-right)
    #tmux split-window -t $SESSION:2.0 -h
    #tmux send-keys -t $SESSION:2.1 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel09b' C-m 'clear' C-m
    #
    ## Pane for rhel08b (bottom-right)
    #tmux split-window -t $SESSION:2.2 -h
    #tmux send-keys -t $SESSION:2.3 'ssh -i ~/.ssh/id_rsa_ans ansible@rhel08b' C-m 'clear' C-m
    #
    ## Manually enforce the layout to even-horizontal for 2x2 grid
    #tmux select-layout -t $SESSION:2 tiled
    #
    ## 3:k8s
    #tmux new-window -t $SESSION:3 -n 'k8s'
    #tmux send-keys -t $SESSION:3 'cd ~/git/itg/kube' C-m 'clear' C-m
fi

# Attach to the session at the first window
tmux attach-session -t $SESSION:0

