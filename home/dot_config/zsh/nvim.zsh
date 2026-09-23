#! /bin/zsh

if [[ ! -d $HOME/.vim_runtime ]]; then
  echo "Installing vimrc..."
  git clone --depth=1 https://github.com/amix/vimrc.git $HOME/.vim_runtime

  sh ~/.vim_runtime/install_awesome_vimrc.sh
else
  # echo ".vimrc already installed"
fi

if [[ ! -d $HOME/.config/nvim ]]; then
  echo "Installing neovim NvChad..."
  git clone https://github.com/NvChad/starter $HOME/.config/nvim
else
  # echo "neovim NvChad already installed"
fi
