local compileCommandsDir = nil
local compileCommandsPath = nil

function PickCompileCommands(callback)
  local telescope = require 'telescope.builtin'

  telescope.find_files {
    prompt_title = 'Pick compile_commands.json',
    previewer = false,
    find_command = { 'rg', '--files', '--hidden', '--no-ignore', '--glob', 'compile_commands.json', '/', '--no-messages' },
    attach_mappings = function(prompt_bufnr, map)
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local dir = vim.fn.fnamemodify(entry.path, ':h')
        compileCommandsDir = vim.fs.normalize(dir)
        compileCommandsPath = compileCommandsDir .. '/compile_commands.json'

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

        -- Print out new compile commands
        vim.defer_fn(function()
          vim.notify(compileCommandsPath, vim.log.levels.INFO)
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
    if compileCommandsDir then
      new_config.cmd = { 'clangd', '--compile-commands-dir=' .. compileCommandsDir }
    end
  end,
}

-- If some warnings create '.clangd' file in root with content:
-- CompileFlags:
--   Add: -Wno-unknown-warning-option
--   Remove: [-m*, -f*]

function GetFilesFromCompileCommands()
  local files = {}

  -- Read file
  if compileCommandsPath == nil then
    vim.notify('Compile commands not picked yet', vim.log.levels.ERROR)
    return files
  end

  local file = io.open(compileCommandsPath, 'r')

  if not file then
    vim.notify('Compile commands file not existed', vim.log.levels.ERROR)
    return files
  end

  local fileContent = file:read 'a'
  file:close()

  -- Parse file
  local compileCommands = vim.fn.json_decode(fileContent)

  if not compileCommands then
    vim.notify('Compile commands JSON parsing error', vim.log.levels.ERROR)
    return files
  end

  -- Agregate all files
  for _, commandObject in ipairs(compileCommands) do
    local file = commandObject.file
    file = vim.fs.abspath(file)
    table.insert(files, file)
  end

  return files
end

function SearchFileInCompileCommands()
  -- Make sure compile commands was picked
  if compileCommandsPath == nil then
    PickCompileCommands(SearchFileInCompileCommands)
    return
  end

  local files = GetFilesFromCompileCommands()

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local sorters = require 'telescope.sorters'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = 'Files within compile commands',
      finder = finders.new_table {
        results = files,
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

return {
  PickCompileCommands = PickCompileCommands,
  SearchFileInCompileCommands = SearchFileInCompileCommands,
}
