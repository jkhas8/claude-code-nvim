" claude-code-nvim.vim - Main plugin file

if exists('g:loaded_claude_code_nvim')
  finish
endif
let g:loaded_claude_code_nvim = 1

" Initialize the plugin
lua require('claude-code-nvim').setup(vim.g.claude_code_config or {})