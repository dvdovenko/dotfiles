require "mappings"

vim.cmd.enew()
vim.api.nvim_buf_set_name(0, "package.json")
vim.api.nvim_exec_autocmds("BufEnter", { buffer = 0 })

local command
local preview
local lsp_hovered
vim.system = function(args, _, callback)
  command = args
  callback { code = 0, stdout = "version = '1.0.0'", stderr = "" }
end
vim.lsp.util.open_floating_preview = function(lines)
  preview = lines
end
vim.lsp.buf.hover = function()
  lsp_hovered = true
end

local hover = vim.fn.maparg("K", "n", false, true).callback
assert(type(hover) == "function", "package.json K mapping is missing")

for _, package in ipairs { "react", "@scope/pkg" } do
  command, preview = nil, nil
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "{",
    '  "dependencies": {',
    ('    "%s": "1.0.0"'):format(package),
    "  }",
    "}",
  })
  vim.api.nvim_win_set_cursor(0, { 3, 6 })
  hover()
  assert(
    vim.wait(1000, function()
      return preview ~= nil
    end),
    "npm preview timed out"
  )
  assert(command[3] == package, "wrong package: " .. vim.inspect(command))
  assert(preview[1] == "# " .. package, "wrong preview: " .. vim.inspect(preview))
end

command, lsp_hovered = nil, false
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "{",
  '  "dependencies": {',
  '    "react": "1.0.0"',
  "  },",
  '  "scripts": {',
  '    "react": "echo not-a-package"',
  "  }",
  "}",
})
vim.api.nvim_win_set_cursor(0, { 6, 6 })
hover()
assert(lsp_hovered and command == nil, "K should fall back to LSP outside dependency sections")

print "package hover: ok"
