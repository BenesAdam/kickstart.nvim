-- Linting

vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

local lint = require 'lint'
vim.g.lint_enabled = vim.g.lint_enabled or false

local clangtidy = lint.linters.clangtidy
clangtidy.args = {
  '--quiet',
  '--checks=-*,clang-analyzer-*,bugprone-*,cert-*,cppcoreguidelines-*,modernize-*,performance-*,readability-*,misc-*,deadcode-*,clang-diagnostic-*,concurrency-*,portability-*',
}

lint.linters_by_ft = {
  markdown = { 'markdownlint' }, -- Make sure to install `markdownlint` via mason / npm
  python = { 'pylint' },
  cpp = { 'clangtidy' },
}

-- To allow other plugins to add linters to require('lint').linters_by_ft,
-- instead set linters_by_ft like this:
-- lint.linters_by_ft = lint.linters_by_ft or {}
-- lint.linters_by_ft['markdown'] = { 'markdownlint' }
--
-- However, note that this will enable a set of default linters,
-- which will cause errors unless these tools are available:
-- {
--   clojure = { "clj-kondo" },
--   dockerfile = { "hadolint" },
--   inko = { "inko" },
--   janet = { "janet" },
--   json = { "jsonlint" },
--   markdown = { "vale" },
--   rst = { "vale" },
--   ruby = { "ruby" },
--   terraform = { "tflint" },
--   text = { "vale" }
-- }
--
-- You can disable the default linters by setting their filetypes to nil:
-- lint.linters_by_ft['clojure'] = nil
-- lint.linters_by_ft['dockerfile'] = nil
-- lint.linters_by_ft['inko'] = nil
-- lint.linters_by_ft['janet'] = nil
-- lint.linters_by_ft['json'] = nil
-- lint.linters_by_ft['markdown'] = nil
-- lint.linters_by_ft['rst'] = nil
-- lint.linters_by_ft['ruby'] = nil
-- lint.linters_by_ft['terraform'] = nil
-- lint.linters_by_ft['text'] = nil

-- Create autocommand which carries out the actual linting
-- on the specified events.
local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function()
    if vim.g.lint_enabled and vim.bo.modifiable then
      lint.try_lint()
    end
  end,
})

vim.keymap.set('n', '<leader>tl', function()
  vim.g.lint_enabled = not vim.g.lint_enabled
  if vim.g.lint_enabled then
    lint.try_lint()
    vim.notify('Lint enabled', vim.log.levels.INFO)
  else
    for _, linters in pairs(lint.linters_by_ft) do
      for _, name in ipairs(linters) do
        vim.diagnostic.reset(lint.get_namespace(name))
      end
    end
    vim.notify('Lint disabled', vim.log.levels.INFO)
  end
end, { desc = '[T]oggle [L]int' })
