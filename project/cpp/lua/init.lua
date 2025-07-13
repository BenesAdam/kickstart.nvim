-- Make shortcuts
vim.keymap.set("n", "<leader>nc", "<cmd>make clean<CR>", { desc = "Solutio[n] clean" })
vim.keymap.set("n", "<leader>ng", "<cmd>make generate<CR>", { desc = "Solutio[n] generate" })
vim.keymap.set("n", "<leader>nb", "<cmd>make build<CR>", { desc = "Solutio[n] build" })
vim.keymap.set("n", "<leader>nr", "<cmd>make run<CR>", { desc = "Solutio[n] run" })

-- Debug
local dap = require("dap")
table.insert(dap.configurations.cpp, {
	name = "C++ Debug (GDB)",
	type = "gdb",
	request = "launch",
	program = "${workspaceFolder}/build/example.exe",
	cwd = "${workspaceFolder}",
	stopOnEntry = false,
	args = {},
	setupCommands = {
		{
			text = "-enable-pretty-printing",
			description = "Enable pretty printing",
			ignoreFailures = true,
		},
	},
	before = function()
		vim.fn.system("make build")
	end,
})
