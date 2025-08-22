local M = {}
local state = nil

function M.init(plugin_state)
    state = plugin_state
end

function M.notify_change(change_data)
    local icon = state.config.icons[change_data.change_type:lower()] or state.config.icons.modified
    local msg = string.format(
        "%s %s: %s",
        icon,
        change_data.change_type,
        vim.fn.fnamemodify(change_data.file_path, ':~:.')
    )
    
    vim.notify(msg, vim.log.levels.INFO, { title = "Claude Code" })
end

function M.show_diff_preview(change_data)
    if not change_data.diff or not change_data.diff.hunks then
        return
    end
    
    -- Create floating window
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.6)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
        title = ' Claude Code Changes: ' .. vim.fn.fnamemodify(change_data.file_path, ':t') .. ' ',
        title_pos = 'center'
    })
    
    -- Add diff content
    local lines = {}
    table.insert(lines, "File: " .. change_data.file_path)
    table.insert(lines, "Type: " .. change_data.change_type)
    table.insert(lines, string.rep("-", width))
    
    for _, hunk in ipairs(change_data.diff.hunks) do
        if hunk.type == 'delete' then
            table.insert(lines, string.format("-%d,%d", hunk.start_line, hunk.end_line))
            for line in hunk.text:gmatch("[^\n]+") do
                table.insert(lines, "- " .. line)
            end
        elseif hunk.type == 'insert' then
            table.insert(lines, string.format("+%d", hunk.start_line))
            for line in hunk.text:gmatch("[^\n]+") do
                table.insert(lines, "+ " .. line)
            end
        end
    end
    
    table.insert(lines, string.rep("-", width))
    table.insert(lines, "")
    table.insert(lines, "Actions:")
    table.insert(lines, "  [" .. state.config.keymaps.accept .. "] Accept")
    table.insert(lines, "  [" .. state.config.keymaps.reject .. "] Reject")
    table.insert(lines, "  [q] Close")
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'diff')
    
    -- Set up keymaps
    local opts = { buffer = buf, silent = true, noremap = true }
    vim.keymap.set('n', state.config.keymaps.accept, function()
        vim.api.nvim_win_close(win, true)
        local main = require('claude-code-nvim')
        main.accept_change(change_data.id)
    end, opts)
    
    vim.keymap.set('n', state.config.keymaps.reject, function()
        vim.api.nvim_win_close(win, true)
        local main = require('claude-code-nvim')
        main.reject_change(change_data.id)
    end, opts)
    
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
    end, opts)
end

function M.show_changes_window(pending_changes)
    -- Create buffer for changes list
    local buf = vim.api.nvim_create_buf(false, true)
    
    -- Prepare content
    local lines = { "Claude Code - Pending Changes", string.rep("=", 40), "" }
    local change_list = {}
    
    for id, change in pairs(pending_changes) do
        table.insert(change_list, { id = id, change = change })
    end
    
    -- Sort by timestamp
    table.sort(change_list, function(a, b)
        return a.change.timestamp < b.change.timestamp
    end)
    
    for i, item in ipairs(change_list) do
        local change = item.change
        local icon = state.config.icons[change.change_type:lower()] or state.config.icons.modified
        local line = string.format(
            "%d. %s %s - %s",
            i,
            icon,
            vim.fn.fnamemodify(change.file_path, ':t'),
            change.change_type
        )
        table.insert(lines, line)
        table.insert(lines, "   " .. vim.fn.fnamemodify(change.file_path, ':~:.'))
        table.insert(lines, "")
    end
    
    table.insert(lines, string.rep("-", 40))
    table.insert(lines, "Actions:")
    table.insert(lines, "  [Enter] View diff")
    table.insert(lines, "  [a] Accept change")
    table.insert(lines, "  [r] Reject change")
    table.insert(lines, "  [A] Accept all")
    table.insert(lines, "  [R] Reject all")
    table.insert(lines, "  [q] Close")
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Create window
    local width = math.min(60, vim.o.columns - 4)
    local height = math.min(#lines + 2, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
        title = ' Claude Code Changes ',
        title_pos = 'center'
    })
    
    -- Set up keymaps
    local opts = { buffer = buf, silent = true, noremap = true }
    
    vim.keymap.set('n', '<CR>', function()
        local line = vim.api.nvim_win_get_cursor(win)[1]
        local idx = math.floor((line - 3) / 3) + 1
        if change_list[idx] then
            M.show_diff_preview(change_list[idx].change)
        end
    end, opts)
    
    vim.keymap.set('n', 'a', function()
        local line = vim.api.nvim_win_get_cursor(win)[1]
        local idx = math.floor((line - 3) / 3) + 1
        if change_list[idx] then
            local main = require('claude-code-nvim')
            main.accept_change(change_list[idx].id)
            vim.api.nvim_win_close(win, true)
        end
    end, opts)
    
    vim.keymap.set('n', 'r', function()
        local line = vim.api.nvim_win_get_cursor(win)[1]
        local idx = math.floor((line - 3) / 3) + 1
        if change_list[idx] then
            local main = require('claude-code-nvim')
            main.reject_change(change_list[idx].id)
            vim.api.nvim_win_close(win, true)
        end
    end, opts)
    
    vim.keymap.set('n', 'A', function()
        vim.api.nvim_win_close(win, true)
        local main = require('claude-code-nvim')
        main.accept_all_changes()
    end, opts)
    
    vim.keymap.set('n', 'R', function()
        vim.api.nvim_win_close(win, true)
        local main = require('claude-code-nvim')
        main.reject_all_changes()
    end, opts)
    
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
    end, opts)
end

function M.update_statusline(status)
    if not state.config.show_statusline then
        return
    end
    
    local icon = status == "connected" and state.config.icons.connected or state.config.icons.disconnected
    local pending = vim.tbl_count(state.pending_changes or {})
    
    vim.g.claude_code_status = string.format(
        "%s Claude Code %s",
        icon,
        pending > 0 and string.format("(%d pending)", pending) or ""
    )
end

return M