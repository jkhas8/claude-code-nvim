# Claude Code + Neovim Integration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/jkhas8/claude-code-nvim)](https://github.com/jkhas8/claude-code-nvim/issues)
[![GitHub stars](https://img.shields.io/github/stars/jkhas8/claude-code-nvim)](https://github.com/jkhas8/claude-code-nvim/stargazers)

A seamless bridge between [Claude Code](https://claude.ai/code) CLI and Neovim that provides real-time file change synchronization, diff previews, and interactive change acceptance/rejection.

<p align="center">
  <img src="https://github.com/jkhas8/claude-code-nvim/assets/demo.gif" alt="Demo" width="800">
</p>

## 🌟 Features

- **Real-time Sync**: See Claude Code's file changes instantly in Neovim (<100ms latency)
- **Diff Preview**: Visual floating windows showing exactly what changed
- **Interactive Control**: Accept or reject changes from within Neovim
- **Change Indicators**: Visual markers in the sign column for modified lines
- **Auto-reload**: Automatically refresh buffers when files change
- **Non-intrusive**: Works alongside your existing Neovim workflow
- **Configurable**: Customize behavior, appearance, and keybindings
- **Cross-platform**: Linux, macOS, and Windows (WSL) support

## 📋 Requirements

- **Neovim** 0.8.0+ 
- **Python** 3.8+
- **Claude Code CLI** (latest version)

## 🚀 Installation

### Quick Install

```bash
git clone https://github.com/jkhas8/claude-code-nvim.git
cd claude-code-nvim
./install.sh
```

### Manual Install

<details>
<summary>Click to expand manual installation steps</summary>

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jkhas8/claude-code-nvim.git
   cd claude-code-nvim
   ```

2. **Install Python dependencies:**
   ```bash
   cd file-watcher
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Install Neovim plugin:**
   
   **For lazy.nvim:**
   ```lua
   {
     "jkhas8/claude-code-nvim",
     config = function()
       require("claude-code-nvim").setup()
     end
   }
   ```

   **For packer.nvim:**
   ```lua
   use {
     "jkhas8/claude-code-nvim",
     config = function()
       require("claude-code-nvim").setup()
     end
   }
   ```

   **For vim-plug:**
   ```vim
   Plug 'jkhas8/claude-code-nvim'
   ```

</details>

## 🎯 Quick Start

1. **Start the file watcher:**
   ```bash
   claude-code-watch
   ```

2. **In Neovim, connect to the watcher:**
   ```vim
   :ClaudeCodeStart
   ```

3. **Use Claude Code as normal** - changes will appear instantly in Neovim!

4. **Review and accept/reject changes:**
   ```vim
   :ClaudeCodeReview
   ```

## 📋 Commands

| Command | Description |
|---------|-------------|
| `:ClaudeCodeStart` | Connect to the file watcher |
| `:ClaudeCodeStop` | Disconnect from the file watcher |
| `:ClaudeCodeStatus` | Show connection and change status |
| `:ClaudeCodeReview` | Open the changes review window |
| `:ClaudeCodeAcceptAll` | Accept all pending changes |
| `:ClaudeCodeRejectAll` | Reject all pending changes |

## ⚙️ Configuration

Add to your `init.lua`:

```lua
require('claude-code-nvim').setup({
  -- Connection settings
  socket_path = '/tmp/claude-code-nvim.sock',
  auto_start = true,
  auto_reconnect = true,
  
  -- UI settings
  show_notifications = true,
  show_statusline = true,
  diff_preview = true,
  
  -- Behavior
  auto_accept = false,  -- Set to true for automatic acceptance
  auto_reload = true,
  
  -- Appearance
  icons = {
    added = '+',
    deleted = '-',
    modified = '~',
    pending = '●',
    connected = '✓',
    disconnected = '✗'
  },
  
  -- Keymaps (in diff windows)
  keymaps = {
    accept = '<CR>',
    reject = '<Esc>',
    diff = 'd'
  }
})
```

## 🎯 How It Works

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Claude Code   │───▶│  File System    │───▶│  File Watcher   │
│      CLI        │    │                 │    │    Service      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        │ IPC
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Neovim      │◀───│   Diff Preview  │◀───│  Neovim Plugin  │
│     Editor      │    │     Window      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

1. **Claude Code** modifies files
2. **File Watcher** detects changes via filesystem events
3. **Neovim Plugin** receives change notifications
4. **Diff Preview** shows what changed
5. **You decide** whether to accept or reject changes

## 🔧 Architecture

- **File Watcher** (`file-watcher/watcher.py`): Python service using `watchdog` for filesystem monitoring
- **Neovim Plugin** (`nvim-plugin/`): Lua plugin for Neovim integration
- **IPC Communication**: Unix sockets for fast, reliable communication
- **Diff Engine**: Line-by-line change detection and visualization

## 🛠️ Development

### Project Structure
```
claude-code-nvim/
├── file-watcher/           # Python file watcher service
│   ├── watcher.py          # Main watcher implementation
│   └── requirements.txt    # Python dependencies
├── nvim-plugin/           # Neovim plugin
│   ├── lua/claude-code-nvim/
│   │   ├── init.lua       # Main plugin entry
│   │   ├── config.lua     # Configuration management
│   │   ├── ipc.lua        # IPC communication
│   │   ├── events.lua     # Event handling
│   │   ├── buffer.lua     # Buffer management
│   │   └── ui.lua         # User interface
│   └── plugin/
│       └── claude-code-nvim.vim
└── scripts/               # Installation and utility scripts
```

### Running Tests
```bash
# Test the file watcher
cd file-watcher
python3 -m pytest tests/

# Test the Neovim plugin
nvim --headless -c "PlenaryBustedDirectory nvim-plugin/tests/ {minimal_init = 'nvim-plugin/tests/minimal_init.vim'}"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🐛 Troubleshooting

### Connection Issues
- Ensure the file watcher is running: `ps aux | grep watcher.py`
- Check socket permissions: `ls -la /tmp/claude-code-nvim.sock`
- View logs: `tail -f ~/.local/share/claude-code-nvim/watcher.log`

### Performance Issues
- Reduce `debounce_delay` in configuration
- Add more patterns to `ignore_patterns`
- Limit `watch_paths` to relevant directories

### Plugin Not Loading
- Check Neovim version: `nvim --version` (requires 0.8.0+)
- Verify plugin installation path
- Check for conflicts with other plugins

## 📊 Status Line Integration

Add to your status line configuration:

```lua
-- For lualine.nvim
sections = {
  lualine_x = { 'claude_code_status' }
}

-- For vim-airline
let g:airline_section_x = airline#section#create(['claude_code_status'])
```

## 🎨 Highlighting

The plugin uses these highlight groups:
- `DiffAdd`: Added lines
- `DiffDelete`: Deleted lines  
- `DiffChange`: Modified lines
- `WarningMsg`: Pending changes

Customize with:
```lua
vim.api.nvim_set_hl(0, 'ClaudeCodeAdded', { fg = '#00ff00' })
```