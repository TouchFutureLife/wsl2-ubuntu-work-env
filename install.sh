#!/usr/bin/env bash
# WSL2 Ubuntu Development Environment Setup
# 搭建wsl2-ubuntu工作需要的环境

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# Ensure running on Ubuntu
if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
  log_error "This script is intended for Ubuntu only."
  exit 1
fi

# Ensure running as a normal user (not root)
if [[ "$EUID" -eq 0 ]]; then
  log_error "Please run this script as a regular user (not root). sudo will be used internally where needed."
  exit 1
fi

log_info "Starting WSL2 Ubuntu development environment setup..."
echo ""

# ──────────────────────────────────────────────
# 1. System packages
# ──────────────────────────────────────────────
source "${SCRIPT_DIR}/scripts/system.sh"

# ──────────────────────────────────────────────
# 2. Shell (Zsh + Oh My Zsh)
# ──────────────────────────────────────────────
source "${SCRIPT_DIR}/scripts/shell.sh"

# ──────────────────────────────────────────────
# 3. Programming languages
# ──────────────────────────────────────────────
source "${SCRIPT_DIR}/scripts/languages.sh"

# ──────────────────────────────────────────────
# 4. Developer tools (Docker, etc.)
# ──────────────────────────────────────────────
source "${SCRIPT_DIR}/scripts/tools.sh"

echo ""
log_success "All done! Please restart your terminal (or open a new WSL2 session) to apply all changes."
