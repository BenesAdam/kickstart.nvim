local M = {}
local pick_compile_commands = require('custom.pick_compile_commands')

function M.search_file_in_compile_commands()

  -- Make sure compile commands was picked
  if pick_compile_commands.get_compile_commands_path() == '' then
    pick_compile_commands.pick_compile_commands('/', nil)
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
        results = pick_compile_commands.get_parsed_files(),
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
