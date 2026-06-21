return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
  	"nvim-treesitter/nvim-treesitter",
  	opts = {
  		ensure_installed = {
  			"vim", "lua", "vimdoc", "editorconfig",
        "html", "css", "dockerfile", "dot", "git_config",
        "git_rebase", "gitattributes", "gitcommit", "gitignore",
        "go", "javascript", "jq", "jsdoc", "json", "yaml", "typescript",
        "tsx", "scss", "rust", "prisma"
  		},
  	},
  },
}
