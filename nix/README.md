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
| Dotfiles only | `make dotfiles-apply` |

`make bootstrap` also installs Nix and clones the repo if necessary. On macOS,
Nix is expected to use the Determinate Systems installer; `nix.enable = false`
keeps nix-darwin from replacing its daemon configuration. On Linux, the
standalone Home Manager target reads `$USER` and `$HOME`, so it requires
`--impure`. The script supplies that flag and handles containers without
systemd by starting `nix-daemon` itself.

After a switch, `chezmoi diff`, `chezmoi status`, and `chezmoi apply` use this
checkout. The repository's `.chezmoiroot` selects `home/` as the source state;
chezmoi's local config records the checkout path. Do not place machine-local
Git identities or installed plugins in `home/`.

The Ubuntu devcontainer runs `scripts/bootstrap.sh` after creation and mounts
the checkout at `/home/vscode/dotfiles`. CI builds the x86_64 Linux and macOS
targets and evaluates aarch64 Linux. It also checks a chezmoi apply in an
isolated destination.
