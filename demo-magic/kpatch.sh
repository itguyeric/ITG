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

dnf install -y kpatch

# hide the evidence
clear

# put your demo awesomeness here

pei "cat /etc/redhat-release"

pe "dnf info kpatch"

pe "kpatch list"

clear

pei "uname -r"

pe "dnf list available kpatch-patch*284*"

pe "dnf -y install "kpatch-patch = $(uname -r)""

clear

pei "kpatch list"

pe "rpm -q --changelog $(rpm -qa | grep kpatch-patch)"

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
