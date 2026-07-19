.PHONY: bootstrap darwin-bootstrap darwin-switch darwin-build vps-switch vps-build

# OS/arch-detecting bootstrap: installs Nix if missing, clones this repo if
# missing, and runs the right first-time switch for the current machine.
# Safe to also curl-pipe on a fresh box before this repo is even cloned —
# see scripts/bootstrap.sh.
bootstrap:
	./scripts/bootstrap.sh

# One-time: installs nix-darwin itself and activates this config. Requires
# Nix to already be installed (see nix/README.md).
darwin-bootstrap:
	nix run nix-darwin -- switch --flake ./nix

# Every update after the first: rebuild and activate.
darwin-switch:
	darwin-rebuild switch --flake ./nix

# Build only, no activation - useful to sanity check a change.
darwin-build:
	darwin-rebuild build --flake ./nix

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
		home-manager -- switch --flake ./nix#vps@$(VPS_ARCH)-linux --impure

# Build only, no activation.
vps-build:
	nix build --extra-experimental-features "nix-command flakes" --impure \
		./nix#homeConfigurations."vps@$(VPS_ARCH)-linux".activationPackage --no-link
