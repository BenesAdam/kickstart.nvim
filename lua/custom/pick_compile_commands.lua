local compileCommandsDir = nil
local compileCommandsPath = nil

function PickCompileCommands()
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
        else
          vim.cmd('e ' .. compileCommandsPath)
        end

        -- Print out new compile commands
        vim.defer_fn(function()
          vim.notify(compileCommandsPath, vim.log.levels.INFO)
        end, 200)
      end)

      return true
    end,
  }
end

-- Setting of new clangd clients
require('lspconfig').clangd.setup {
  on_new_config = function(new_config, root_dir)
    if compileCommandsDir then
      new_config.cmd = { 'clangd', '--compile-commands-dir=' .. compileCommandsDir}
    end
  end,
}

-- If some warnings create '.clangd' file in root with content:
-- CompileFlags:
--   Add: -Wno-unknown-warning-option
--   Remove: [-m*, -f*]

return {
  PickCompileCommands = PickCompileCommands,
}
