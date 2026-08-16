# Second Neovim, configured declaratively via nvf (github:notashelf/nvf)
# instead of the NvChad + lazy.nvim setup ../../.config/nvim symlinks in via
# dotfiles.nix. Installed as `nvimf`, not `nvim` - nvf's wrapper binary is
# also literally called `nvim`, so it's renamed here to run side by side
# with NvChad's `nvim` (from shared/cli-packages.nix) instead of colliding
# with it. Switching between them is just typing the other command; there's
# no shared state to swap. See nix/README.md for the tradeoffs.
{ pkgs, inputs, ... }:

let
  nvfNeovim = (inputs.nvf.lib.neovimConfiguration {
    inherit pkgs;
    modules = [ ./nvf-config.nix ];
  }).neovim;

  nvimf = pkgs.runCommand "nvimf" { } ''
    mkdir -p $out/bin
    ln -s ${nvfNeovim}/bin/nvim $out/bin/nvimf
  '';
in
{
  home.packages = [ nvimf ];
}
