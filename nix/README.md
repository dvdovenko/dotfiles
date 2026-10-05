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
systemd by starting `nix-daemon` only when the existing store is inaccessible.

After a switch, `chezmoi diff`, `chezmoi status`, and `chezmoi apply` use this
checkout. The repository's `.chezmoiroot` selects `home/` as the source state;
chezmoi's local config records the checkout path. Do not place machine-local
Git identities or installed plugins in `home/`.

The Ubuntu devcontainer runs `scripts/bootstrap.sh` after creation and mounts
the checkout at `/home/vscode/dotfiles`. CI evaluates core on both Linux architectures and builds it
natively on Linux; Apple Silicon builds both profiles. It also checks a chezmoi apply in an
isolated destination.

## Profiles

The default is `DOTFILES_PROFILE=core`. macOS accepts `core|full`; full uses
`danylo-mbp-full`. Linux/VPS supports only core, with targets
`vps@x86_64-linux` / `vps@aarch64-linux`. `make vps-build`, `make vps-switch`,
and Linux bootstrap reject `DOTFILES_PROFILE=full`.
Linux targets retain generic Linux integration but disable GPU and MIME setup.
Both profiles use the same locked inputs; launchers use `--inputs-from ./nix`.

Run `bash scripts/check-shell.sh` for isolated startup validation.
Run `make check-profiles` to check profile selection without activation.
For a fresh-host transfer trace, record network receive bytes before and after
Nix installation, flake/launcher fetches, package activation, and explicit plugin
installation separately. `nix build --dry-run` reports package downloads and
unpacked store size only; it does not measure the other stages. No fresh VPS
transfer trace has been verified by these repository checks.
