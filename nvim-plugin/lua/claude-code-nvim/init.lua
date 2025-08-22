local M = {}

-- Version information
M._VERSION = "1.0.0"

local config = require('claude-code-nvim.config')
local events = require('claude-code-nvim.events')
local buffer = require('claude-code-nvim.buffer')
local ui = require('claude-code-nvim.ui')
local ipc = require('claude-code-nvim.ipc')

M.state = {
    connected = false,
    pending_changes = {},
    active_buffers = {},
    config = {}
}

function M.version()
    return M._VERSION
end

function M.setup(user_config)
    M.state.config = config.setup(user_config)
    
    -- Initialize components
    ipc.init(M.state)
    events.init(M.state)
    buffer.init(M.state)
    ui.init(M.state)
    
    -- Set up commands
    M._setup_commands()
    
    -- Set up autocommands
    M._setup_autocmds()
    
    vim.notify("Claude Code integration initialized", vim.log.levels.INFO)
end

function M.start()
    if M.state.connected then
        vim.notify("Already connected to Claude Code watcher", vim.log.levels.WARN)
        return
    end
    
    -- Check if watcher might be startable
    local socket_exists = vim.fn.filereadable(M.state.config.socket_path) == 1
    if not socket_exists and M.state.config.auto_start_watcher then
        M._try_start_watcher()
    end
    
    ipc.connect(function(success)
        if success then
            M.state.connected = true
            ui.update_statusline("connected")
            vim.notify("✅ Connected to Claude Code watcher", vim.log.levels.INFO, { title = "Claude Code" })
        end
    end)
end

-- Try to start the watcher automatically
function M._try_start_watcher()
    vim.notify("🚀 Attempting to start Claude Code watcher...", vim.log.levels.INFO, { title = "Claude Code" })
    
    -- Try to start using the installed command
    local handle = vim.fn.jobstart("claude-code-watch", {
        detach = true,
        on_exit = function(_, code)
            if code ~= 0 then
                vim.schedule(function()
                    vim.notify("Failed to auto-start watcher. Please run 'claude-code-watch' manually.", vim.log.levels.WARN)
                end)
            end
        end
    })
    
    if handle > 0 then
        -- Give it a moment to start
        vim.defer_fn(function()
            vim.notify("Watcher started! Connecting...", vim.log.levels.INFO)
        end, 1000)
    end
end

function M.stop()
    if not M.state.connected then
        vim.notify("Not connected to Claude Code watcher", vim.log.levels.WARN)
        return
    end
    
    ipc.disconnect()
    M.state.connected = false
    ui.update_statusline("disconnected")
    vim.notify("Disconnected from Claude Code watcher", vim.log.levels.INFO)
end

function M.status()
    local status = M.state.connected and "Connected" or "Disconnected"
    local pending = vim.tbl_count(M.state.pending_changes)
    
    vim.notify(string.format(
        "Claude Code Status:\n  Connection: %s\n  Pending changes: %d",
        status, pending
    ), vim.log.levels.INFO)
end

function M.review_changes()
    if vim.tbl_count(M.state.pending_changes) == 0 then
        vim.notify("No pending changes to review", vim.log.levels.INFO)
        return
    end
    
    ui.show_changes_window(M.state.pending_changes)
end

function M.accept_change(change_id)
    local change = M.state.pending_changes[change_id]
    if not change then
        vim.notify("Change not found: " .. change_id, vim.log.levels.ERROR)
        return
    end
    
    buffer.apply_change(change)
    M.state.pending_changes[change_id] = nil
    
    -- Notify watcher
    ipc.send_message({
        type = "ACCEPT_CHANGE",
        change_id = change_id
    })
    
    vim.notify("Change accepted: " .. change.file_path, vim.log.levels.INFO)
end

function M.reject_change(change_id)
    local change = M.state.pending_changes[change_id]
    if not change then
        vim.notify("Change not found: " .. change_id, vim.log.levels.ERROR)
        return
    end
    
    M.state.pending_changes[change_id] = nil
    
    -- Notify watcher
    ipc.send_message({
        type = "REJECT_CHANGE",
        change_id = change_id
    })
    
    vim.notify("Change rejected: " .. change.file_path, vim.log.levels.INFO)
end

function M.accept_all_changes()
    for change_id, _ in pairs(M.state.pending_changes) do
        M.accept_change(change_id)
    end
end

function M.reject_all_changes()
    for change_id, _ in pairs(M.state.pending_changes) do
        M.reject_change(change_id)
    end
end

function M._setup_commands()
    vim.api.nvim_create_user_command('ClaudeCodeStart', M.start, {})
    vim.api.nvim_create_user_command('ClaudeCodeStop', M.stop, {})
    vim.api.nvim_create_user_command('ClaudeCodeStatus', M.status, {})
    vim.api.nvim_create_user_command('ClaudeCodeReview', M.review_changes, {})
    vim.api.nvim_create_user_command('ClaudeCodeAcceptAll', M.accept_all_changes, {})
    vim.api.nvim_create_user_command('ClaudeCodeRejectAll', M.reject_all_changes, {})
end

function M._setup_autocmds()
    local group = vim.api.nvim_create_augroup('ClaudeCodeNvim', { clear = true })
    
    -- Auto-start on enter
    if M.state.config.auto_start then
        vim.api.nvim_create_autocmd('VimEnter', {
            group = group,
            callback = function()
                vim.defer_fn(M.start, 100)
            end
        })
    end
    
    -- Clean up on exit
    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = group,
        callback = function()
            if M.state.connected then
                M.stop()
            end
        end
    })
end

return M