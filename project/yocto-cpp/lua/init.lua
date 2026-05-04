local M = {}

function M.get_clangd_sufix()
	if vim.env.SDKTARGETSYSROOT then
		return "--query-driver=/opt/poky/5.3.3/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/*"
	else
		return ""
	end
end

function M.configure()
	-- Make shortcuts
	vim.keymap.set("n", "<leader>nc", "<cmd>make clean<CR>", { desc = "Solutio[n] [c]lean" })
	vim.keymap.set("n", "<leader>ng", "<cmd>make generate<CR>", { desc = "Solutio[n] [g]enerate" })
	vim.keymap.set("n", "<leader>nb", "<cmd>make build<CR>", { desc = "Solutio[n] [b]uild" })
	vim.keymap.set("n", "<leader>nr", "<cmd>make run<CR>", { desc = "Solutio[n] [r]un" })
	vim.keymap.set("n", "<leader>nd", "<cmd>make deploy<CR>", { desc = "Solutio[n] [d]eploy" })

	-- Debug
	local function debug_buffer_start()
		vim.cmd("vsplit")
		vim.cmd("term ssh root@192.168.7.2 -t 'gdbserver :2345 /tmp/example; sh'")
		vim.g.debug_term_buf = vim.api.nvim_get_current_buf()
		vim.cmd("wincmd p")
	end

	local function debug_buffer_stop()
		if vim.g.debug_term_buf and vim.api.nvim_buf_is_valid(vim.g.debug_term_buf) then
			vim.cmd("bd! " .. vim.g.debug_term_buf)
			vim.g.debug_term_buf = nil
		end
	end

	local dap = require("dap")
	if vim.env.SDKTARGETSYSROOT then
		-- ARM application on RPi0
		table.insert(dap.configurations.cpp, {
			name = "C++ ARM Debug (GDB)",
			type = "gdb",
			request = "attach",
			target = "192.168.7.2:2345",
			program = "${workspaceFolder}/build/example",
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
				vim.fn.system(
					[[ssh root@192.168.7.2 "ps | grep '[g]dbserver :2345' | awk '{print \$1}' | xargs -r kill"]]
				)
				vim.fn.system("scp build/example root@192.168.7.2:/tmp/example")
				debug_buffer_start()
			end,
		})

		dap.listeners.after["event_terminated"]["close_term"] = function()
			vim.schedule(debug_buffer_stop)
		end
	else
		-- Default x86 application on PC
		table.insert(dap.configurations.cpp, {
			name = "C++ Debug (GDB)",
			type = "codelldb",
			request = "launch",
			program = "${workspaceFolder}/build/example",
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
	end
end

return M
