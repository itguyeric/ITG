#!/bin/bash
# Install and configure Demo Magic on vanilla system
# requires GitLab Personal Access Token

TOKEN=$1

clear
touch ~/demoMagic_installer.log

echo "Installing epel repository..."
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm >> ~/demoMagic_installer.log 2>&1
sudo dnf clean all >> ~/demoMagic_installer.log 2>&1

echo "Installing git and pv..."
sudo dnf install -y git pv >> ~/demoMagic_installer.log 2>&1

echo "Cloning repositories..."
mkdir ~/git
cd ~/git/
git clone https://github.com/paxtonhare/demo-magic.git  >> ~/demoMagic_installer.log 2>&1
git clone https://oauth2:$TOKEN@gitlab.com/itguyeric/itg.git  >> ~/demoMagic_installer.log 2>&1

echo ""
echo "Available demos:"
ls -lh ~/git/itg/demo-magic
