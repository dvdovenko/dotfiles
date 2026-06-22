# dotfiles

Personal configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

This repo is a single Stow package: every file/directory at the repo root mirrors
its target location in `$HOME`.

```
.
├── .vimrc                  -> ~/.vimrc
├── .zshrc                  -> ~/.zshrc
├── .zsh/                   -> ~/.zsh/
├── .config/
│   ├── starship.toml       -> ~/.config/starship.toml
│   └── tmux/tmux.conf      -> ~/.config/tmux/tmux.conf
└── custom-scripts/         -> ~/custom-scripts/ (helper scripts, not symlinked configs)
```

## Prerequisites

```bash
brew install stow   # macOS
# or
sudo apt install stow   # Debian/Ubuntu
```

## Install

Clone the repo and stow it into your home directory:

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
make install
```

This symlinks every file in this repo into the matching path under `~`.

If a target file already exists (e.g. a default `~/.zshrc`), back it up or remove it
first, then re-run the command above:

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
| `install`   | Stow all dotfiles into `$HOME`                |
| `update`    | `git pull` + re-stow                          |
| `uninstall` | Remove symlinks created by Stow               |
| `dry-run`   | Preview Stow actions without applying them    |
| `fonts`     | Install Nerd Fonts via `custom-scripts/fonts.sh` |
| `setup`     | `install` + `fonts`                           |
