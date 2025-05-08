function PickCompileCommands()
  local util = require 'lspconfig.util'
  local telescope = require 'telescope.builtin'

  telescope.find_files {
    prompt_title = 'Pick compile_commands.json',
    no_ignore = true,
    search_file = 'compile_commands.json',
    attach_mappings = function(prompt_bufnr, map)
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local dir = vim.fn.fnamemodify(entry.path, ':h')

        -- Stop clangd for this buffer
        local bufnr = vim.api.nvim_get_current_buf()
        for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
          if client.name == 'clangd' then
            client.stop()
          end
        end

        -- Manually start new clangd client and attach to buffer
        vim.defer_fn(function()
          -- Get target flag
          local target_flag = nil
          local cc_file = dir .. '/compile_commands.json'

          if vim.fn.filereadable(cc_file) == 1 then
            local ok, json = pcall(vim.fn.readfile, cc_file)
            if ok then
              local decoded = vim.fn.json_decode(table.concat(json, '\n'))
              if decoded and decoded[1] then
                local cmd_str = decoded[1].command or table.concat(decoded[1].arguments or {}, ' ')
                if cmd_str:match 'cl%.exe' then
                  target_flag = '--target=x86_64-pc-windows-msvc'
                elseif cmd_str:match '%-mfpu=' or cmd_str:match 'arm' then
                  target_flag = '--target=arm-none-eabi'
                end
              end
            end
          end

          local cmd = { 'clangd', '--compile-commands-dir=' .. dir }
          if target_flag then
            table.insert(cmd, target_flag)
          end

          local root_dir = util.root_pattern('compile_commands.json', 'CMakeLists.txt', '.git')(dir) or vim.fn.getcwd()

          -- Start new client
          local client_id = vim.lsp.start {
            name = 'clangd',
            cmd = cmd,
            root_dir = root_dir,
            on_attach = function(client, bufnr_)
              vim.notify('clangd attached to buffer ' .. bufnr_)
            end,
          }

          -- Attach manually if needed
          if client_id then
            vim.lsp.buf_attach_client(bufnr, client_id)
          else
            vim.notify('clangd did not start', vim.log.levels.ERROR)
          end
        end, 100)

        -- Reload buffer
        vim.cmd 'edit'

        -- Print out new compile commands
        vim.defer_fn(function()
          local normalized_path = vim.fs.normalize(dir .. '/compile_commands.json')
          vim.notify(normalized_path, vim.log.levels.INFO)
        end, 200)
      end)

      return true
    end,
  }
end

return {
  PickCompileCommands = PickCompileCommands,
}
