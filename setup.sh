#!/bin/bash

# Clone the repository if it doesn't exist
if [ ! -d ~/dotfiles ]; then
  git clone git@github.com:hkeidesen/dotfiles.git ~/dotfiles
fi

# Create symlinks
ln -sf ~/dotfiles/.zshrc ~/
ln -sf ~/dotfiles/.gitconfig ~/
ln -s ~/dotfiles/nvim ~/.config
ln -s ~/dotfiles/.tmux.conf.local ~/
ln -s ~/dotfiles/.tmux.conf ~/
ln -s ~/dotfiles/.tmux ~/
ln -s ~/dotfiles/.p10k.zsh ~/

echo "Dotfiles setup complete!"
