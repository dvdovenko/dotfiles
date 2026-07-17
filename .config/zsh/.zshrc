#! /bin/zsh
# zsh configuration

# =========================================================
# History
# =========================================================

export HISTFILE="$XDG_STATE_HOME/zsh/history"

[[ ! -d "$XDG_STATE_HOME/zsh" ]] && mkdir -p "$XDG_STATE_HOME/zsh"

export HISTSIZE=${HISTSIZE:-20000}
export SAVEHIST=${SAVEHIST:-20000}

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

# =========================================================
# Completion
# =========================================================

# Load completion system
autoload -Uz compinit

autoload -Uz zmv

[[ ! -d "$XDG_CACHE_HOME/zsh" ]] && mkdir -p "$XDG_CACHE_HOME/zsh"

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line


# Clear screen, keep buffer
clear-keep-buffer() {
  zle clear-screen
}
zle -N clear-keep-buffer
bindkey '^' clear-keep-buffer

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# Install oh-my-zsh if missing (fresh machine bootstrap)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "oh-my-zsh not found, installing..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="bira"

export TERM="xterm-256color"

export LANGUAGE="en_US.UTF-8"
# You may need to manually set your language environment
# export LANG=en_US.UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"

export HOMEBREW_NO_ENV_HINTS=1

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

HIST_STAMPS="dd.mm.yyyy"

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

[[ -f $ZDOTDIR/plugins.zsh ]] && source $ZDOTDIR/plugins.zsh

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  z
  git
  ansible
  alias-tips
  fzf-zsh-plugin
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# =========================================================
# Modular Config Files
# =========================================================

[[ -f $ZDOTDIR/aliases.zsh ]] && source $ZDOTDIR/aliases.zsh
[[ -f $ZDOTDIR/fnm.zsh ]] && source $ZDOTDIR/fnm.zsh
[[ -f $ZDOTDIR/functions.zsh ]] && source $ZDOTDIR/functions.zsh
[[ -f $ZDOTDIR/fzf.zsh ]] && source $ZDOTDIR/fzf.zsh
[[ -f $ZDOTDIR/nvim.zsh ]] && source $ZDOTDIR/nvim.zsh
[[ -f $ZDOTDIR/starship.zsh ]] && source $ZDOTDIR/starship.zsh
[[ -f $ZDOTDIR/zoxide.zsh ]] && source $ZDOTDIR/zoxide.zsh

# User configuration

PATH="$HOME/.go/bin:$PATH"
if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
