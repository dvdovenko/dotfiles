# dotfiles

Nix installs packages and applies system settings. [chezmoi](https://www.chezmoi.io/)
installs the files in `home/` into `$HOME`. The same repository supports the
`danylo-mbp` macOS flake and standalone Home Manager on Linux.

## Layout

- `nix/`: nix-darwin, Home Manager, and shared CLI packages, including chezmoi.
- `home/`: chezmoi source for zsh, tmux, Starship, Git, and Neovim.
- `scripts/bootstrap.sh`: installs Nix (and Homebrew on macOS) if needed, activates the appropriate
  flake target, and applies chezmoi.

chezmoi copies tracked config files into `$HOME`. oh-my-zsh, the zsh plugin
loader, TPM, and Neovim keep their existing plugin managers. Bootstrap installs
plugins explicitly with `scripts/install-plugins.sh`; shell startup never installs
tools or clones repositories. Neovim plugins install on the first `nvim` launch
through lazy.nvim; use `make nvim-plugins-install` to install them in advance. Local Git
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

Linux accepts `DOTFILES_PROFILE=slim|core`, with `slim` as the default.
macOS accepts `core|full`, with `core` as the default.

| Profile | Packages |
| --- | --- |
| `slim` | `gitMinimal openssh curl less zsh tmux starship chezmoi coreutils gnumake gnused nano rtk ripgrep fd fzf zoxide jq` |
| `core` | Current CLI tools, Neovim/NvChad, Git LFS, Devbox, Codex and Claude Code |
| `full` | Core plus credential tools, standalone runtimes and build tools |

Use `DOTFILES_PROFILE=core ./scripts/bootstrap.sh` or
`make vps-switch DOTFILES_PROFILE=core` for a Linux development environment.
On macOS, use `DOTFILES_PROFILE=full ./scripts/bootstrap.sh` or
`make darwin-build DOTFILES_PROFILE=full` for the full setup.
Unsupported profiles fail before bootstrap installs packages or updates the checkout.
Projects can supply runtimes through Devbox or devcontainers.

Shell and Git use `nvim` when available, otherwise `nano`; Git uses `delta`
when available, otherwise `less`/`cat`. File previews use `bat` or `cat`,
and the tmux Git popup uses `lazygit` or a Git log in `less`.
`slim` omits Git LFS but keeps the required LFS filter: an LFS checkout
without `git-lfs` fails explicitly. Existing personal `.vimrc` and
`.vim_runtime` are left untouched; this repository no longer manages amix/vimrc.

Install the stages separately from the repository root:

```sh
./scripts/bootstrap.sh --nix-only  # First install: Nix and its configuration
make nix-install                 # Activate Nix with Nix already installed
make dotfiles-apply              # Apply config files with chezmoi installed
make plugins-install            # Install shell and tmux plugins explicitly
```

On Linux, `--nix-only` skips Homebrew, chezmoi application and plugin installation.
On macOS, Nix activation also applies the existing system settings and declarative
Homebrew packages; first bootstrap still prepares Homebrew for that configuration.
The default bootstrap continues to install both Nix and dotfiles.

Install editor tools explicitly with `:MasonInstall <tool>` and parsers with
`:TSInstall <language>`; neither is installed in bulk at startup.

## Neovim

NvChad provides LSP completion, snippets, Telescope, Git signs, Neo-tree and Harpoon.
Mason tools load before LSP and are appended to `PATH`, preserving project tools.
Install the configured web and dotfiles tools once inside Neovim:

```vim
:MasonInstall typescript-language-server html-lsp css-lsp json-lsp yaml-language-server tailwindcss-language-server eslint-lsp graphql-language-service-cli prisma-language-server bash-language-server lua-language-server prettier stylua
:TSInstall lua luadoc vim vimdoc javascript typescript tsx jsdoc html css json yaml graphql prisma bash nix markdown markdown_inline
```

Rust, Go and Docker LSP are also configured; install `rust-analyzer`, `gopls` and
`dockerfile-language-server` with Mason when needed. Servers may need project
configuration (for example ESLint, Tailwind or GraphQL). Node-based tools need
Node.js on `PATH`; launch Neovim from the project's Devbox environment if required.
On macOS, Tree-sitter uses Apple's compiler and the SDK selected by `xcrun`,
avoiding conflicts with an inherited `SDKROOT` or older Nix compiler.

[Copilot](https://github.com/zbirenbaum/copilot.lua) supplies automatic inline AI
suggestions. Run `:Copilot auth` once and complete GitHub sign-in. It requires
Copilot access and sends code context to GitHub. The native language server is
downloaded on first use. Use `:Copilot disable` to turn it off for the session.

| Key | Action |
| --- | --- |
| `Ctrl+Space` | Open completion |
| `Tab` / `Shift+Tab` | Navigate completion or jump through snippets |
| `Enter` | Confirm an explicitly selected completion |
| `Alt+l` | Accept Copilot suggestion |
| `Alt+]` / `Alt+[` | Next / previous AI suggestion |
| `Ctrl+]` | Dismiss AI suggestion |
| `gd` / `grr` / `K` | Definition / references / hover |
| `Space ra` / `gra` | Rename / code action |
| `Space fm` | Format with project-local Prettier when available, otherwise Mason |
| `Space ff` / `Space fw` | Find files / search project text |
| `Space ha` / `Ctrl+e` | Pin file / open Harpoon |

`Space` is the leader key. Formatting runs manually; completion hides AI ghost
text while its menu is open. On macOS, configure the terminal's Option key as
Alt/Esc+ if `Alt` shortcuts insert special characters.

Run focused checks with the applied config and installed plugins:

```sh
nvim --headless -n -i NONE '+luafile home/dot_config/nvim/tests/completion.lua' +qa!
nvim --headless -n -i NONE '+luafile home/dot_config/nvim/tests/package_hover.lua' +qa!
```

## Homebrew and Linuxbrew

macOS bootstrap installs [Homebrew](https://docs.brew.sh/Installation) before Nix
activation. Linux bootstrap does not install Homebrew; the manual commands below
remain available. Linuxbrew is Homebrew on Linux, with its standard prefix at
`/home/linuxbrew/.linuxbrew`; macOS uses `/opt/homebrew` on Apple Silicon or
`/usr/local` on Intel. Run as a non-root user with sudo access. macOS needs
Xcode Command Line Tools; Linux needs a compiler/build tools, procps, curl,
file, and Git (on Ubuntu: `sudo apt-get install build-essential procps curl file git`).
The installer runs noninteractively, so fresh installations need available sudo
credentials. Setup reuses an existing `brew`, including one outside `PATH`.
If Nix is installed but `curl` is missing from `PATH`, setup supplies it from
the pinned nixpkgs input before Home Manager activation.

```sh
make brew-install  # Install Homebrew only
make brew-bundle   # Install optional packages from this checkout's Brewfile
make brew-check    # Check Brewfile packages without installing or upgrading
```

macOS packages remain managed by `nix/darwin/homebrew.nix`, including casks.
The root `Brewfile` adds optional Linux tools; bootstrap does not install those
packages automatically. Homebrew packages are separate from the Nix CLI profiles.
Bundle installation disables automatic updates and upgrades, and never runs
cleanup. [Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile) does not pin
versions. Login zsh initializes an existing Homebrew installation while keeping
inherited paths, including Nix, first; shell startup never installs packages.

## Codex environment

Keep local secrets in `~/.codex/.env` with permissions `0600`; do not add the
file to this repository. Use trusted, shell-compatible `NAME=value` assignments.
The zsh `codex` function exports these values only for the CLI and its children
when invoked. It respects `CODEX_HOME` and works without an `.env` file.

Codex desktop reads `~/.codex/.env` directly. Fully quit and reopen the app after
changing it; the zsh function is only for CLI launches. MCP forwarding still
depends on each server's `config.toml` settings. See the
[official desktop environment guidance](https://help.openai.com/en/articles/20001253-configure-codex-with-amazon-bedrock).

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

## Validation

The 2026-10-08 checks built Linux slim/core on aarch64 and x86_64 in isolated
Nix 2.35.1 containers, and macOS core/full on Apple Silicon, without activation.
The x86_64 container used QEMU with Nix `filter-syscalls = false` for compatibility;
the repository configuration keeps its existing builder settings.
Profile/default selection, package boundaries, shell fallbacks, Git editor/pager,
required LFS failure, fzf previews and isolated tmux config checks passed.
The nixpkgs, Home Manager and nix-darwin locks are unchanged.

Measured runtime closures (sum of recursive `narSize`; Linux `config.home.path`,
macOS `config.system.path`):

| System | slim | core | full |
| --- | ---: | ---: | ---: |
| x86_64-linux | 542.7 MiB | 2020.6 MiB | — |
| aarch64-linux | 567.7 MiB | 2059.7 MiB | — |
| aarch64-darwin | — | 2702.3 MiB | 3309.0 MiB |

These include the requested `gnused` addition. Package download/build inputs,
total `/nix/store`, plugin downloads and user data are separate measurements.
CI builds Linux slim/core for both architectures and macOS core/full.
A fresh VPS bootstrap, activation and old-generation cleanup remain separate;
these checks do not establish deployed-host disk savings.
