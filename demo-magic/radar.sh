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
sudo dnf erase -y tuxcare-radar
sudo rm -f /etc/yum.repos.d/tuxcare-radar.repo

# hide the evidence
clear

# put your demo awesomeness here

pe "cat /etc/almalinux-release"

pe "printf '[tuxcare-radar]\nname=TuxCare Radar\nbaseurl=https://repo.tuxcare.com/radar/\$releasever/\$basearch/\nenabled=1\ngpgcheck=1\nskip_if_unavailable=1\ngpgkey=https://repo.tuxcare.com/radar/RPM-GPG-KEY-TuxCare\n' | sudo tee /etc/yum.repos.d/tuxcare-radar.repo"

pe "sudo dnf install -y tuxcare-radar"

pe "clear"

# hidden server change
sudo sed -i 's|https://radar.tuxcare.com|https://eu.radar.tuxcare.com|' /etc/tuxcare-radar/radar.yaml

pe "sudo sed -i 's/apikey:.*/apikey: 123456-1234-5678/' /etc/tuxcare-radar/radar.yaml"
# -- internal config override (not shown to audience)
sudo sed -i 's/apikey:.*/apikey: 47044768-0917-4f63-9585-62f7959c1328/' /etc/tuxcare-radar/radar.yaml

pe "sudo su -s /bin/bash nobody -c 'tuxcare-radar --config /etc/tuxcare-radar/radar.yaml'"

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
