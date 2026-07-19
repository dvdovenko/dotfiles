#! /bin/zsh

log() {
  if [ "$DEBUG" = "true" ]; then
    echo -e "\033[1;34m$1\033[0m"
  fi
}

# Script to install zsh plugins: zsh-autosuggestions and zsh-syntax-highlighting
# Install oh-my-zsh if missing (fresh machine bootstrap)
if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  # A container volume mounted at ~/.oh-my-zsh (to persist the install across
  # rebuilds) pre-creates this as an empty directory before anything's ever
  # installed into it. The installer refuses to run against ANY pre-existing
  # directory, even an empty one — clear it first when that's all it is.
  [[ -d "$HOME/.oh-my-zsh" ]] && rmdir "$HOME/.oh-my-zsh" 2>/dev/null
  echo "oh-my-zsh not found, installing..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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
_zplugin_load zsh-users zsh-autosuggestions
_zplugin_load zsh-users zsh-syntax-highlighting


log "Zsh plugins installation completed. Make sure to add them to your plugins list in ~/.zshrc if not already done."
