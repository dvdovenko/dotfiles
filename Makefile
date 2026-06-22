TARGET := $(HOME)

.PHONY: install update uninstall dry-run fonts setup

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

setup: install fonts
