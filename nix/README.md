# Nix configuration

`nix-darwin` configures `danylo-mbp`; standalone Home Manager installs the
shared CLI packages for any user on Linux. Nix owns packages and macOS
settings. [chezmoi](https://www.chezmoi.io/) owns the files in `home/`, with
`~/dotfiles` as its source directory. The bootstrap script initializes chezmoi
after the first Nix switch.

## Targets

| Target | Command from repository root |
| --- | --- |
| First macOS switch | `make darwin-bootstrap` |
| Later macOS switches | `make darwin-switch` |
| macOS build only | `make darwin-build` |
| Linux switch | `make vps-switch` |
| Linux build only | `make vps-build` |
| Nix activation only (current OS) | `make nix-install` |
| macOS Nix activation only | `make darwin-nix-switch` |
| Linux Nix activation only | `make vps-nix-switch` |
| Dotfiles only | `make dotfiles-apply` |

For first installation without applying dotfiles, run
`./scripts/bootstrap.sh --nix-only`. On Linux this also skips Homebrew and plugins.
macOS retains the existing nix-darwin system settings and Homebrew activation.
Neovim plugins install at first launch; `make nvim-plugins-install` installs them
explicitly in advance.

`make bootstrap` also installs Nix and clones the repo if necessary. On macOS,
Nix is expected to use the Determinate Systems installer; `nix.enable = false`
keeps nix-darwin from replacing its daemon configuration. On Linux, the
standalone Home Manager target reads `$USER` and `$HOME`, so it requires
`--impure`. The script supplies that flag and handles containers without
systemd by starting `nix-daemon` only when the existing store is inaccessible.

After a switch, `chezmoi diff`, `chezmoi status`, and `chezmoi apply` use this
checkout. The repository's `.chezmoiroot` selects `home/` as the source state;
chezmoi's local config records the checkout path. Do not place machine-local
Git identities or installed plugins in `home/`.

The Ubuntu devcontainer runs `scripts/bootstrap.sh` after creation and mounts
the checkout at `/home/vscode/dotfiles`. CI builds slim/core on both Linux
architectures; Apple Silicon builds core/full. It also checks a chezmoi apply
in an isolated destination.

## Profiles

Linux accepts `slim|core` and defaults to `slim`; macOS accepts `core|full`
and defaults to `core`. `full` uses `danylo-mbp-full`.
Core contains the current CLI tools, Neovim/NvChad, Git LFS and Devbox;
full adds credential and build tools through Nix; macOS Homebrew owns
standalone runtimes and Neovim/tmux/Starship. Linux core keeps those three in Nix.
`danylo-mbp` (core/full) installs Codex and Claude Code (`latest` channel) through
Homebrew. Linux profiles omit both; automatic updates remain deferred.

| Linux profile | Targets |
| --- | --- |
| `slim` | `vps@x86_64-linux-slim`, `vps@aarch64-linux-slim` |
| `core` | `vps@x86_64-linux`, `vps@aarch64-linux` (existing names) |

`slim` installs exactly:

```nix
gitMinimal openssh curl less
zsh tmux starship chezmoi coreutils gnumake gnused nano
ripgrep fd fzf jq
```

`slim` disables the Home Manager CLI/manuals, generic Linux integration,
and user service management. Core retains generic Linux integration with GPU
and MIME setup disabled. All profiles retain the same locked inputs;
launchers use `--inputs-from ./nix`. Linux core bootstrap installs Linuxbrew and the Brewfile packages; slim and
Linux `--nix-only` skip Homebrew.
Use `make vps-build DOTFILES_PROFILE=core` to build the existing core target;
`make vps-build` builds slim. Unsupported profiles are rejected before activation.

Run `bash scripts/check-shell.sh` for isolated startup validation.
Run `make check-profiles` to check profile selection without activation.
Run `bash scripts/check-profiles.sh --nix` to also evaluate package boundaries
on both Linux architectures and Apple Silicon.
For a fresh-host transfer trace, record network receive bytes before and after
Nix installation, flake/launcher fetches, package activation, and explicit plugin
installation separately. `nix build --dry-run` reports package downloads and
unpacked store size only; it does not measure the other stages. No fresh VPS
transfer trace has been verified by these repository checks.

## Disk measurements

Compare runtime closures after builds with `nix path-info --recursive --closure-size`
on each output, or `nix path-info --json --recursive <output>` and sum `narSize`.
The package dry run in the approved slim plan reported **622.8 MiB unpacked /
175.7 MiB download**; this is not the size of the complete Home Manager generation
or total `/nix/store`. Download estimates also depend on existing cached paths.

VPS activation and old-generation cleanup are separate operations. Before and after
activation, record the active profile closure, total `/nix/store` usage, and retained
generations. Do not infer store savings from a package dry run or delete generations
as part of a build check.
