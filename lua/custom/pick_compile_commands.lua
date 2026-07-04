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
        vim.lsp.config('clangd', { cmd = M.get_command() })

        -- Restart clangd clients
        local lsp_clients = vim.lsp.get_clients { name = 'clangd' }
        if #lsp_clients > 0 then
          vim.cmd 'lsp restart clangd'
        end

        -- Parse compile commands
        vim.defer_fn(function()
          parsed_files = require('custom.parse_compile_commands').get_files(compile_commands_path)
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
  local cmd = {
    'clangd',
    '--header-insertion=never',
  }

  if compile_commands_dir then
    table.insert(cmd, '--compile-commands-dir=' .. compile_commands_dir)
  end

  local project_clangd_sufix = require('custom.project_init').get_clangd_sufix()
  if project_clangd_sufix ~= '' then
    local args = vim.split(project_clangd_sufix, '%s+', { trimempty = true })
    for _, arg in ipairs(args) do
      table.insert(cmd, arg)
    end
  end

  return cmd
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

function M.get_parsed_files()
  if compile_commands_dir ~= nil then
    return parsed_files
  else
    return ''
  end
end

return M
