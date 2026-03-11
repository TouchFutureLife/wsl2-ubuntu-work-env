#!/usr/bin/env bash
# Zsh + Oh My Zsh setup for WSL2 Ubuntu

log_info "Installing Zsh..."
sudo apt-get install -y zsh

# Change default shell to Zsh if not already set
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  log_info "Setting Zsh as the default shell..."
  chsh -s "$(command -v zsh)"
fi

# Install Oh My Zsh (unattended)
if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
  log_info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log_warn "Oh My Zsh is already installed – skipping."
fi

ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

# zsh-autosuggestions
if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
  log_info "Installing zsh-autosuggestions plugin..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]]; then
  log_info "Installing zsh-syntax-highlighting plugin..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# Enable plugins in .zshrc: add to the plugins=() list only if not already present
ZSHRC="${HOME}/.zshrc"
if [[ -f "$ZSHRC" ]]; then
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    # Only edit the file if the plugin isn't already referenced anywhere
    if ! grep -q "$plugin" "$ZSHRC"; then
      log_info "Enabling ${plugin} in ~/.zshrc..."
      # Insert the plugin name inside the existing plugins=(...) block
      sed -i "/^plugins=(/s/)$/ ${plugin})/" "$ZSHRC"
    fi
  done
fi

log_success "Zsh + Oh My Zsh configured."
