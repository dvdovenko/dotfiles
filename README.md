# dotfiles

Personal configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

This repo is a single Stow package: every file/directory at the repo root mirrors
its target location in `$HOME`.

```
.
├── .zshenv                 -> ~/.zshenv (sets ZDOTDIR, read before anything else)
├── .profile                -> ~/.profile (POSIX login-shell fallback)
├── .bashrc                 -> ~/.bashrc
├── .vimrc                  -> ~/.vimrc
├── .gitconfig              -> ~/.gitconfig
├── .config/
│   ├── zsh/                -> ~/.config/zsh/ (ZDOTDIR: .zshenv, .zshrc, plugins, aliases, ...)
│   ├── nvim/                -> ~/.config/nvim/ (NvChad)
│   ├── tmux/tmux.conf       -> ~/.config/tmux/tmux.conf
│   ├── vim/.vimrc           -> ~/.config/vim/.vimrc
│   └── starship.toml        -> ~/.config/starship.toml
└── custom-scripts/         -> ~/custom-scripts/ (helper scripts, not symlinked configs)
```

zsh reads `~/.zshenv` before it knows about `$ZDOTDIR`, so that one file has to live
at the repo root; everything else zsh-related lives under `.config/zsh` and is found
automatically once `ZDOTDIR` is exported.

## Prerequisites

```bash
make bootstrap   # installs stow, git, zsh, tmux, neovim, starship, fzf, zoxide
```

`bootstrap` uses Homebrew on macOS and `apt` on Debian/Ubuntu. Individual tools
(oh-my-zsh, its plugins, tmux's TPM, NvChad, the vim "awesome" runtime) self-install
the first time you start zsh/tmux/nvim, so a plain `make setup` (below) is normally
enough — `make bootstrap` mainly exists to unblock `stow` itself, and the shell
package managers, on a box that has neither.

## Install

Clone the repo and stow it into your home directory:

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
make setup
```

This installs prerequisites, symlinks every file in this repo into the matching path
under `~`, and installs Nerd Fonts. The first `zsh`/`tmux`/`nvim` launch afterwards
self-installs oh-my-zsh, zsh plugins, TPM and NvChad's plugins respectively.

If a target file already exists (e.g. a default `~/.zshrc` or `~/.gitconfig` from an
earlier setup), back it up or remove it first, then re-run:

```bash
make dry-run   # shows what would happen without making changes
```

## Updating

Pull the latest changes and re-stow to pick up any new files:

```bash
make update
```

## Uninstall

Remove all symlinks created by Stow without deleting the source files:

```bash
make uninstall
```

## Extra setup

`custom-scripts/fonts.sh` installs Nerd Fonts (used by Starship/tmux). Run it on its
own, or run `make setup` to install dotfiles and fonts together:

```bash
make fonts   # just the fonts
make setup   # install + fonts
```

## Makefile targets

| Target      | Description                                  |
|-------------|-----------------------------------------------|
| `bootstrap` | Install OS packages (stow, zsh, tmux, neovim, starship, fzf, zoxide) |
| `install`   | Stow all dotfiles into `$HOME`                |
| `update`    | `git pull` + re-stow                          |
| `uninstall` | Remove symlinks created by Stow               |
| `dry-run`   | Preview Stow actions without applying them    |
| `fonts`     | Install Nerd Fonts via `custom-scripts/fonts.sh` |
| `setup`     | `bootstrap` + `install` + `fonts`             |
