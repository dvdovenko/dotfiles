#! /bin/zsh

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
else
  echo "zoxide not found, trying installing..."

  if command -v brew >/dev/null 2>&1; then
    brew install zoxide
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y zoxide
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y zoxide
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add zoxide
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S zoxide
  else
    echo "Could not find a package manager to install zoxide. Please install it manually."

    return
  fi

  eval "$(zoxide init zsh)"
fi
