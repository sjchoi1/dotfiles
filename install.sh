#!/bin/bash

# Dotfiles install script
# Usage: ./install.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Install neovim, xclip, fzf, and ripgrep
if ! command -v nvim &> /dev/null || ! command -v xclip &> /dev/null || ! command -v fzf &> /dev/null || ! command -v rg &> /dev/null; then
    echo "Installing neovim, xclip, fzf, and ripgrep..."
    sudo apt-get update
    sudo apt-get install -y neovim xclip fzf ripgrep
fi

# Backup and link .tmux.conf
if [ -f ~/.tmux.conf ] && [ ! -L ~/.tmux.conf ]; then
    echo "Backing up existing .tmux.conf to ~/.tmux.conf.backup"
    mv ~/.tmux.conf ~/.tmux.conf.backup
fi
ln -sf "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf
echo "Linked .tmux.conf"

# Backup and link .vimrc
if [ -f ~/.vimrc ] && [ ! -L ~/.vimrc ]; then
    echo "Backing up existing .vimrc to ~/.vimrc.backup"
    mv ~/.vimrc ~/.vimrc.backup
fi
ln -sf "$DOTFILES_DIR/.vimrc" ~/.vimrc
echo "Linked .vimrc"

# Install vim-plug
if [ ! -f ~/.vim/autoload/plug.vim ]; then
    echo "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Install vim plugins
echo "Installing vim plugins..."
vim +PlugInstall +qall

# Link nvim config
mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
echo "Linked nvim config"

# Link .bashrc.dotfiles and source it from .bashrc
ln -sf "$DOTFILES_DIR/.bashrc.dotfiles" ~/.bashrc.dotfiles
echo "Linked .bashrc.dotfiles"

if ! grep -q "bashrc.dotfiles" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Dotfiles config" >> ~/.bashrc
    echo '[ -f ~/.bashrc.dotfiles ] && source ~/.bashrc.dotfiles' >> ~/.bashrc
    echo "Added source line to .bashrc"
fi

# Install claude code
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "Claude Code already installed, skipping..."
fi

# Install VS Code CLI (standalone tunnel binary)
VSCODE_CLI="$HOME/.local/bin/code"
if [ ! -f "$VSCODE_CLI" ]; then
    echo "Installing VS Code CLI..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  VSCODE_ARCH="x64" ;;
        aarch64) VSCODE_ARCH="arm64" ;;
        *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    mkdir -p "$HOME/.local/bin"
    curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-${VSCODE_ARCH}" -o /tmp/vscode_cli.tar.gz
    tar -xzf /tmp/vscode_cli.tar.gz -C "$HOME/.local/bin"
    mv "$HOME/.local/bin/code" "$VSCODE_CLI"
    rm /tmp/vscode_cli.tar.gz
    echo "VS Code CLI installed to $VSCODE_CLI"
else
    echo "VS Code CLI already installed, skipping..."
fi

# Set up VS Code tunnel as a systemd service
NODE_NAME="${VSCODE_TUNNEL_NAME:-$(hostname)}"
SERVICE_FILE="$HOME/.config/systemd/user/code.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Setting up VS Code tunnel service (node name: $NODE_NAME)..."
    echo "NOTE: Run '$VSCODE_CLI tunnel --name $NODE_NAME' once first to authenticate with GitHub."
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=VS Code Tunnel ($NODE_NAME)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$HOME/.local/bin/code tunnel --name $NODE_NAME --accept-server-license-terms
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable code.service
    echo "VS Code tunnel service created. Start with: systemctl --user start code"
else
    echo "VS Code tunnel service already exists, skipping..."
fi

# Git config
git config --global user.name "sjchoi"
git config --global user.email "sjchoi@casys.kaist.ac.kr"
git config --global pull.rebase true

# Generate SSH key if not exists
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating SSH key..."
    mkdir -p ~/.ssh
    ssh-keygen -t ed25519 -C "sjchoi@casys.kaist.ac.kr" -f ~/.ssh/id_ed25519 -N ""
fi

echo ""
echo "========================================"
echo "SSH public key (add to GitHub):"
echo "========================================"
cat ~/.ssh/id_ed25519.pub
echo "========================================"
echo ""

echo "Done! Starting new shell..."
exec bash
