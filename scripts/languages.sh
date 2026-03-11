#!/usr/bin/env bash
# Programming language runtimes and version managers for WSL2 Ubuntu

# ── Node.js via nvm ───────────────────────────────────────────────────────────
NVM_DIR="${HOME}/.nvm"
if [[ ! -d "$NVM_DIR" ]]; then
  log_info "Installing nvm (Node Version Manager)..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  log_warn "nvm is already installed – skipping."
fi

# Source nvm in this shell session so we can use it immediately
export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[[ -s "${NVM_DIR}/nvm.sh" ]] && source "${NVM_DIR}/nvm.sh"

if command -v nvm &>/dev/null; then
  log_info "Installing Node.js LTS via nvm..."
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  log_success "Node.js $(node --version) / npm $(npm --version) installed."
else
  log_warn "nvm could not be sourced; Node.js installation skipped. Re-open your terminal and run 'nvm install --lts'."
fi

# ── Python ────────────────────────────────────────────────────────────────────
log_info "Installing Python 3 and related tools..."
sudo apt-get install -y python3 python3-pip python3-venv python3-dev

# Upgrade pip
python3 -m pip install --upgrade pip --quiet

log_success "Python $(python3 --version) installed."

# ── Go ────────────────────────────────────────────────────────────────────────
GO_VERSION="1.22.3"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_INSTALL_DIR="/usr/local"

if ! command -v go &>/dev/null; then
  log_info "Installing Go ${GO_VERSION}..."
  curl -fsSL "https://golang.org/dl/${GO_TARBALL}" -o "/tmp/${GO_TARBALL}"
  sudo tar -C "${GO_INSTALL_DIR}" -xzf "/tmp/${GO_TARBALL}"
  rm -f "/tmp/${GO_TARBALL}"

  # Add Go to PATH for current and future sessions
  for profile_file in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    if [[ -f "$profile_file" ]] && ! grep -q '/usr/local/go/bin' "$profile_file"; then
      # shellcheck disable=SC2016  # $PATH/$HOME intentionally unexpanded here
      printf '\n# Go\nexport PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"\n' >> "$profile_file"
    fi
  done

  export PATH="$PATH:/usr/local/go/bin:${HOME}/go/bin"
  log_success "Go $(go version | awk '{print $3}') installed."
else
  log_warn "Go is already installed ($(go version | awk '{print $3}')) – skipping."
fi

# ── Rust (via rustup) ─────────────────────────────────────────────────────────
if ! command -v rustc &>/dev/null; then
  log_info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  # shellcheck source=/dev/null
  source "${HOME}/.cargo/env"
  log_success "Rust $(rustc --version) installed."
else
  log_warn "Rust is already installed – skipping."
fi
