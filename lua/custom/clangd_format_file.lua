local M = {}

function M.get_file()
  local is_windows = vim.loop.os_uname().sysname == 'Windows_NT'

  if is_windows then
    return vim.env.HOME .. '/AppData/Local/nvim/.clang-format'
  else
    return vim.env.HOME .. '/.config/nvim/.clang-format'
  end
end

return M
