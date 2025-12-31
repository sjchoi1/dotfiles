#!/bin/bash

# Dotfiles install script
# Usage: ./install.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Install neovim if not present (need v0.9+ for modern plugins)
if ! command -v nvim &> /dev/null; then
    echo "Installing neovim..."
    if command -v brew &> /dev/null; then
        brew install neovim
    elif command -v apt &> /dev/null; then
        # Use PPA for newer version (apt version is too old)
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:neovim-ppa/unstable
        sudo apt update
        sudo apt install -y neovim
    else
        echo "Could not install neovim - please install manually"
    fi
fi

# Install Node.js if not present (needed for Claude Code)
if ! command -v npm &> /dev/null; then
    echo "Installing Node.js..."
    if command -v apt &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
    elif command -v brew &> /dev/null; then
        brew install node
    else
        echo "Could not install Node.js - please install manually"
    fi
fi

# Backup and link .tmux.conf
if [ -f ~/.tmux.conf ] && [ ! -L ~/.tmux.conf ]; then
    echo "Backing up existing .tmux.conf to ~/.tmux.conf.backup"
    mv ~/.tmux.conf ~/.tmux.conf.backup
fi
ln -sf "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf
echo "Linked .tmux.conf"

# Backup and link neovim config
mkdir -p ~/.config
if [ -d ~/.config/nvim ] && [ ! -L ~/.config/nvim ]; then
    echo "Backing up existing nvim config to ~/.config/nvim.backup"
    mv ~/.config/nvim ~/.config/nvim.backup
fi
ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
echo "Linked nvim config"

# Backup and link .vimrc (fallback for servers without neovim)
if [ -f ~/.vimrc ] && [ ! -L ~/.vimrc ]; then
    echo "Backing up existing .vimrc to ~/.vimrc.backup"
    mv ~/.vimrc ~/.vimrc.backup
fi
ln -sf "$DOTFILES_DIR/.vimrc" ~/.vimrc
echo "Linked .vimrc"

# Install neovim plugins
echo "Installing neovim plugins..."
nvim --headless "+Lazy! sync" +qa
echo "Neovim plugins installed"

# Install Claude Code
echo "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code
echo "Claude Code installed"

echo "Done!"
