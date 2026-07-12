#! /bin/zsh

log() {
  if [ "$DEBUG" = "true" ]; then
    echo -e "\033[1;34m$1\033[0m"
  fi
}

# Script to install zsh plugins: zsh-autosuggestions and zsh-syntax-highlighting

# Ensure oh-my-zsh is installed
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    echo "oh-my-zsh is not installed. Installing oh-my-zsh..."

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    source $HOME/.zshrc
fi

ZSH_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# =========================================================
# Plugins
# =========================================================

ZPLUGINDIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"

_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${2}..."
    git clone --depth=1 "https://github.com/${1}/${2}" "$plugin_path" \
      || { echo "ERROR: failed to install ${2}" >&2; return 1; }
  fi
  source "${plugin_path}/${2}.plugin.zsh"
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}

_zplugin_load unixorn fzf-zsh-plugin
_zplugin_load zdharma-continuum fast-syntax-highlighting
_zplugin_load djui alias-tips
# _zplugin_load zsh-users zsh-autosuggestions
# _zplugin_load zsh-users zsh-syntax-highlighting

# # Install fzf-zsh-plugin
# if [ ! -d "$ZSH_DIR/plugins/fzf-zsh-plugin" ]; then
#     echo "Installing fzf-zsh-plugin..."
#     git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git "$ZSH_DIR/plugins/fzf-zsh-plugin"
# else
#     log "fzf-zsh-plugin is already installed."
# fi

# # Install fast-syntax-highlighting
# if [ ! -d "$ZSH_DIR/plugins/fast-syntax-highlighting" ]; then
#     echo "Installing fast-syntax-highlighting..."
#     git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_DIR/plugins/fast-syntax-highlighting"
# else
#     log "fast-syntax-highlighting is already installed."
# fi

# # Install alias-tips
# if [ ! -d "$ZSH_DIR/plugins/alias-tips" ]; then
#     echo "Installing alias-tips..."
#     git clone https://github.com/djui/alias-tips.git "$ZSH_DIR/plugins/alias-tips"
# else
#     log "alias-tips is already installed."
# fi

# # Install zsh-autosuggestions
# if [ ! -d "$ZSH_DIR/plugins/zsh-autosuggestions" ]; then
#     echo "Installing zsh-autosuggestions..."
#     git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_DIR/plugins/zsh-autosuggestions"
# else
#     log "zsh-autosuggestions is already installed."
# fi

# # Install zsh-syntax-highlighting
# if [ ! -d "$ZSH_DIR/plugins/zsh-syntax-highlighting" ]; then
#     echo "Installing zsh-syntax-highlighting..."
#     git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_DIR/plugins/zsh-syntax-highlighting"
# else
#     log "zsh-syntax-highlighting is already installed."
# fi


log "Zsh plugins installation completed. Make sure to add them to your plugins list in ~/.zshrc if not already done."
