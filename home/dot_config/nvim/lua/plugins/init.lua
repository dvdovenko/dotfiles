return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore project session" },
      { "<leader>ql", function() require("persistence").load { last = true } end, desc = "Restore last session" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Select session" },
    },
  },

  {
    "folke/which-key.nvim",
    opts = { delay = 300, preset = "modern" },
    keys = {
      { "<leader>?", function() require("which-key").show { global = false } end, desc = "Show buffer keymaps" },
    },
  },

  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "mason-org/mason.nvim",
    opts = { PATH = "append" },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      panel = { enabled = false },
      suggestion = { auto_trigger = true },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.preselect = require("cmp").PreselectMode.None
      opts.mapping["<CR>"] = require("cmp").mapping.confirm { select = false }
      require("cmp").event:on("menu_opened", function()
        vim.b.copilot_suggestion_hidden = true
      end)
      require("cmp").event:on("menu_closed", function()
        vim.b.copilot_suggestion_hidden = false
      end)
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = {}
      opts.auto_install = false
      if vim.fn.has "mac" == 1 then
        -- Match Xcode's compiler and SDK even when an inherited SDKROOT points elsewhere.
        local install = require "nvim-treesitter.install"
        install.compilers = { "/usr/bin/clang" }
        local sdk = vim.system({ "/usr/bin/xcrun", "--sdk", "macosx", "--show-sdk-path" }, { text = true }):wait()
        if sdk.code == 0 then
          install.command_extra_args["/usr/bin/clang"] = { "-isysroot", vim.trim(sdk.stdout) }
        end
      end
    end,
  },

  -- replaced by neo-tree
  { "nvim-tree/nvim-tree.lua", enabled = false },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      close_if_last_window = true,
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      window = { position = "right", width = 30 },
    },
  },

  -- quick pin/jump between a handful of frequently used files
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- seamless navigation between tmux panes and vim splits with Ctrl-hjkl
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
    },
  },
}
