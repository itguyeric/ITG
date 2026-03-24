#!/usr/bin/env bash

########################
# Check for demo-magic dependency (pv)
########################
if ! command -v pv &>/dev/null; then
    echo "pv not found. Running demo-magic installer..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$SCRIPT_DIR/_install-demoMagic.sh" ]]; then
        bash "$SCRIPT_DIR/_install-demoMagic.sh"
    else
        echo "ERROR: _install-demoMagic.sh not found in $SCRIPT_DIR"
        exit 1
    fi
fi

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

pei "cat /etc/rocky-release"

pei "sudo dnf repolist enabled | grep -i ciq"

pe "clear"

pe "sudo dnf check"

pe "uname -r"

pe "clear"

pei "systemctl list-units --type=service --state=running"

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
