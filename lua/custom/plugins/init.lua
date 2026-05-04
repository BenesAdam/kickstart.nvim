-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Add :LspInfo alias
vim.api.nvim_create_user_command('LspInfo', 'checkhealth vim.lsp', {})

---@module 'lazy'
---@type LazySpec
return {}
