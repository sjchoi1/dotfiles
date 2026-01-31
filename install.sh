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

# Claude Telegram Bot setup
echo "Installing claude-telegram-bot dependencies..."
pip3 install python-telegram-bot --quiet

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo ""
    echo "=== Claude Telegram Bot Setup ==="
    read -p "Enter your Telegram Bot Token (from @BotFather): " telegram_token
    if [ -n "$telegram_token" ]; then
        echo "" >> ~/.bashrc
        echo "# Claude Telegram Bot" >> ~/.bashrc
        echo "export TELEGRAM_BOT_TOKEN=\"$telegram_token\"" >> ~/.bashrc
        export TELEGRAM_BOT_TOKEN="$telegram_token"
        echo "Saved TELEGRAM_BOT_TOKEN to ~/.bashrc"
    fi
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
