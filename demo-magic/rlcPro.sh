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

# hide the evidence
clear

# put your demo awesomeness here

pei "sudo dnf install -y https://depot.ciq.com/public/files/depot-client/depot/depot.$(uname -m).rpm"

pe "clear"

pei "sudo depot login -u itguyeric -t wram-sp3l-3aa7"

pe "sudo depot list"

pei "sudo depot enable rlc-9"

pe "clear"

pe "sudo dnf repolist enabled"

pei "sudo dnf update -y"

pe "clear"

pei "cat /etc/rocky-release"

pe "sudo dnf repolist enabled |grep -i ciq"

pe "sudo dnf check"

pe "uname -r"

pei "clear"

pe "sudo systemctl list-units --type=service --state=running"

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
