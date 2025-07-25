M = {}

local function get_files_from_compile_commands(compile_commands_path)
  local files = {}

  -- Read file
  local file_handler = io.open(compile_commands_path, 'r')

  if not file_handler then
    vim.notify('Compile commands file not existed', vim.log.levels.ERROR)
    return files
  end

  local file_content = file_handler:read 'a'
  file_handler:close()

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

local function test_compile_commands()
  -- local compile_command_path = 'E:/Downloads/test_project/build/compile_commands.json'
  local compile_command_path = 'I:/output/est90/compile_commands.json'
  local files = get_files_from_compile_commands(compile_command_path)
  for _, file in pairs(files) do
    print(file)
  end
end

local function get_files_from_build_ninja(build_ninja_path)
  local files = {}

  local suffix_matches = {
    '%.cpp',
    '%.hpp',
    '%.c',
    '%.h',
    '%.asm',
    '%.datafield',
    '%.cmake', -- TODO: what about cmake file in output folder?
    'CMakeLists%.txt',
  }

  local Path = require 'plenary.path'

  -- Read file
  local file_handler = io.open(build_ninja_path, 'r')

  if not file_handler then
    vim.notify('build.ninja file not existed', vim.log.levels.ERROR)
    return files
  end

  local file_content = file_handler:read 'a'
  file_handler:close()

  -- Get source path
  local source_path_quoted = file_content:match '%-S"([^"]+)"'
  local source_path_unquoted = file_content:match '%-S([^%s"]+)'
  local source_path = source_path_quoted or source_path_unquoted or ''
  source_path = string.gsub(source_path, '\\', '/')
  source_path = string.gsub(source_path, '//', '/')

  -- Get all files
  file_content = string.gsub(file_content, '%$ ', '%*')
  local base_dir = vim.fn.fnamemodify(build_ninja_path, ':h')
  local all_files = {}
  file_content = file_content:gsub('%$ ', '*')

  for match in file_content:gmatch '(%S*[a-zA-Z]+%S*%.%S*[a-zA-Z]+%S*[^:\n%s\\%/"])' do
    table.insert(all_files, match)
  end

  for i, val in ipairs(all_files) do
    val = val:gsub('%*', ' ')
    val = val:gsub('%$', '')
    all_files[i] = val
  end

  -- Filter files
  for _, file in ipairs(all_files) do
    local path_object = Path:new(file)
    if not path_object:is_absolute() then
      path_object = Path:new(base_dir, file)
    end

    file = path_object:absolute()
    file = string.gsub(file, '\\', '/')
    file = string.gsub(file, '//', '/')

    local approved_extension = false
    for _, ext in ipairs(suffix_matches) do
      if string.match(file, ext .. '$') then
        approved_extension = true
        break
      end
    end

    if approved_extension then
      table.insert(files, file)
    end
  end

  -- Sort files
  table.sort(files, function(a, b)
    local a_in_source = string.match(a, '^' .. source_path) ~= nil
    local b_in_source = string.match(b, '^' .. source_path) ~= nil

    if a_in_source and not b_in_source then
      return true
    elseif not a_in_source and b_in_source then
      return false
    else
      return a < b
    end
  end)

  return files
end

local function test_build_ninja()
  local build_ninja_path = 'E:/Downloads/test_project/build/build.ninja'
  -- local build_ninja_path = 'I:/output/est90/build.ninja'
  local files = get_files_from_build_ninja(build_ninja_path)

  local output_file = io.open(vim.fn.fnamemodify(build_ninja_path, ':h') .. '/nvim_test.txt', 'w')
  for _, file in pairs(files) do
    print(file)
    -- output_file:write(file .. '\n')
  end
  output_file:close()
end

-- test_compile_commands()
-- test_build_ninja()

function M.get_files(compile_commands_path)
  local files = {}
  local base_dir = vim.fn.fnamemodify(compile_commands_path, ':h')

  -- build.ninja
  local build_ninja_path = base_dir .. '/build.ninja'

  if vim.fn.file_readable(build_ninja_path) == 1 then
    local cmake_files = get_files_from_build_ninja(build_ninja_path)
    vim.list_extend(files, cmake_files)
    vim.notify(build_ninja_path, vim.log.levels.INFO)
    return files
  end

  -- compile_commands.json
  if vim.fn.file_readable(compile_commands_path) == 1 then
    local source_files = get_files_from_compile_commands(compile_commands_path)
    vim.list_extend(files, source_files)
    vim.notify(compile_commands_path, vim.log.levels.INFO)
    return files
  end

  return files
end

return M
