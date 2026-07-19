# dotfiles

Personal configuration files. Installed and kept in sync via a
[nix-darwin](https://github.com/nix-darwin/nix-darwin) + [home-manager](https://github.com/nix-community/home-manager)
flake — see [`nix/README.md`](nix/README.md) for the actual install/update
commands, on macOS or on a Linux/VPS box. This root repo just holds the
tracked config files themselves; the `nix/` flake is what symlinks them into
`$HOME` and installs the packages they need.

## Layout

```
.
├── .zshenv                 -> ~/.zshenv (sets ZDOTDIR, read before anything else)
├── .gitconfig              -> ~/.gitconfig
├── .config/
│   ├── zsh/                -> ~/.config/zsh/ (ZDOTDIR: .zshenv, .zshrc, plugins, aliases, ...)
│   ├── nvim/                -> ~/.config/nvim/ (NvChad)
│   ├── tmux/tmux.conf       -> ~/.config/tmux/tmux.conf
│   ├── vim/.vimrc           -> ~/.vimrc (vim itself only reads ~/.vimrc, not XDG paths)
│   └── starship.toml        -> ~/.config/starship.toml
├── scripts/         -> ~/scripts/ (helper scripts, not symlinked)
└── nix/                     -> nix-darwin + home-manager flake (packages, macOS
                                defaults, Homebrew, and the symlinks above)
```

zsh reads `~/.zshenv` before it knows about `$ZDOTDIR`, so that one file has to live
at the repo root; everything else zsh-related lives under `.config/zsh` and is found
automatically once `ZDOTDIR` is exported.

The first `zsh`/`tmux`/`nvim` launch after installing self-installs oh-my-zsh, its
zsh plugins, and NvChad's plugins respectively — that part isn't managed by Nix,
see [`nix/README.md`](nix/README.md) for why.

## Install / update

One-liner, any OS, installs Nix itself if it's missing (VPS, devcontainer,
OrbStack VM, ...):

```bash
curl -fsSL https://raw.githubusercontent.com/dvdovenko/dotfiles/main/scripts/bootstrap.sh | bash
```

Or manually — macOS:

```bash
git clone git@github.com:dvdovenko/dotfiles.git ~/dotfiles
cd ~/dotfiles
nix run nix-darwin -- switch --flake ~/dotfiles/nix   # first time only
darwin-rebuild switch --flake ~/dotfiles/nix           # every update after
```

Any Linux box / VPS with Nix installed (no NixOS or root required, any user):

```bash
git clone git@github.com:dvdovenko/dotfiles.git ~/dotfiles
nix run home-manager -- switch --flake ~/dotfiles/nix#vps@x86_64-linux --impure
```

`make darwin-bootstrap|darwin-switch|vps-switch|vps-build|bootstrap` wrap
these from the repo root. Full details, prerequisites, and what each file in
`nix/` does are in [`nix/README.md`](nix/README.md).
