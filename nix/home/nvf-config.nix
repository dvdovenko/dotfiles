# Nix-native mirror of ../../home/dot_config/nvim (NvChad + lazy.nvim). Kept as a
# separate `nvimf` binary (see nvf.nix) rather than replacing NvChad - see
# nix/README.md for why. Maps the same options/theme/keymaps/LSP servers;
# not a byte-for-byte port (harpoon and vim-tmux-navigator have no nvf
# module - see the note at the bottom).
{
  vim = {
    viAlias = false;
    vimAlias = true;

    globals.mapleader = " ";
    options.mouse = "a";

    theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
    };

    statusline.lualine.enable = true;
    telescope.enable = true;
    treesitter.enable = true;
    autopairs.nvim-autopairs.enable = true;
    autocomplete.nvim-cmp.enable = true;
    filetree.neo-tree.enable = true;
    git.gitsigns.enable = true;

    # Ctrl-hjkl split/tmux navigation - the nvf equivalent of
    # christoomey/vim-tmux-navigator from plugins/init.lua.
    utility.smart-splits.enable = true;

    formatter.conform-nvim.enable = true;

    lsp.enable = true;

    # Each language module wires up LSP + treesitter + formatting together;
    # lsp.enable/treesitter.enable/format.enable per-language all default to
    # the top-level toggles above, so `.enable = true` here is enough -
    # matches lspconfig.lua's server list plus the treesitter parsers used.
    languages = {
      lua.enable = true; # + conform's stylua, matching configs/conform.lua
      nix.enable = true; # new vs. the Lua config - free once you're in Nix
      html.enable = true;
      css.enable = true;
      typescript.enable = true; # covers ts/tsx
      json.enable = true;
      yaml.enable = true;
      rust.enable = true;
      go.enable = true;
      docker.enable = true;
    };

    keymaps = [
      { key = ";"; mode = "n"; action = ":"; desc = "CMD enter command mode"; }
      { key = "jk"; mode = "i"; action = "<ESC>"; silent = true; }
      { key = "<C-n>"; mode = "n"; action = ":Neotree toggle<CR>"; desc = "neotree toggle window"; silent = true; }
      { key = "<leader>e"; mode = "n"; action = ":Neotree focus<CR>"; desc = "neotree focus window"; silent = true; }
    ];

    # ponytail: no harpoon module in nvf (checked nvf.notashelf.dev/options.html,
    # no vim.utility.harpoon) - quick-file-switching binds from mappings.lua
    # are dropped here. Add via vim.extraPlugins if nvimf becomes the daily
    # driver: https://nvf.notashelf.dev/tips.html#adding-plugins-from-different-sources
  };
}
