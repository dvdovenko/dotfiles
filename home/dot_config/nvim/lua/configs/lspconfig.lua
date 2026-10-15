require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "ts_ls",
  "jsonls",
  "yamlls",
  "tailwindcss",
  "eslint",
  "graphql",
  "prismals",
  "bashls",
  "rust_analyzer",
  "gopls",
  "dockerls",
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
