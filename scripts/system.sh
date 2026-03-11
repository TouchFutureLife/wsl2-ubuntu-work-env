#!/usr/bin/env bash
# System-level package installation for WSL2 Ubuntu

log_info "Updating package lists and upgrading existing packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

log_info "Installing essential system packages..."
sudo apt-get install -y \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  file \
  git \
  gnupg \
  htop \
  jq \
  less \
  lsb-release \
  man-db \
  net-tools \
  openssh-client \
  software-properties-common \
  tmux \
  tree \
  unzip \
  vim \
  wget \
  xclip \
  zip

log_success "System packages installed."
