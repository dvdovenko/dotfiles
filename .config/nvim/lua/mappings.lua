require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- neo-tree (overrides NvChad's default nvim-tree mappings)
map("n", "<C-n>", "<cmd>Neotree toggle<CR>", { desc = "neotree toggle window" })
map("n", "<leader>e", "<cmd>Neotree focus<CR>", { desc = "neotree focus window" })

-- quick file switching
map("n", "<leader>ha", function()
  require("harpoon"):list():add()
end, { desc = "harpoon add file" })
map("n", "<C-e>", function()
  require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
end, { desc = "harpoon quick menu" })
map("n", "<leader>1", function()
  require("harpoon"):list():select(1)
end, { desc = "harpoon file 1" })
map("n", "<leader>2", function()
  require("harpoon"):list():select(2)
end, { desc = "harpoon file 2" })
map("n", "<leader>3", function()
  require("harpoon"):list():select(3)
end, { desc = "harpoon file 3" })
map("n", "<leader>4", function()
  require("harpoon"):list():select(4)
end, { desc = "harpoon file 4" })

local dependency_sections = {
  dependencies = true,
  devDependencies = true,
  optionalDependencies = true,
  peerDependencies = true,
}

local function npm_package_under_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
  local indent, package = lines[row]:match '^(%s*)"([^"]+)"%s*:'
  if not package then
    return
  end

  -- ponytail: indentation handles normal package.json files; use a parser if minified manifests need hover.
  for line = row - 1, 1, -1 do
    local parent_indent, section = lines[line]:match '^(%s*)"([^"]+)"%s*:%s*{'
    if section and #parent_indent < #indent then
      return dependency_sections[section] and package or nil
    end
  end
end

local function npm_package_hover()
  local package = npm_package_under_cursor()
  if not package then
    return vim.lsp.buf.hover()
  end

  if vim.fn.executable "npm" == 0 then
    return vim.notify("npm executable not found", vim.log.levels.ERROR)
  end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.system(
    { "npm", "view", package, "description", "version", "license", "homepage" },
    { text = true, timeout = 10000 },
    function(result)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
          return
        end

        if result.code ~= 0 then
          local message = vim.trim(result.stderr or "")
          return vim.notify(message ~= "" and message or "npm view failed for " .. package, vim.log.levels.ERROR)
        end

        local lines = vim.split(vim.trim(result.stdout or ""), "\n", { plain = true })
        lines = vim.list_extend({ "# " .. package, "" }, lines)
        vim.lsp.util.open_floating_preview(lines, "markdown", { border = "rounded" })
      end)
    end
  )
end

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "package.json",
  callback = function(args)
    vim.keymap.set("n", "K", npm_package_hover, { buffer = args.buf, desc = "npm package info" })
  end,
})
