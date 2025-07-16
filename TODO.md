# TODO list

- [x] (C)make project manager
  - [x] <leader>nc -> (c)make clean
  - [x] <leader>ng -> (c)make generate
  - [x] <leader>nb -> (c)make build
  - [x] <leader>nr -> (c)make run
- [x] Template manager
  - [x] Add template to some nvim folder
  - [x] Select&Copy template to current folder
- [ ] Update cache files when compile command is selected
  - [ ] Move this functionality to other module called something like `custom_find_files.lua`
  - [ ] Search either in `compile_commands.json` on preferable in `build.ninja`.
  - [ ] Search for:
      - [ ] *.cpp, *.hpp files
      - [ ] *.c, *.h files
      - [ ] *.cmake, CMakeLists.txt files
      - [ ] *.datafield files
- [ ] Custom find file and grep in file
  - [ ] <leader>f - if compile commands selected find in this file list otherwise default
  - [ ] <leader>F - find all files
  - [ ] <leader>g - if compile commands selected grep in this file list otherwise default
  - [ ] <leader>G - grep in all files

