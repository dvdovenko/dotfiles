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
loader, TPM, and Neovim keep their existing plugin managers. Bootstrap installs
plugins explicitly with `scripts/install-plugins.sh`; shell startup never installs
tools or clones repositories. Local Git
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

`DOTFILES_PROFILE=core` is the default on both systems. It includes Devbox,
Codex, Claude Code, RTK, Git LFS, OpenSSH, and the usual shell/editor tools.
Use `DOTFILES_PROFILE=full ./scripts/bootstrap.sh` or
`make vps-build DOTFILES_PROFILE=full` to include standalone language runtimes
and build tools. Projects can supply these through Devbox or devcontainers.
Existing installations and local configuration are retained.

Install editor tools explicitly with `:MasonInstall <tool>` and parsers with
`:TSInstall <language>`; neither is installed in bulk at startup.

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

## Validation of the profile change

On 2026-10-01, both Linux profiles evaluated on x86_64 and aarch64;
both Apple Silicon profiles built without activation. The isolated shell check
passed, and the retained nixpkgs, Home Manager, and nix-darwin locks were unchanged.
The x86_64 Linux core dry run reported **683.5 MiB download / 2.1 GiB unpacked**.
This excludes Nix installation, flake sources, and plugin downloads.

An interleaved local warm-start benchmark (10 measured runs per version after
2 warmups, isolated homes, existing plugins, network/credential commands blocked)
measured median **315.25 ms before / 184.3 ms after**, about **42% faster**.
This measures non-login interactive zsh startup on the current Mac, not a fresh VPS.

CI covers native Linux builds for both architectures and profiles. Clean Linux
bootstrap, Git/LFS editing, SSH, NvChad, tmux navigation/popups, CLI versions, and
a staged fresh-VPS transfer trace remain unverified locally. No configurations
were activated, applications removed, hosts deployed, or garbage collection run.
