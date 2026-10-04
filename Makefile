DOTFILES_PROFILE ?= core
export DOTFILES_PROFILE
ifneq ($(DOTFILES_PROFILE),core)
ifneq ($(DOTFILES_PROFILE),full)
$(error DOTFILES_PROFILE must be core or full)
endif
endif
PROFILE_SUFFIX := $(if $(filter full,$(DOTFILES_PROFILE)),-full,)

.PHONY: bootstrap plugins-install check-shell check-homebrew brew-install brew-bundle brew-check darwin-bootstrap darwin-switch darwin-build vps-switch vps-build dotfiles-apply

# OS/arch-detecting bootstrap: installs Nix if missing, clones this repo if
# missing, and runs the right first-time switch for the current machine.
# Safe to also curl-pipe on a fresh box before this repo is even cloned —
# see scripts/bootstrap.sh.
bootstrap:
	./scripts/bootstrap.sh

# One-time: installs nix-darwin itself and activates this config. Requires
# Nix to already be installed (see nix/README.md).
darwin-bootstrap:
	bash scripts/setup-homebrew.sh
	sudo -H $(shell command -v nix) run --inputs-from "path:$(CURDIR)/nix" nix-darwin -- switch --flake "path:$(CURDIR)/nix#danylo-mbp$(PROFILE_SUFFIX)"
	./scripts/apply-dotfiles.sh

# Every update after the first: rebuild and activate.
darwin-switch:
	sudo -H $(shell command -v nix) run --inputs-from "path:$(CURDIR)/nix" nix-darwin -- switch --flake "path:$(CURDIR)/nix#danylo-mbp$(PROFILE_SUFFIX)"
	./scripts/apply-dotfiles.sh

dotfiles-apply:
	./scripts/apply-dotfiles.sh

# Build only, no activation - useful to sanity check a change.
darwin-build:
	nix build --impure "path:$(CURDIR)/nix#darwinConfigurations.danylo-mbp$(PROFILE_SUFFIX).system" --no-link

# uname -m -> the arch half of home-manager's "vps@<arch>-linux" target.
# (Written with Make's own $(if)/$(filter) rather than a shell case: a shell
# case's closing ")" after each pattern would confuse Make's $(shell ...)
# paren-matching.)
UNAME_M := $(shell uname -m)
VPS_ARCH := $(if $(filter x86_64,$(UNAME_M)),x86_64,$(if $(filter aarch64 arm64,$(UNAME_M)),aarch64,unknown))

# Standalone home-manager switch for a Linux/VPS box (any user, see
# nix/README.md). --impure is required: the flake reads $USER/$HOME. Run
# these ON the target Linux box (or a devcontainer/VM) — from macOS,
# building the Linux target needs a configured remote/linux builder.
vps-switch:
	nix run --extra-experimental-features "nix-command flakes" \
		--inputs-from "path:$(CURDIR)/nix" home-manager -- switch --flake ./nix#vps$(PROFILE_SUFFIX)@$(VPS_ARCH)-linux --impure
	./scripts/apply-dotfiles.sh

# Build only, no activation.
vps-build:
	nix build --extra-experimental-features "nix-command flakes" --impure \
		./nix#homeConfigurations."vps$(PROFILE_SUFFIX)@$(VPS_ARCH)-linux".activationPackage --no-link

# Explicit installation for new machines; regular switches only apply config.
plugins-install:
	./scripts/install-plugins.sh

check-shell:
	bash scripts/check-shell.sh

check-homebrew:
	bash scripts/check-homebrew.sh

brew-install:
	bash scripts/setup-homebrew.sh

brew-bundle:
	bash scripts/setup-homebrew.sh bundle

brew-check:
	bash scripts/setup-homebrew.sh check
