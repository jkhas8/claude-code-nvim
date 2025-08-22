local M = {}
local state = nil

function M.init(plugin_state)
    state = plugin_state
end

function M.apply_change(change)
    if change.change_type == "DELETE" then
        M._handle_delete(change)
    elseif change.change_type == "CREATE" then
        M._handle_create(change)
    elseif change.change_type == "MODIFY" then
        M._handle_modify(change)
    end
end

function M._handle_delete(change)
    local bufnr = M._find_buffer(change.file_path)
    
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        -- Ask for confirmation
        local choice = vim.fn.confirm(
            "Claude Code deleted this file. Close buffer?",
            "&Yes\n&No",
            1
        )
        
        if choice == 1 then
            vim.api.nvim_buf_delete(bufnr, { force = false })
        end
    end
    
    -- Delete the actual file
    os.remove(change.file_path)
end

function M._handle_create(change)
    if not change.new_content then
        return
    end
    
    -- Write the file
    local file = io.open(change.file_path, "w")
    if file then
        file:write(change.new_content)
        file:close()
        
        -- Open in new buffer if requested
        if state.config.auto_open_new then
            vim.cmd("edit " .. vim.fn.fnameescape(change.file_path))
        end
    else
        vim.notify("Failed to create file: " .. change.file_path, vim.log.levels.ERROR)
    end
end

function M._handle_modify(change)
    local bufnr = M._find_buffer(change.file_path)
    
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        -- Apply changes to buffer
        if change.new_content then
            -- Save cursor position
            local cursor_save = vim.api.nvim_win_get_cursor(0)
            local view_save = vim.fn.winsaveview()
            
            -- Split content into lines
            local lines = {}
            for line in change.new_content:gmatch("([^\n]*)\n?") do
                table.insert(lines, line)
            end
            
            -- Remove trailing empty line if present
            if lines[#lines] == "" then
                table.remove(lines)
            end
            
            -- Update buffer
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
            
            -- Restore cursor position
            pcall(vim.api.nvim_win_set_cursor, 0, cursor_save)
            pcall(vim.fn.winrestview, view_save)
            
            -- Clear change indicators
            local ns_id = vim.api.nvim_create_namespace('claude_code_changes')
            vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
            
            -- Mark as not having pending changes
            vim.api.nvim_buf_set_var(bufnr, 'claude_code_pending', false)
            
            vim.notify("Applied changes to " .. vim.fn.fnamemodify(change.file_path, ':t'), vim.log.levels.INFO)
        end
    else
        -- File not open in buffer, write directly to disk
        if change.new_content then
            local file = io.open(change.file_path, "w")
            if file then
                file:write(change.new_content)
                file:close()
                vim.notify("Updated file: " .. vim.fn.fnamemodify(change.file_path, ':t'), vim.log.levels.INFO)
            else
                vim.notify("Failed to update file: " .. change.file_path, vim.log.levels.ERROR)
            end
        end
    end
end

function M._find_buffer(file_path)
    local normalized = vim.fn.fnamemodify(file_path, ':p')
    
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

function M.reload_buffer(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    if file_path == '' or not vim.fn.filereadable(file_path) then
        return
    end
    
    -- Save cursor position
    local cursor_save = vim.api.nvim_win_get_cursor(0)
    local view_save = vim.fn.winsaveview()
    
    -- Reload the file
    vim.cmd('checktime ' .. bufnr)
    
    -- Restore cursor position
    pcall(vim.api.nvim_win_set_cursor, 0, cursor_save)
    pcall(vim.fn.winrestview, view_save)
end

return M