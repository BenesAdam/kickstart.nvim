local M = {}
local pick_compile_commands = require 'custom.pick_compile_commands'

function M.search_vars_in_compile_commands()
  -- Configuration
  local MAX_CMD_LEN = 30000 -- WinApi command line argument len max
  local MAX_JOBS = 4 -- how many parallel rg processes
  local DEBOUNCE_MS = 500 -- debounce for writing

  -- Local shortcuts
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local make_entry = require 'telescope.make_entry'

  -- Make sure compile commands was picked
  if pick_compile_commands.get_compile_commands_path() == '' then
    pick_compile_commands.pick_compile_commands('/', nil)
    return
  end

  -- Batch by lenght of command line
  local function chunk_by_cmd_length(files, base_len)
    local batches = {}
    local current = {}
    local current_len = base_len

    for _, path in ipairs(files) do
      local add_len = #path + 1 -- space

      if current_len + add_len > MAX_CMD_LEN then
        table.insert(batches, current)
        current = { path }
        current_len = base_len + add_len
      else
        table.insert(current, path)
        current_len = current_len + add_len
      end
    end

    if #current > 0 then
      table.insert(batches, current)
    end

    return batches
  end

  local picker
  local results = {}
  local debounce_timer = nil
  local generation = 0
  local last_prompt = nil

  local function refresh_picker()
    picker:refresh(
      finders.new_table {
        results = results,
        entry_maker = make_entry.gen_from_vimgrep {},
      },
      {
        reset_prompt = false,
        reset_selection = false,
      }
    )
  end

  local function run_rg(prompt)
    generation = generation + 1
    local gen = generation

    if not prompt or prompt == '' then
      results = {}
      refresh_picker()
      return
    end

    results = {}

    local base_cmd_len = #'rg' + #' --vimgrep --no-heading --color=never ' + #prompt

    local parsed_files = pick_compile_commands.get_parsed_files()
    local batches = chunk_by_cmd_length(parsed_files, base_cmd_len)
    local queue = vim.deepcopy(batches)
    local running = 0

    local function spawn_next()
      if gen ~= generation then
        return
      end

      if #queue == 0 and running == 0 then
        refresh_picker()
        return
      end

      while running < MAX_JOBS and #queue > 0 do
        local batch = table.remove(queue, 1)
        running = running + 1

        local cmd = {
          'rg',
          '--vimgrep',
          '--no-heading',
          '--color=never',
          prompt,
        }
        vim.list_extend(cmd, batch)

        vim.system(cmd, { text = true }, function(res)
          running = running - 1
          if gen ~= generation then
            return
          end

          if res.stdout and res.stdout ~= '' then
            for line in res.stdout:gmatch '[^\r\n]+' do
              results[#results + 1] = line
            end
          end

          spawn_next()
        end)
      end
    end

    spawn_next()
  end

  picker = pickers.new({}, {
    prompt_title = 'Grep (compile_commands files)',

    finder = finders.new_table {
      results = {},
      entry_maker = make_entry.gen_from_vimgrep {},
    },

    sorter = conf.generic_sorter {},
    previewer = conf.grep_previewer {},

    on_input_filter_cb = function(prompt)
      if prompt == last_prompt then
        return prompt
      end
      last_prompt = prompt

      if debounce_timer then
        debounce_timer:stop()
        debounce_timer:close()
      end

      debounce_timer = vim.loop.new_timer()
      debounce_timer:start(DEBOUNCE_MS, 0, function()
        vim.schedule(function()
          run_rg(prompt)
        end)
      end)

      return prompt
    end,
  })

  picker:find()
end

return M
