{ config, ... }:

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  # Derived from home.homeDirectory rather than hardcoded, so this same
  # module works unchanged on macOS (/Users/danylo/dotfiles) and on a
  # Linux/VPS home-manager config (/home/dev/dotfiles).
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  # Takes over the job GNU Stow used to do: symlink the tracked dotfiles into
  # $HOME. These are out-of-store symlinks straight to the git repo, so
  # editing a file never requires a rebuild, and the self-installing scripts
  # (oh-my-zsh, NvChad, amix/vimrc, the zsh plugin loader) keep working
  # exactly as before — their content is not managed by Nix.
  home.file = {
    ".zshenv".source = mkOutOfStoreSymlink "${dotfiles}/.zshenv";
    ".vimrc".source = mkOutOfStoreSymlink "${dotfiles}/.config/vim/.vimrc";
    ".gitconfig".source = mkOutOfStoreSymlink "${dotfiles}/.gitconfig";
  };

  # Whole-directory symlinks, matching Stow's current behavior: these dirs
  # also hold runtime-generated state (zsh's .zcompdump*, its cloned
  # plugins/) written straight into the repo, so they can't be split into
  # per-file symlinks.
  xdg.configFile = {
    "zsh".source = mkOutOfStoreSymlink "${dotfiles}/.config/zsh";
    "nvim".source = mkOutOfStoreSymlink "${dotfiles}/.config/nvim";
    "tmux".source = mkOutOfStoreSymlink "${dotfiles}/.config/tmux";
    "git".source = mkOutOfStoreSymlink "${dotfiles}/.config/git";
    "starship.toml".source = mkOutOfStoreSymlink "${dotfiles}/.config/starship.toml";
  };
}
