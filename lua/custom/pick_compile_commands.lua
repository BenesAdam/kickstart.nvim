local M = {}
-- If some warnings create '.clangd' file in root with content:
-- CompileFlags:
--   Add: -Wno-unknown-warning-option
--   Remove: [-m*, -f*]

local compile_commands_dir = nil
local compile_commands_path = nil
local parsed_files = nil

function M.pick_compile_commands(root_folder, callback)
  local telescope = require 'telescope.builtin'

  telescope.find_files {
    prompt_title = 'Pick compile_commands.json',
    previewer = false,
    find_command = { 'rg', '--files', '--hidden', '--no-ignore', '--glob', 'compile_commands.json', root_folder, '--no-messages' },
    attach_mappings = function(prompt_bufnr, map)
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local dir = vim.fn.fnamemodify(entry.path, ':h')
        compile_commands_dir = vim.fs.normalize(dir)
        compile_commands_path = compile_commands_dir .. '/compile_commands.json'

        -- New configuration of clangd
        local lspconfig = require 'lspconfig'
        lspconfig.clangd.setup {
          cmd = M.get_command(),
        }

        -- Restart clangd clients
        local lsp_clients = vim.lsp.get_clients { name = 'clangd' }
        if #lsp_clients > 0 then
          vim.cmd 'LspRestart clangd'
        end

        -- Parse compile commands
        vim.defer_fn(function()
          parsed_files = require('custom.find_files').get_files(compile_commands_path)
        end, 10)

        if callback then
          callback() -- TODO: not working right now
        end
      end)

      return true
    end,
  }
end

function M.get_command()
  local cmd = { 'clangd' }

  if compile_commands_dir then
    cmd = { 'clangd', '--compile-commands-dir=' .. compile_commands_dir }
  end

  return cmd
end

function M.search_file_in_compile_commands()
  -- Make sure compile commands was picked
  if compile_commands_path == nil then
    M.pick_compile_commands('/', search_file_in_compile_commands)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local sorters = require 'telescope.sorters'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = 'Files within compile commands',
      finder = finders.new_table {
        results = parsed_files,
      },
      sorter = sorters.get_generic_fuzzy_sorter(),

      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          vim.cmd('edit ' .. selection.value)
        end)
        return true
      end,
    })
    :find()
end

function M.get_compile_commands_dir()
  if compile_commands_dir ~= nil then
    return compile_commands_dir
  else
    return ''
  end
end

function M.get_compile_commands_path()
  if compile_commands_path ~= nil then
    return compile_commands_path
  else
    return ''
  end
end

return M
