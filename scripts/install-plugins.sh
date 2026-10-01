#!/usr/bin/env bash
# Explicit, idempotent installation; keep existing plugin directories intact.
set -euo pipefail
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
clone() {
  local repo="$1" target="$2"
  if [[ -d "$target" && -n "$(ls -A "$target")" ]]; then return 0; fi
  git clone --depth=1 "https://github.com/$repo.git" "$target"
}
clone ohmyzsh/ohmyzsh "$HOME/.oh-my-zsh"
for repo in djui/alias-tips zsh-users/zsh-autosuggestions zdharma-continuum/fast-syntax-highlighting; do
  clone "$repo" "${ZDOTDIR:-$HOME/.config/zsh}/plugins/${repo##*/}"
done
clone amix/vimrc "$HOME/.vim_runtime"
clone tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins/" "$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
nvim --headless '+Lazy! install' +qa
