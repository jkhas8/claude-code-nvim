local M = {}
local uv = vim.loop

local state = nil
local socket = nil
local connected = false
local message_buffer = ""

function M.init(plugin_state)
    state = plugin_state
end

function M.connect(callback)
    local socket_path = state.config.socket_path
    
    socket = uv.new_pipe(false)
    
    socket:connect(socket_path, function(err)
        if err then
            vim.schedule(function()
                -- Show helpful error message
                local error_msg = "❌ Failed to connect to Claude Code watcher!\n\n" ..
                                "🔧 To fix this:\n" ..
                "   1. Start the watcher: claude-code-watch\n" ..
                "   2. Or run: systemctl --user start claude-code-watcher\n" ..
                "   3. Then try :ClaudeCodeStart again\n\n" ..
                "💡 Tip: Run 'claude-code-watch' in your terminal first!"
                
                vim.notify(error_msg, vim.log.levels.WARN, { title = "Claude Code" })
                if callback then callback(false) end
            end)
            return
        end
        
        connected = true
        
        -- Start reading messages
        socket:read_start(function(err, data)
            if err then
                vim.schedule(function()
                    vim.notify("Read error: " .. err, vim.log.levels.ERROR)
                    M.disconnect()
                end)
                return
            end
            
            if data then
                M._handle_data(data)
            else
                -- Connection closed
                vim.schedule(function()
                    M.disconnect()
                    if state.config.auto_reconnect then
                        vim.defer_fn(function()
                            M.connect()
                        end, state.config.reconnect_delay)
                    end
                end)
            end
        end)
        
        vim.schedule(function()
            if callback then callback(true) end
        end)
    end)
end

function M.disconnect()
    if socket then
        socket:read_stop()
        socket:close()
        socket = nil
    end
    connected = false
end

function M.send_message(message)
    if not connected or not socket then
        vim.notify("Not connected to watcher", vim.log.levels.WARN)
        return false
    end
    
    local data = vim.fn.json_encode(message) .. "\n"
    socket:write(data)
    return true
end

function M._handle_data(data)
    message_buffer = message_buffer .. data
    
    -- Process complete messages (separated by newlines)
    while true do
        local newline_pos = string.find(message_buffer, "\n")
        if not newline_pos then
            break
        end
        
        local message_str = string.sub(message_buffer, 1, newline_pos - 1)
        message_buffer = string.sub(message_buffer, newline_pos + 1)
        
        -- Parse and handle message
        local ok, message = pcall(vim.fn.json_decode, message_str)
        if ok and message then
            vim.schedule(function()
                M._handle_message(message)
            end)
        end
    end
end

function M._handle_message(message)
    local msg_type = message.type
    
    if msg_type == "HANDSHAKE" then
        vim.notify("Connected to Claude Code watcher v" .. message.version, vim.log.levels.INFO)
        
    elseif msg_type == "FILE_CHANGE" then
        local events = require('claude-code-nvim.events')
        events.handle_file_change(message.data)
        
    elseif msg_type == "PONG" then
        -- Heartbeat response
        
    elseif msg_type == "STATUS" then
        vim.notify(string.format(
            "Watcher Status:\n  Watching: %s\n  Queue: %d\n  Cache: %d",
            message.watching and "Yes" or "No",
            message.queue_size,
            message.cache_size
        ), vim.log.levels.INFO)
        
    else
        vim.notify("Unknown message type: " .. msg_type, vim.log.levels.WARN)
    end
end

-- Heartbeat to keep connection alive
function M.start_heartbeat()
    local timer = uv.new_timer()
    timer:start(30000, 30000, function()
        if connected then
            vim.schedule(function()
                M.send_message({ type = "PING" })
            end)
        end
    end)
end

return M