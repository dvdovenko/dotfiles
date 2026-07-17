# nix

nix-darwin + home-manager config for `danylo-mbp`, plus a standalone
home-manager config reusable on any Linux box (VPS or otherwise) that just
has Nix installed. This is the single source of truth for installed
packages, Homebrew taps/casks, a few macOS system defaults, and — replacing
what GNU Stow used to do — the symlinks that put the dotfiles in this repo
into `$HOME`.

## Layout

```
flake.nix               inputs: nixpkgs, nix-darwin, home-manager
                          outputs: darwinConfigurations.danylo-mbp (macOS)
                                   homeConfigurations.vps@<arch>-linux (VPS, any user)
darwin/
  configuration.nix      top-level system config (hostname, nix.enable=false, imports)
  packages.nix            environment.systemPackages: pulls in shared/cli-packages.nix
  homebrew.nix             nix-darwin's `homebrew` block: taps/brews/casks, cleanup="none"
  macos.nix                a few system.defaults + Touch ID for sudo
home/
  home.nix                 home-manager entry point (macOS)
  home-linux.nix            home-manager entry point for a standalone Linux/VPS box
  dotfiles.nix              home.file / xdg.configFile symlinks into ~/dotfiles
                             (path derived from home.homeDirectory, so it's the
                             same module on macOS and Linux)
shared/
  cli-packages.nix          the portable CLI/dev tool list, shared by darwin/
                             packages.nix (system packages) and home-linux.nix
                             (home.packages)
```

Dotfile *content* (zsh, nvim, tmux, git, vim, starship) is **not** managed
declaratively here — it's the same self-installing setup as before (oh-my-zsh,
NvChad, amix/vimrc, a git-clone-based zsh plugin loader). This config only
symlinks those files into place and installs the packages they need. That's
also why the VPS config is plain home-manager rather than full NixOS: it only
needs to manage a user's packages + dotfiles, not the machine.

## Prerequisites

Nix itself is expected to already be installed (this machine uses the
[Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer)
— that's why `darwin/configuration.nix` sets `nix.enable = false;`, so
nix-darwin doesn't fight it for control of the daemon/`nix.conf`). If Nix isn't
installed yet:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## First-time install

nix-darwin itself isn't installed yet on a fresh machine, so bootstrap it
directly from the flake:

```bash
git clone git@github.com:dvdovenko/dotfiles.git ~/dotfiles
cd ~/dotfiles
nix run nix-darwin -- switch --flake ~/dotfiles/nix
```

This will prompt for `sudo`, install `darwin-rebuild`, and activate the
config — installing the Nix packages, applying Homebrew taps/casks
(`cleanup = "none"`, so nothing already installed gets removed), the macOS
defaults, and symlinking the dotfiles. Equivalent shortcut: `make
darwin-bootstrap` (from the repo root), or see `scripts/bootstrap.sh`
below for a one-liner that also installs Nix itself if it's missing.

## Updating

```bash
cd ~/dotfiles
git pull
darwin-rebuild switch --flake ~/dotfiles/nix
```

Or `make darwin-switch` from the repo root.

## Notes

- `homebrew.brews`/`homebrew.casks` mirror this machine's actual `brew leaves`
  / `brew list --cask` output at the time this was written — add to them as
  you `brew install` new things you want reproducible.
- To try a change without touching the running system: `darwin-rebuild build
  --flake ~/dotfiles/nix` (builds only, no activation).

## VPS / any Linux box (any user)

No NixOS or root required — this uses standalone home-manager, which only
touches the invoking user's home directory. The `vps@<arch>-linux` target
reads `$USER`/`$HOME` at build time (see `flake.nix`), so the same target
works for any user — it's not tied to a specific username. This needs
`--impure` since reading the environment isn't a pure flake evaluation.

If Nix isn't installed yet:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
```

Then, as whichever user should own the dotfiles:

```bash
git clone git@github.com:dvdovenko/dotfiles.git ~/dotfiles
nix run --extra-experimental-features "nix-command flakes" \
  home-manager -- switch --flake ~/dotfiles/nix#vps@x86_64-linux --impure
```

Use `vps@aarch64-linux` instead on an ARM VPS/Apple Silicon devcontainer.
After the first switch, `home-manager` itself is on `$PATH`, so later
updates are just:

```bash
cd ~/dotfiles && git pull
home-manager switch --flake ~/dotfiles/nix#vps@x86_64-linux --impure
```

Or, from the repo root, `make vps-switch` / `make vps-build` (build-only)
auto-detect the arch via `uname -m`.

This installs the same portable CLI toolchain as the Mac
(`shared/cli-packages.nix`: git, ripgrep, fzf, bat, eza, tmux, neovim,
starship, go, node/fnm, rustup, ...) and symlinks the same dotfiles
(`.zshenv`, `.gitconfig`, `.config/{zsh,nvim,tmux,vim,git}`,
`starship.toml`) — no Homebrew, no macOS defaults, since neither applies.

## One-liner bootstrap (any OS, Nix included)

`scripts/bootstrap.sh` installs Nix if it's missing, clones (or
fast-forward pulls) the repo, then activates the right target for the
current OS/arch — nix-darwin on macOS, `vps@<arch>-linux` home-manager
everywhere else. Useful for a brand new VPS, a devcontainer, or an OrbStack
Linux VM you're using to test a change before touching a real machine:

```bash
curl -fsSL https://raw.githubusercontent.com/dvdovenko/dotfiles/main/scripts/bootstrap.sh | bash
```

Already cloned locally: `./scripts/bootstrap.sh` or `make bootstrap`.
`DOTFILES_REPO` is safe to override; `DOTFILES_DIR` isn't really — `home/dotfiles.nix`
derives the symlink source from `home.homeDirectory` (always `$HOME/dotfiles`),
not from this variable, so pointing `DOTFILES_DIR` elsewhere activates
"successfully" but leaves every symlink dangling. The script warns if it
detects this.

## Testing in a container (`.devcontainer/`)

`.devcontainer/devcontainer.json` runs `scripts/bootstrap.sh` against
a plain Ubuntu base image — open the repo in VS Code's Dev Containers
extension, or `devcontainer up`, and it installs Nix + activates
`vps@<arch>-linux` from scratch, same as a fresh VPS would. It bind-mounts
the repo at `/home/vscode/dotfiles` specifically (not the tool's usual
`/workspaces/<name>`) to satisfy the `$HOME/dotfiles` constraint above.

Things that only broke inside a container (fixed in `bootstrap.sh`, so real
VPS installs — which have systemd — aren't affected by the first two):

- No systemd → the installer's default plan fails outright; needs
  `--init none`, with `nix-daemon` then started by hand (absolute path,
  since `sudo` resets `$PATH` and won't find it otherwise).
- `$USER` isn't set by a bare `docker exec`/cron/some Ansible `become`
  setups, but home-manager's own activation script requires it — now
  exported defensively at the top of the script.

## CI

`.github/workflows/nix-checks.yml` builds `vps@x86_64-linux` and the darwin
config, and evaluates `vps@aarch64-linux` (can't build cross-arch without a
registered builder), on every push/PR touching `nix/**` — catches a broken
module before it reaches a real machine.
