local M = {}

local defaults = {
    -- Connection settings
    socket_path = '/tmp/claude-code-nvim.sock',
    auto_start = true,
    auto_start_watcher = false,  -- Try to start watcher automatically
    auto_reconnect = true,
    reconnect_delay = 5000,  -- ms
    
    -- UI settings
    show_notifications = true,
    show_statusline = true,
    diff_preview = true,
    floating_window = true,
    
    -- Behavior settings
    auto_accept = false,
    auto_reload = true,
    debounce_delay = 100,  -- ms
    
    -- Appearance
    highlights = {
        added = 'DiffAdd',
        deleted = 'DiffDelete',
        modified = 'DiffChange',
        pending = 'WarningMsg'
    },
    
    -- Icons
    icons = {
        added = '+',
        deleted = '-',
        modified = '~',
        pending = '●',
        connected = '✓',
        disconnected = '✗'
    },
    
    -- Keymaps
    keymaps = {
        accept = '<CR>',
        reject = '<Esc>',
        diff = 'd',
        next_change = ']c',
        prev_change = '[c'
    }
}

function M.setup(user_config)
    return vim.tbl_deep_extend('force', defaults, user_config or {})
end

return M