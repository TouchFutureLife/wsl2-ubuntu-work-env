# wsl2-ubuntu-work-env

搭建 WSL2 Ubuntu 工作需要的环境 / One-command WSL2 Ubuntu development environment setup.

## 快速开始 / Quick Start

```bash
git clone https://github.com/TouchFutureLife/wsl2-ubuntu-work-env.git
cd wsl2-ubuntu-work-env
chmod +x install.sh
./install.sh
```

Restart your WSL2 terminal after the script completes to apply all changes.

---

## 安装内容 / What Gets Installed

### 系统工具 / System packages (`scripts/system.sh`)

| Package | Description |
|---|---|
| `build-essential` | C/C++ compiler and make |
| `git` | Version control |
| `curl` / `wget` | Download utilities |
| `vim` | Text editor |
| `tmux` | Terminal multiplexer |
| `htop` | Interactive process viewer |
| `jq` | JSON processor |
| `tree` | Directory tree viewer |
| `unzip` / `zip` | Archive utilities |
| `xclip` | Clipboard support |

### Shell (`scripts/shell.sh`)

- **Zsh** – default shell replacement for bash
- **Oh My Zsh** – Zsh framework
- **zsh-autosuggestions** – Fish-like autosuggestions
- **zsh-syntax-highlighting** – Command syntax highlighting

### 编程语言 / Programming Languages (`scripts/languages.sh`)

| Language | Version / Tool |
|---|---|
| **Node.js** | Latest LTS via [nvm](https://github.com/nvm-sh/nvm) |
| **Python 3** | System package + pip + venv |
| **Go** | 1.22.3 (official binary) |
| **Rust** | Latest stable via [rustup](https://rustup.rs) |

### 开发工具 / Developer Tools (`scripts/tools.sh`)

| Tool | Description |
|---|---|
| **Docker Engine** | Container runtime (rootless-capable via group) |
| **GitHub CLI** (`gh`) | GitHub operations from terminal |
| **fzf** | Fuzzy finder |
| **ripgrep** (`rg`) | Fast grep replacement |
| **bat** | `cat` with syntax highlighting |

---

## 目录结构 / Repository Layout

```
wsl2-ubuntu-work-env/
├── install.sh          # Entry point – runs all scripts in order
└── scripts/
    ├── system.sh       # apt system packages
    ├── shell.sh        # Zsh + Oh My Zsh
    ├── languages.sh    # Node.js / Python / Go / Rust
    └── tools.sh        # Docker / gh / fzf / ripgrep / bat
```

## 要求 / Requirements

- WSL2 with **Ubuntu 20.04 / 22.04 / 24.04**
- Internet access during installation
- Run as a **normal user** (not root); `sudo` is invoked automatically where needed
