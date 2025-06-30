#!/bin/bash

# Fail if python3.11 is not installed
command -v python3.11 >/dev/null 2>&1 || {
  echo >&2 "Installing Python 3.11 and dependencies..."
  sudo dnf install -y python3.11 python3.11-devel
}

# Install system build dependencies (GCC, Python dev headers, Rust)
sudo dnf group install development-tools -y
sudo dnf install -y gcc-c++

# Install Rust toolchain if not already installed
if ! command -v cargo >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source $HOME/.cargo/env
fi

# Ensure AWS credentials are configured
if [ ! -f "$HOME/.aws/credentials" ]; then
  echo "AWS credentials not found."
  if ! command -v aws >/dev/null 2>&1; then
    echo "Installing AWS CLI..."
    sudo dnf install -y awscli
  fi
  echo "Please run 'aws configure' to set up your AWS credentials."
  exit 1
fi

# Ensure AWS_REGION is persisted in bashrc
if ! grep -q 'export AWS_REGION=us-east-2' "$HOME/.bashrc"; then
  echo 'export AWS_REGION=us-east-2' >> "$HOME/.bashrc"
  export AWS_REGION=us-east-2
else
  source "$HOME/.bashrc"
fi

# Clone the repository if it doesn't already exist
mkdir -p ~/git
cd ~/git
if [ ! -d "bedrock-youtube-analyzer" ]; then
  git clone https://github.com/labeveryday/bedrock-youtube-analyzer.git
fi
cd bedrock-youtube-analyzer

# Clean pip cache and previous virtual environment
pip cache purge
rm -rf ~/.cache/pip
rm -rf venv

# Set up new virtual environment using Python 3.11
python3.11 -m venv --copies venv

# Activate the environment
if [ -f "venv/bin/activate" ]; then
  source venv/bin/activate
else
  echo "Virtual environment not found."
  exit 1
fi

# Set compiler flags for pandas compatibility
export CXXFLAGS="-std=c++17"

# Upgrade pip and install requirements
pip install --upgrade pip
pip install -r requirements.txt --prefer-binary | tee pip_install.log

# wrap up
cd ~/git/bedrock-youtube-analyzer

