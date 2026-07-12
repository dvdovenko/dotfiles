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
