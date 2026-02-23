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

pei "cat /etc/redhat-release"

pei "sudo subscription-manager status"

pei "ls -lh /etc/yum.repos.d"

pe "clear"

pei "fips-mode-setup --check"

pei "rpm -qa"

pe "clear"

pei "systemctl list-units --type=service --state=running"

pe "clear"

pei "curl -O https://raw.githubusercontent.com/rocky-linux/rocky-tools/main/migrate2rocky/migrate2rocky9.sh"

pe "chmod +x migrate2rocky9.sh"

pei "sudo ./migrate2rocky9.sh -r"

pe "sudo reboot"


# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
