#! /bin/zsh

# starship
if [[ -x "$(command -v starship)" ]]; then
  eval "$(starship init zsh)"
else
  echo "starship not found, trying installing..."

  if command -v brew >/dev/null 2>&1; then
    brew install starship
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install starship
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install starship
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add starship
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S starship
  else
    echo "Could not find a package manager to install starship. Please install it manually."

    return
  fi

  eval "$(starship init zsh)"
fi