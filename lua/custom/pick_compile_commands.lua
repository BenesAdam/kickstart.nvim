local M = {}

local compile_commands_dir = nil
local compile_commands_path = nil
local compile_commands_files = nil

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

        -- Restart clangd clients
        for _, client in ipairs(vim.lsp.get_clients()) do
          if client.name == 'clangd' then
            client.stop()
          end
        end

        vim.cmd 'LspRestart'

        -- Reload buffer
        if vim.api.nvim_buf_get_name(0) ~= '' then
          vim.cmd 'edit'
        end

        -- Parse compile commands
        compile_commands_files = get_files_from_compile_commands()

        -- Print out new compile commands
        vim.defer_fn(function()
          vim.notify(compile_commands_path, vim.log.levels.INFO)
        end, 200)

        if callback then
          callback()
        end
      end)

      return true
    end,
  }
end

-- Setting of new clangd clients
require('lspconfig').clangd.setup {
  on_new_config = function(new_config, root_dir)
    if compile_commands_dir then
      new_config.cmd = { 'clangd', '--compile-commands-dir=' .. compile_commands_dir }
    end
  end,
}

-- If some warnings create '.clangd' file in root with content:
-- CompileFlags:
--   Add: -Wno-unknown-warning-option
--   Remove: [-m*, -f*]

function get_files_from_compile_commands()
  local files = {}

  -- Read file
  if compile_commands_path == nil then
    vim.notify('Compile commands not picked yet', vim.log.levels.ERROR)
    return files
  end

  local file = io.open(compile_commands_path, 'r')

  if not file then
    vim.notify('Compile commands file not existed', vim.log.levels.ERROR)
    return files
  end

  local file_content = file:read 'a'
  file:close()

  -- Parse file
  local compile_commands = vim.fn.json_decode(file_content)

  if not compile_commands then
    vim.notify('Compile commands JSON parsing error', vim.log.levels.ERROR)
    return files
  end

  -- Agregate all files
  for _, command_object in ipairs(compile_commands) do
    local file = command_object.file
    file = vim.fs.abspath(file)
    table.insert(files, file)
  end

  return files
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
        results = compile_commands_files,
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

return M
