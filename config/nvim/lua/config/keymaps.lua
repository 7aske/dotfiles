-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = LazyVim.safe_keymap_set

map("n", "<leader>ws", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>wv", "<C-W>v", { desc = "Split Window Right", remap = true })

-- Move Lines
map("n", "<C-A-Down>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "<C-A-Up>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("i", "<C-A-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<C-A-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<C-A-Down>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<C-A-Up>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- buffers
map("n", "<C-A-Left>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<C-A-Right>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

map("n", "<leader>m", "<cmd>!make<cr>", { desc = "make" })
