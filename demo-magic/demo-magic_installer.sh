#!/bin/bash
# Install and configure Demo Magic on vanilla system
# requires GitLab Personal Access Token

TOKEN=$1

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf clean all
dnf install -y git pv
mkdir ~/git && cd ~/git/
git clone https://github.com/paxtonhare/demo-magic.git
git clone https://oauth2:$TOKEN@gitlab.com/itguyeric/itg.git
cd ~/git/itg/demo-magic
clear
ls -lh