#!/usr/bin/env bash

########################
# include the magic
########################
. ../demo-magic.sh


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

pe "subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-extras-rpms"

pe "dnf install -y leapp-upgrade"

pe "leapp --version"

pe "leapp preupgrade --target 8.8"

pe "cat /var/log/leapp/answerfile"

pe "sed -i 's/# confirm =/confirm = true/g' /var/log/leapp/answerfile"

pe "leapp preupgrade --target 8.8"

pe "leapp upgrade --target 8.8 --reboot"

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
