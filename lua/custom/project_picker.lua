local M = {}

local finders = require 'telescope.finders'
local sorters = require 'telescope.sorters'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local function copy_folder_contents(source_folder)
  local target_folder = vim.fn.getcwd()
  local cmd = string.format('cp -a "%s"/. "%s"', source_folder, target_folder)
  vim.fn.system(cmd)
end

function M.pick_project_folder()
  local project_path = vim.fn.stdpath 'config' .. '/project'
  local folders = vim.fn.globpath(project_path .. '/', '*', false, true)
  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Pick project folder',
      finder = finders.new_table { results = folders },
      sorter = sorters.get_generic_fuzzy_sorter(),
      attach_mappings = function(_, map)
        map('i', '<CR>', function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          copy_folder_contents(selection[1])
        end)
        return true
      end,
    })
    :find()
end

return M
