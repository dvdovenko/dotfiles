# dotfiles

Nix installs packages and applies system settings. [chezmoi](https://www.chezmoi.io/)
installs the files in `home/` into `$HOME`. The same repository supports the
`danylo-mbp` macOS flake and standalone Home Manager on Linux.

## Layout

- `nix/`: nix-darwin, Home Manager, and shared CLI packages, including chezmoi.
- `home/`: chezmoi source for zsh, tmux, Starship, Git, Vim, and Neovim.
- `scripts/bootstrap.sh`: installs Nix if needed, activates the appropriate
  flake target, and applies chezmoi.

chezmoi copies tracked config files into `$HOME`. oh-my-zsh, the zsh plugin
loader, TPM, and Neovim continue to install their own plugins. Local Git
identities in `~/.config/git/conf.d/*.gitconfig`, plugin clones, histories, and
caches stay outside chezmoi's source state.

## Install

On a fresh macOS or Linux machine:

```sh
curl -fsSL https://raw.githubusercontent.com/dvdovenko/dotfiles/main/scripts/bootstrap.sh | bash
```

With an existing checkout:

```sh
./scripts/bootstrap.sh
```

The default checkout is `~/dotfiles`. `DOTFILES_DIR` and `DOTFILES_REPO` can
override it. The macOS Nix target is specific to `danylo-mbp`; the Linux target
uses the current user and detects x86_64 or aarch64.

## Update

After pulling the repository, run `make darwin-switch` on this Mac or
`make vps-switch` on Linux. Both commands switch Nix first, then apply chezmoi.
For config-only changes, use `make dotfiles-apply`. Preview with `chezmoi diff`
and check pending changes with `chezmoi status`.

On the first migration from Stow or Home Manager symlinks,
`scripts/apply-dotfiles.sh` saves the previous links and their contents under
`~/.local/state/dotfiles-migration.*` before replacing them. It keeps local
plugin clones and Git identities in the new real directories. Existing regular
files are left for chezmoi to compare; conflicts require a decision.

See [nix/README.md](nix/README.md) for Nix prerequisites, build-only commands,
and devcontainer details.
