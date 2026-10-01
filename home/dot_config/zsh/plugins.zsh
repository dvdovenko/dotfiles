# Plugins are installed by scripts/install-plugins.sh, never at shell startup.
ZPLUGINDIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
for plugin in alias-tips zsh-autosuggestions fast-syntax-highlighting; do
  [[ ! -f "$ZPLUGINDIR/$plugin/$plugin.plugin.zsh" ]] || source "$ZPLUGINDIR/$plugin/$plugin.plugin.zsh"
done

# Updates remain an explicit command.
zplugin-update() {
  local dir
  for dir in "$ZPLUGINDIR"/*/(N); do
    git -C "$dir" pull --ff-only
  done
}
