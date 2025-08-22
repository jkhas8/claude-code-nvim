local M = {}
local state = nil

function M.init(plugin_state)
    state = plugin_state
end

function M.handle_file_change(change_data)
    -- Store the change
    state.pending_changes[change_data.id] = change_data
    
    -- Get the buffer for this file if it's open
    local bufnr = M._find_buffer(change_data.file_path)
    
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        -- Mark buffer as having pending changes
        vim.api.nvim_buf_set_var(bufnr, 'claude_code_pending', true)
        
        -- Add visual indicators
        if state.config.show_notifications then
            M._add_change_indicators(bufnr, change_data)
        end
        
        -- Show notification
        if state.config.show_notifications then
            local ui = require('claude-code-nvim.ui')
            ui.notify_change(change_data)
        end
        
        -- Auto-accept if configured
        if state.config.auto_accept then
            vim.defer_fn(function()
                local main = require('claude-code-nvim')
                main.accept_change(change_data.id)
            end, 100)
        elseif state.config.diff_preview then
            -- Show diff preview
            local ui = require('claude-code-nvim.ui')
            ui.show_diff_preview(change_data)
        end
    else
        -- File not open, just notify
        if state.config.show_notifications then
            vim.notify(string.format(
                "Claude Code changed: %s (%s)",
                vim.fn.fnamemodify(change_data.file_path, ':t'),
                change_data.change_type
            ), vim.log.levels.INFO)
        end
    end
    
    -- Update statusline
    local ui = require('claude-code-nvim.ui')
    ui.update_statusline()
end

function M._find_buffer(file_path)
    -- Normalize path
    local normalized = vim.fn.fnamemodify(file_path, ':p')
    
    -- Check all buffers
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        if buf_name ~= '' then
            local buf_normalized = vim.fn.fnamemodify(buf_name, ':p')
            if buf_normalized == normalized then
                return bufnr
            end
        end
    end
    
    return nil
end

function M._add_change_indicators(bufnr, change_data)
    local ns_id = vim.api.nvim_create_namespace('claude_code_changes')
    
    if change_data.diff and change_data.diff.hunks then
        for _, hunk in ipairs(change_data.diff.hunks) do
            local start_line = hunk.start_line - 1
            local end_line = hunk.end_line or hunk.start_line
            
            -- Add extmark for the change
            if hunk.type == 'delete' then
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, 0, {
                    sign_text = state.config.icons.deleted,
                    sign_hl_group = state.config.highlights.deleted,
                    priority = 100
                })
            elseif hunk.type == 'insert' then
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, 0, {
                    sign_text = state.config.icons.added,
                    sign_hl_group = state.config.highlights.added,
                    priority = 100
                })
            else
                vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_line, 0, {
                    sign_text = state.config.icons.modified,
                    sign_hl_group = state.config.highlights.modified,
                    priority = 100
                })
            end
        end
    end
end

return M