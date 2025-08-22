#!/bin/bash

set -e

echo "🚀 Installing Claude Code + Neovim Integration"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for Python 3
echo -n "Checking for Python 3... "
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo "  Found Python $PYTHON_VERSION"
else
    echo -e "${RED}✗${NC}"
    echo "  Python 3 is required. Please install it first."
    exit 1
fi

# Check for pip
echo -n "Checking for pip... "
if command -v pip3 &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  pip3 is required. Please install it first."
    exit 1
fi

# Check for Neovim
echo -n "Checking for Neovim... "
if command -v nvim &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
    NVIM_VERSION=$(nvim --version | head -1)
    echo "  Found $NVIM_VERSION"
else
    echo -e "${RED}✗${NC}"
    echo "  Neovim is required. Please install it first."
    exit 1
fi

# Install Python dependencies in virtual environment
echo ""
echo "Setting up Python virtual environment..."
cd "$SCRIPT_DIR/file-watcher"
python3 -m venv venv
if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Failed to create virtual environment"
    exit 1
fi

echo "Installing Python dependencies..."
./venv/bin/pip install -r requirements.txt
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Python dependencies installed in virtual environment"
else
    echo -e "${RED}✗${NC} Failed to install Python dependencies"
    exit 1
fi
cd -

# Create config directory
CONFIG_DIR="$HOME/.config/claude-code-nvim"
echo ""
echo "Creating configuration directory..."
mkdir -p "$CONFIG_DIR"

# Copy default config if it doesn't exist
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    cat > "$CONFIG_DIR/config.yaml" << EOF
# Claude Code + Neovim Integration Configuration

# Paths to watch for changes
watch_paths:
  - $(pwd)

# Socket path for IPC communication
socket_path: /tmp/claude-code-nvim.sock

# Patterns to ignore
ignore_patterns:
  - "*.pyc"
  - "__pycache__"
  - "node_modules"
  - ".git"
  - ".svn"
  - ".hg"
  - "*.swp"
  - "*.swo"
  - ".DS_Store"

# File patterns to watch (empty means all files)
watch_patterns: []

# Cache settings
cache_max_files: 100

# Debounce delay in seconds
debounce_delay: 0.1
EOF
    echo -e "${GREEN}✓${NC} Created default configuration at $CONFIG_DIR/config.yaml"
else
    echo -e "${YELLOW}!${NC} Configuration already exists at $CONFIG_DIR/config.yaml"
fi

