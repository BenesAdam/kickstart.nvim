local M = {}
local project_module = nil

function M.is_work()
  local config_path = vim.fn.getcwd() .. '/.lfsconfig'

  if vim.fn.filereadable(config_path) == 0 then
    return false
  end

  local content = table.concat(vim.fn.readfile(config_path), '\n')
  return content:find 'artifactory%.bluel3%.com' ~= nil
end

function M.get_path()
  if M.is_work() then
    return vim.fn.expand '~/lua/init.lua'
  else
    return vim.fn.getcwd() .. '/lua/init.lua'
  end
end

function M.exists()
  return vim.fn.filereadable(M.get_path()) == 1
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
    end
  end

  return ''
end

return M
