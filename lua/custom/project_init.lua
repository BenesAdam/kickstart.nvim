local M = {}
local project_module = nil

function M.get_path()
  return vim.fn.getcwd() .. '/lua/init.lua'
end

function M.exists()
  return vim.fn.file_readable(M.get_path()) == 1
end

function M.load()
  if M.exists() then
    project_module = dofile(M.get_path())
  end
end

function M.get_module()
  if not project_module then
    M.load()
  end

  return project_module
end

function M.configure()
  if project_module and project_module.configure then
    project_module.configure()
  end
end

function M.get_clangd_sufix()
  if project_module ~= nil then
    if project_module.get_clangd_sufix ~= nil then
      return project_module.get_clangd_sufix()
    else
      vim.notify 'Function get_clangd_sufix not defined.'
      return ''
    end
  else
    vim.notify 'Project module not exists.'
    return ''
  end
end

return M
