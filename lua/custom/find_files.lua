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
  local suffixes = {
    '.cpp',
    '.hpp',
    '.c',
    '.h',
    '.asm',
    '.datafield',
    '.cmake',
    'CMakeLists.txt',
  }

  local file = io.open(build_ninja_path, 'r')
  if not file then
    vim.notify('build.ninja file not found', vim.log.levels.ERROR)
    return files
  end

  local base_dir = build_ninja_path:match '(.*/)'
  local source_path = ''
  local seen = {}

  for line in file:lines() do
    if source_path == '' then
      local s = line:match '%-S"([^"]+)"' or line:match '%-S([^%s"]+)'
      if s then
        source_path = s:gsub('\\', '/'):gsub('//', '/')
      end
    end

    for word in line:gmatch '%S+' do
      word = word:gsub('%*', ' '):gsub('%$', '')
      for _, ext in ipairs(suffixes) do
        if word:sub(-#ext) == ext then
          if not word:match '^/' and not word:match '^%a:[/\\]' then
            word = base_dir .. word
          end

          word = word:gsub('\\', '/'):gsub('//', '/')

          if not seen[word] then
            seen[word] = true
            table.insert(files, word)
          end

          break
        end
      end
    end
  end

  file:close()

  return files
end

local function test_build_ninja()
  -- local build_ninja_path = 'E:/Downloads/test_project/build/build.ninja'
  local build_ninja_path = 'I:/output/est90/build.ninja'
  local files = get_files_from_build_ninja(build_ninja_path)

  local output_file = io.open(vim.fn.fnamemodify(build_ninja_path, ':h') .. '/nvim_test.txt', 'w')
  for _, file in pairs(files) do
    -- print(file)
    output_file:write(file .. '\n')
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
