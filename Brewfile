# macOS packages remain in nix/darwin/homebrew.nix.
# Optional Linux tools from the macOS Homebrew list. Nix owns core CLI tools.
if OS.linux?
  brew "ansible"
  brew "ansible-lint"
  brew "ffmpeg"
  brew "rclone"
end
