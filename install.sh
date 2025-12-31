#!/bin/bash

# Dotfiles install script
# Usage: ./install.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Install neovim
if ! command -v nvim &> /dev/null; then
    echo "Installing neovim..."
    sudo apt install -y neovim
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

# Copy vim cheatsheet
mkdir -p ~/.vim
cp "$DOTFILES_DIR/cheatsheet.txt" ~/.vim/cheatsheet.txt
echo "Copied cheatsheet"

# Link nvim config
mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
echo "Linked nvim config"

# Add vim alias to bashrc
if ! grep -q "alias vim='nvim'" ~/.bashrc; then
    echo "alias vim='nvim'" >> ~/.bashrc
    echo "Added vim->nvim alias to .bashrc"
fi

# Add cc (copy terminal output to clipboard) alias
if ! grep -q "alias cc=" ~/.bashrc; then
    echo "alias cc='tmux capture-pane -p -S -50 | xclip -selection clipboard'" >> ~/.bashrc
    echo "Added cc alias to .bashrc"
fi

# Add gg (quick git sync) alias - excludes files >50MB
if ! grep -q "alias gg=" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'
gg() {
  find . -size +50M -type f 2>/dev/null | while read f; do git reset "$f" 2>/dev/null; done
  git add . && git commit -m "." && git push || (git pull --rebase && git push)
}
EOF
    echo "Added gg alias to .bashrc"
fi

# Git config
git config --global user.name "sjchoi"
git config --global user.email "sjchoi@casys.kaist.ac.kr"
echo "Configured git user"

echo "Done! Run 'source ~/.bashrc' to apply alias."
