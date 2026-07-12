TARGET := $(HOME)
UNAME := $(shell uname -s)

.PHONY: install update uninstall dry-run fonts bootstrap setup

bootstrap:
ifeq ($(UNAME),Darwin)
	command -v brew >/dev/null 2>&1 || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew install stow git zsh tmux neovim starship fzf zoxide
else
	sudo apt-get update
	sudo apt-get install -y stow git zsh tmux neovim curl unzip fzf zoxide
	command -v starship >/dev/null 2>&1 || curl -sS https://starship.rs/install.sh | sh -s -- -y
endif

install:
	stow -t $(TARGET) .

update:
	git pull
	stow -t $(TARGET) .

uninstall:
	stow -D -t $(TARGET) .

dry-run:
	stow -t $(TARGET) -n -v .

fonts:
	./custom-scripts/fonts.sh

setup: bootstrap install
