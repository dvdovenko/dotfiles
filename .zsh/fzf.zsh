#! /bin/zsh

if command -v fzf >/dev/null 2>&1; then
  # echo "fzf is present..."
else
  echo "fzf not found, trying installing..."

  if command -v brew >/dev/null 2>&1; then
    brew install fzf
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install fzf
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install fzf
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add fzf
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S fzf
  else
    echo "Could not find a package manager to install fzf. Please install it manually."
  fi
fi
