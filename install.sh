#!/bin/bash

# Dotfiles install script
# Usage: ./install.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

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

# Install neovim plugins (lazy.nvim auto-installs on first run)
if command -v nvim &> /dev/null; then
    echo "Installing neovim plugins..."
    nvim --headless "+Lazy! sync" +qa
    echo "Neovim plugins installed"
else
    echo "neovim not found - install with: sudo apt install neovim (or brew install neovim)"
    # Fall back to vim
    if command -v vim &> /dev/null; then
        echo "Installing vim plugins..."
        vim +PlugInstall +qall
        echo "Vim plugins installed"
    fi
fi

# Install Claude Code
if command -v npm &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    echo "Claude Code installed"
else
    echo "npm not found - install Node.js first to get Claude Code"
    echo "  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
    echo "  sudo apt install -y nodejs"
fi

echo "Done!"
