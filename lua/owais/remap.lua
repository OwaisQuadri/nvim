-- print("remapping ...")

vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- paste and keep contents of register '.'
vim.keymap.set("v", "<leader>p", "\"_dP")

-- duplicate line
vim.keymap.set("n", "<leader>d", "yyp")

-- copy to C-v
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("n", "Q", "<nop>")

-- formatting
vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end)
vim.keymap.set("n", "<leader>=", "$gg=GG")

-- save
vim.keymap.set({"n", "i", "v"}, "<C-s>", "<Esc>:w <bar> so\n")

-- make script executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>")

-- window management
vim.keymap.set("n", "<leader>w", "<C-W>")

-- put in quotes
vim.keymap.set("v", "<leader>\"", "c\"\"<Esc>P")
-- put something in squirlies
vim.keymap.set("v", "<leader>{", "c{}<Esc>P")
-- put something in braces
vim.keymap.set("v", "<leader>[", "c[]<Esc>P")
-- put something in parenthesis
vim.keymap.set("v", "<leader>(", "c()<Esc>P")

-- put entire lines in parenthesis/braces/squirlies
vim.keymap.set({"v", "n"}, "<leader>((", "c(\n)<Esc>P<leader>f")
vim.keymap.set({"v", "n"}, "<leader>[[", "c[\n]<Esc>P<leader>f")
vim.keymap.set({"v", "n"}, "<leader>{{", "c{\n}<Esc>P<leader>f")


-- vim.keymap.set({"n"}, "<C-o>", "<cmd> silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>o", "o<Esc>")
vim.keymap.set("n", "<leader>O", "O<Esc>")

-- packer-sync
vim.keymap.set("n", "<leader>ps", "<Esc>:PackerSync\n")


