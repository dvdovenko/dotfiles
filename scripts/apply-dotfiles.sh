#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
command -v chezmoi >/dev/null || { echo 'chezmoi is not installed; run the Nix switch first' >&2; exit 1; }

if [[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]]; then
  chezmoi --source "$repo_dir" init
fi

# Old Home Manager/Stow installations linked whole config directories into
# the repo. Copy their contents first: plugins and local git identities live
# there too, but are intentionally absent from chezmoi's source state.
backup_dir=''
for relative in .zshenv .gitconfig .vimrc .config/starship.toml .config/zsh .config/tmux .config/nvim .config/git; do
  target="$HOME/$relative"
  [[ -L "$target" ]] || continue
  if [[ -z "$backup_dir" ]]; then
    mkdir -p "$HOME/.local/state"
    backup_dir="$(mktemp -d "$HOME/.local/state/dotfiles-migration.XXXXXX")"
  fi
  mkdir -p "$backup_dir/$(dirname "$relative")" "$backup_dir/snapshot/$(dirname "$relative")"
  if [[ -d "$target" ]]; then
    mkdir -p "$backup_dir/snapshot/$relative"
    cp -R -p "$target/." "$backup_dir/snapshot/$relative/"
    mv "$target" "$backup_dir/$relative"
    cp -R -p "$backup_dir/snapshot/$relative" "$target"
  else
    [[ ! -e "$target" ]] || cp -p "$target" "$backup_dir/snapshot/$relative"
    mv "$target" "$backup_dir/$relative"
  fi
done

# Some Stow setups left ~/.config/git as a real directory while local
# identities remained only in the ignored repository directory.
for identity in "$repo_dir"/.config/git/conf.d/*.gitconfig; do
  [[ -f "$identity" ]] || continue
  mkdir -p "$HOME/.config/git/conf.d"
  target="$HOME/.config/git/conf.d/${identity##*/}"
  [[ -e "$target" ]] || cp -p "$identity" "$target"
done

[[ -z "$backup_dir" ]] || echo "Previous links and contents saved in $backup_dir"
chezmoi --source "$repo_dir" apply
