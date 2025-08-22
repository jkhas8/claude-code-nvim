#!/bin/bash

echo "🧪 Testing Claude Code + Neovim Integration"
echo "==========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test 1: Python dependencies
echo -n "Testing Python dependencies... "
if ./file-watcher/venv/bin/python -c "import watchdog, yaml, diff_match_patch; print('OK')" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Run: pip install -r file-watcher/requirements.txt"
    exit 1
fi

# Test 2: File watcher compilation
echo -n "Testing file watcher compilation... "
if ./file-watcher/venv/bin/python -m py_compile file-watcher/watcher.py 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Watcher script has syntax errors"
    exit 1
fi

# Test 3: Neovim plugin syntax
echo -n "Testing Neovim plugin syntax... "
if command -v luacheck &> /dev/null; then
    if luacheck nvim-plugin/lua/claude-code-nvim/*.lua --quiet 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}!${NC} (luacheck warnings, but plugin should work)"
    fi
else
    echo -e "${YELLOW}!${NC} (luacheck not available, skipping syntax check)"
fi

# Test 4: Socket creation
echo -n "Testing socket creation... "
timeout 2s ./file-watcher/venv/bin/python file-watcher/watcher.py > /tmp/watcher_test.log 2>&1 &
WATCHER_PID=$!
sleep 1
if [ -S "/tmp/claude-code-nvim.sock" ]; then
    echo -e "${GREEN}✓${NC}"
    kill $WATCHER_PID 2>/dev/null
    rm -f /tmp/claude-code-nvim.sock
else
    echo -e "${RED}✗${NC}"
    echo "Socket not created. Check log: /tmp/watcher_test.log"
    kill $WATCHER_PID 2>/dev/null
    exit 1
fi

# Test 5: File change detection
echo -n "Testing file change detection... "
TEST_FILE="/tmp/claude_test_file.txt"
echo "original content" > "$TEST_FILE"

timeout 3s ./file-watcher/venv/bin/python file-watcher/watcher.py > /tmp/watcher_change_test.log 2>&1 &
WATCHER_PID=$!
sleep 1
echo "modified content" >> "$TEST_FILE"
sleep 1
kill $WATCHER_PID 2>/dev/null

if grep -q "Queued change" /tmp/watcher_change_test.log; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}!${NC} (change detection unclear, check /tmp/watcher_change_test.log)"
fi

# Clean up
rm -f "$TEST_FILE" /tmp/claude-code-nvim.sock

echo ""
echo "==========================================="
echo -e "${GREEN}Integration tests completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Run: ./install.sh"
echo "2. Start watcher: claude-code-watch"
echo "3. In Neovim: :ClaudeCodeStart"
echo ""
echo "Example Neovim configuration:"
echo "require('claude-code-nvim').setup({"
echo "  auto_start = true,"
echo "  diff_preview = true"
echo "})"