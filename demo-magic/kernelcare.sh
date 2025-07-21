#!/usr/bin/env bash

########################
# include the magic
########################
. ~/git/demo-magic/demo-magic.sh


########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
# TYPE_SPEED=20

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# text color
# DEMO_CMD_COLOR=$BLACK

# setup

echo "Configuring demo..."

# hide the evidence
clear

# put your demo awesomeness here

pei "cat /etc/almalinux-release"

pei "curl -s -L https://kernelcare.com/installer | sudo bash"

pei "clear"

pei "uname -r"

pei "sudo kcarectl --info"

pei "sudo kcarectl --update"

pe "clear"

pei "uname -r"

pe "sudo kcarectl --patch-info"

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
