# ~/.zshenv — read by zsh before ZDOTDIR exists, so this file must stay minimal
# and point zsh at the real, XDG-located config in .config/zsh.

# Rust (rustup)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
