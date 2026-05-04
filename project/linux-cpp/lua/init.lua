local M = {}

function M.configure()
  -- Make shortcuts
  vim.keymap.set('n', '<leader>nc', '<cmd>make clean<CR>', { desc = 'Solutio[n] clean' })
  vim.keymap.set('n', '<leader>ng', '<cmd>make generate<CR>', { desc = 'Solutio[n] generate' })
  vim.keymap.set('n', '<leader>nb', '<cmd>make build<CR>', { desc = 'Solutio[n] build' })
  vim.keymap.set('n', '<leader>nr', '<cmd>make run<CR>', { desc = 'Solutio[n] run' })

  -- Debug
  local dap = require 'dap'

  -- External terminal - normal font
  dap.defaults.fallback.external_terminal = {
    command = '/usr/bin/ghostty',
    args = { '--font-family="MxPlus IBM EGA 8x8"', '-e' },
  }

  -- External terminal - 8x8 font
  dap.defaults.fallback.external_terminal = {
    command = '/usr/bin/alacritty',
    -- font downloaded in: https://int10h.org/oldschool-pc-fonts/download/oldschool_pc_font_pack_v2.2_linux.zip
    args = { '-o', 'font.normal.family="MxPlus IBM EGA 8x8"', '-e' },
  }

  table.insert(dap.configurations.cpp, {
    name = 'C++ Debug (codeLLDB)',
    type = 'codelldb',
    request = 'launch',
    program = '${workspaceFolder}/build/example',
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    console = 'externalTerminal',
    args = {},
    setupCommands = {
      {
        text = '-enable-pretty-printing',
        description = 'Enable pretty printing',
        ignoreFailures = true,
      },
    },
    before = function()
      vim.fn.system 'make build'
    end,
  })
end

return M
