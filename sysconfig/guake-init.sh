#!/bin/bash

# Adjust current tab
guake -r 'local';

# Create new tabs
guake -n ~/ -r "joplin" -e '/usr/bin/joplin';
guake -n ~/ -r "itg" -e "ssh -t itg 'tmux a'";
#guake -n ~/ -r "kube" -e "kubectl get pods";
