require("lazy").load { plugins = { "nvim-lspconfig", "nvim-cmp", "conform.nvim" } }

assert(
  require("mason.settings").current.PATH == "append",
  "Mason tools must be available without overriding project tools"
)
assert(vim.env.PATH:find(vim.fn.stdpath "data" .. "/mason/bin", 1, true), "Mason bin is missing from PATH")
assert(vim.lsp.config.ts_ls.capabilities.textDocument.completion.completionItem.snippetSupport)

local cmp = require "cmp"
assert(cmp.get_config().preselect == cmp.PreselectMode.None, "Completion must not preselect a suggestion")
cmp.event:emit "menu_opened"
assert(vim.b.copilot_suggestion_hidden == true, "AI suggestions must hide while completion is open")
cmp.event:emit "menu_closed"
assert(vim.b.copilot_suggestion_hidden == false, "AI suggestions must return after completion closes")

assert(require("conform").formatters_by_ft.typescriptreact[1] == "prettier")
local copilot = require("lazy.core.plugin").values(require("lazy.core.config").plugins["copilot.lua"], "opts", false)
assert(copilot.suggestion.auto_trigger == true, "AI suggestions must trigger automatically")
assert(copilot.panel.enabled == false, "The unused Copilot panel must stay disabled")

print "completion: ok"
