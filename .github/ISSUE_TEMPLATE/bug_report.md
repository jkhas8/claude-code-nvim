---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment (please complete the following information):**
- OS: [e.g. Linux, macOS, Windows]
- OS Version: [e.g. Ubuntu 22.04, macOS 13.0, Windows 11]
- Neovim version: [e.g. 0.8.0]
- Python version: [e.g. 3.10.0]
- Claude Code CLI version: [e.g. 1.2.3]

**Configuration**
If applicable, share your configuration:

```lua
-- Your claude-code-nvim setup configuration
require('claude-code-nvim').setup({
  -- your config here
})
```

**Logs**
If applicable, add logs to help explain your problem:

```bash
# File watcher logs
tail -f ~/.local/share/claude-code-nvim/watcher.log

# Or manual run output
claude-code-watch
```

**Additional context**
Add any other context about the problem here.

**Checklist**
- [ ] I have searched existing issues to ensure this is not a duplicate
- [ ] I have included all relevant information above
- [ ] I have tested with the latest version