local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader><leader>', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>gf', function()
	builtin.grep_string({ search = vim.fn.input("Files that include: ") });
end)
-- paste from register
vim.keymap.set({"n"}, "<leader>rp", builtin.registers)
vim.keymap.set({"v"}, "<leader>rp", "\"_d:Telescope registers\n")
