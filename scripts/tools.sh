#!/usr/bin/env bash
# Developer tools installation for WSL2 Ubuntu

# ── Docker Engine ─────────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  log_info "Installing Docker Engine..."

  # Add Docker's official GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # Add the repository to Apt sources
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  # Allow running Docker without sudo
  sudo groupadd docker 2>/dev/null || true
  sudo usermod -aG docker "$USER"

  log_success "Docker $(docker --version) installed."
  log_warn "You may need to log out and back in (or restart WSL2) for the docker group membership to take effect."
else
  log_warn "Docker is already installed – skipping."
fi

# ── GitHub CLI ────────────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  log_info "Installing GitHub CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y gh
  log_success "GitHub CLI $(gh --version | head -1) installed."
else
  log_warn "GitHub CLI is already installed – skipping."
fi

# ── fzf (fuzzy finder) ────────────────────────────────────────────────────────
if ! command -v fzf &>/dev/null; then
  log_info "Installing fzf..."
  sudo apt-get install -y fzf
  log_success "fzf installed."
else
  log_warn "fzf is already installed – skipping."
fi

# ── ripgrep ───────────────────────────────────────────────────────────────────
if ! command -v rg &>/dev/null; then
  log_info "Installing ripgrep..."
  sudo apt-get install -y ripgrep
  log_success "ripgrep installed."
else
  log_warn "ripgrep is already installed – skipping."
fi

# ── bat (cat with syntax highlighting) ───────────────────────────────────────
if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
  log_info "Installing bat..."
  sudo apt-get install -y bat
  # On Ubuntu, bat is installed as 'batcat'; create an alias if needed
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    mkdir -p "${HOME}/.local/bin"
    ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
  fi
  log_success "bat installed."
else
  log_warn "bat is already installed – skipping."
fi
