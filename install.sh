#!/bin/bash

# Dotfiles install script
# Usage: ./install.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Install neovim and xclip
if ! command -v nvim &> /dev/null; then
    echo "Installing neovim and xclip..."
    sudo apt-get update
    sudo apt-get install -y neovim xclip
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

# Git config
git config --global user.name "sjchoi"
git config --global user.email "sjchoi@casys.kaist.ac.kr"

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