# Link or copy file watcher
WATCHER_INSTALL_DIR="$HOME/.local/share/claude-code-nvim"
mkdir -p "$WATCHER_INSTALL_DIR"
cp -r "$SCRIPT_DIR/file-watcher"/* "$WATCHER_INSTALL_DIR/"
chmod +x "$WATCHER_INSTALL_DIR/watcher.py"
echo -e "${GREEN}✓${NC} Installed file watcher to $WATCHER_INSTALL_DIR"

# Install Neovim plugin
echo ""
echo "Installing Neovim plugin..."

# Detect plugin manager
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [ -d "$NVIM_CONFIG_DIR/pack" ]; then
    # Native package management
    PLUGIN_DIR="$NVIM_CONFIG_DIR/pack/claude-code/start/claude-code-nvim"
    mkdir -p "$(dirname "$PLUGIN_DIR")"
    ln -sfn "$SCRIPT_DIR/nvim-plugin" "$PLUGIN_DIR"
    echo -e "${GREEN}✓${NC} Installed via native package management"
    
elif [ -d "$HOME/.local/share/nvim/site/pack" ]; then
    # Alternative native package location
    PLUGIN_DIR="$HOME/.local/share/nvim/site/pack/claude-code/start/claude-code-nvim"
    mkdir -p "$(dirname "$PLUGIN_DIR")"
    ln -sfn "$SCRIPT_DIR/nvim-plugin" "$PLUGIN_DIR"
    echo -e "${GREEN}✓${NC} Installed via native package management"
    
else
    echo -e "${YELLOW}!${NC} Could not detect Neovim plugin manager"
    echo ""
    echo "Please add the following to your Neovim configuration:"
    echo ""
    echo "  For Packer:"
    echo "    use '$SCRIPT_DIR/nvim-plugin'"
    echo ""
    echo "  For vim-plug:"
    echo "    Plug '$SCRIPT_DIR/nvim-plugin'"
    echo ""
    echo "  For lazy.nvim:"
    echo "    { '$SCRIPT_DIR/nvim-plugin' }"
fi

# Create start/stop scripts
echo ""
echo "Creating helper scripts..."

# Create start script in user's PATH
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/claude-code-watch" << EOF
#!/bin/bash
# Claude Code + Neovim Integration File Watcher
# This script starts the file watcher service that monitors Claude Code changes

WATCHER_DIR="$WATCHER_INSTALL_DIR"
PYTHON_BIN="\$WATCHER_DIR/venv/bin/python"
WATCHER_SCRIPT="\$WATCHER_DIR/watcher.py"

if [ ! -f "\$PYTHON_BIN" ]; then
    echo "❌ Error: Python virtual environment not found at \$PYTHON_BIN"
    echo "Please run the installation script again: ./install.sh"
    exit 1
fi

if [ ! -f "\$WATCHER_SCRIPT" ]; then
    echo "❌ Error: Watcher script not found at \$WATCHER_SCRIPT"
    echo "Please run the installation script again: ./install.sh"
    exit 1
fi

echo "🚀 Starting Claude Code file watcher..."
echo "📁 Watching: \$(pwd)"
echo "🔌 Socket: /tmp/claude-code-nvim.sock"
echo ""
echo "💡 In Neovim, use :ClaudeCodeStart to connect"
echo "   Or press <leader>Cs to start the connection"
echo ""
echo "Press Ctrl+C to stop the watcher"
echo ""

exec "\$PYTHON_BIN" "\$WATCHER_SCRIPT"
EOF
chmod +x "$HOME/.local/bin/claude-code-watch"

# Also create a desktop shortcut script
cat > "$HOME/.local/bin/claude-code-watch-here" << EOF
#!/bin/bash
# Start Claude Code watcher in current directory
cd "\$(pwd)"
claude-code-watch
EOF
chmod +x "$HOME/.local/bin/claude-code-watch-here"

# Systemd service (Linux)
if [ "$(uname)" = "Linux" ] && command -v systemctl &> /dev/null; then
    SERVICE_FILE="$HOME/.config/systemd/user/claude-code-watcher.service"
    mkdir -p "$(dirname "$SERVICE_FILE")"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Claude Code File Watcher for Neovim
After=graphical-session.target

[Service]
Type=simple
ExecStart=$WATCHER_INSTALL_DIR/venv/bin/python $WATCHER_INSTALL_DIR/watcher.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
    
    systemctl --user daemon-reload
    echo -e "${GREEN}✓${NC} Created systemd service"
    echo "  To enable auto-start: systemctl --user enable claude-code-watcher"
    echo "  To start now: systemctl --user start claude-code-watcher"
fi

# LaunchAgent (macOS)
if [ "$(uname)" = "Darwin" ]; then
    PLIST_FILE="$HOME/Library/LaunchAgents/com.claude-code-nvim.watcher.plist"
    mkdir -p "$(dirname "$PLIST_FILE")"
    
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude-code-nvim.watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>$WATCHER_INSTALL_DIR/venv/bin/python</string>
        <string>$WATCHER_INSTALL_DIR/watcher.py</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/claude-code-watcher.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claude-code-watcher.err</string>
</dict>
</plist>
EOF
    
    echo -e "${GREEN}✓${NC} Created LaunchAgent"
    echo "  To load: launchctl load $PLIST_FILE"
    echo "  To start: launchctl start com.claude-code-nvim.watcher"
fi

echo ""
echo "============================================="
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Start the file watcher:"
echo "   claude-code-watch"
echo ""
echo "2. In Neovim, the plugin will auto-load. Commands:"
echo "   :ClaudeCodeStart    - Connect to watcher"
echo "   :ClaudeCodeStatus   - Check connection status"
echo "   :ClaudeCodeReview   - Review pending changes"
echo ""
echo "3. Configure the plugin in your init.lua:"
echo "   require('claude-code-nvim').setup({"
echo "     auto_start = true,"
echo "     auto_accept = false,"
echo "     diff_preview = true"
echo "   })"
echo ""
echo "Happy coding! 🎉"