# Contributing to Claude Code + Neovim Integration

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🚀 Getting Started

### Prerequisites

- **Neovim** 0.8.0+
- **Python** 3.8+
- **Git**
- **Claude Code CLI**

### Development Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/jkhas8/claude-code-nvim.git
   cd claude-code-nvim
   ```

2. **Set up the development environment:**
   ```bash
   # Install Python dependencies
   cd file-watcher
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   pip install -r requirements-dev.txt  # Development dependencies
   
   # Run tests
   cd ..
   ./test_integration.sh
   ```

3. **Install pre-commit hooks (optional but recommended):**
   ```bash
   pip install pre-commit
   pre-commit install
   ```

## 🛠️ Development Workflow

### Making Changes

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes:**
   ```bash
   # Run integration tests
   ./test_integration.sh
   
   # Test Python code
   cd file-watcher
   python -m pytest tests/
   
   # Test Neovim plugin (if you have plenary.nvim)
   nvim --headless -c "PlenaryBustedDirectory nvim-plugin/tests/"
   ```

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **Push and create a pull request:**
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
feat(nvim): add accept/reject keybindings
fix(watcher): resolve file change detection race condition
docs: update installation instructions
```

## 📋 Code Standards

### Python Code (File Watcher)

- **Style**: Follow [PEP 8](https://pep8.org/)
- **Formatting**: Use `black` for code formatting
- **Linting**: Use `flake8` for linting
- **Type hints**: Use type hints where appropriate
- **Docstrings**: Use Google-style docstrings

```python
def process_change(file_path: str, change_type: str) -> bool:
    """Process a file change event.
    
    Args:
        file_path: Path to the changed file
        change_type: Type of change (CREATE, MODIFY, DELETE)
        
    Returns:
        True if change was processed successfully
    """
    pass
```

### Lua Code (Neovim Plugin)

- **Style**: Follow [LuaRocks style guide](https://github.com/luarocks/lua-style-guide)
- **Formatting**: Use consistent indentation (2 spaces)
- **Comments**: Document complex functions
- **Error handling**: Use `pcall` for potentially failing operations

```lua
--- Process file change from watcher
-- @param change table: Change data from watcher
-- @return boolean: Success status
local function process_change(change)
  -- Implementation
end
```

## 🧪 Testing

### Test Categories

1. **Unit Tests**: Test individual functions
2. **Integration Tests**: Test component interactions
3. **End-to-end Tests**: Test complete workflows

### Running Tests

```bash
# All tests
./test_integration.sh

# Python unit tests
cd file-watcher
python -m pytest tests/ -v

# Neovim plugin tests
cd nvim-plugin
nvim --headless -c "PlenaryBustedDirectory tests/"
```

### Writing Tests

**Python Tests:**
```python
# file-watcher/tests/test_diff.py
import pytest
from watcher import DiffCalculator

def test_diff_calculation():
    calc = DiffCalculator()
    old_text = "line 1\nline 2"
    new_text = "line 1\nline 2 modified"
    
    diff = calc.calculate_diff(old_text, new_text)
    assert diff['hunks'][0]['type'] == 'delete'
```

**Lua Tests:**
```lua
-- nvim-plugin/tests/test_config_spec.lua
local config = require('claude-code-nvim.config')

describe('config', function()
  it('should have default values', function()
    local defaults = config.setup({})
    assert.is_true(defaults.auto_start)
  end)
end)
```

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Environment information:**
   - OS and version
   - Neovim version
   - Python version
   - Claude Code CLI version

2. **Steps to reproduce**
3. **Expected vs actual behavior**
4. **Logs/error messages**
5. **Minimal configuration** (if applicable)

Use the bug report template when creating issues.

## 💡 Feature Requests

For feature requests:

1. **Check existing issues** first
2. **Describe the use case** clearly
3. **Explain the expected behavior**
4. **Consider implementation complexity**

Use the feature request template when creating issues.

## 📚 Documentation

### Areas that need documentation:

- API documentation
- Configuration options
- Troubleshooting guides
- Architecture explanations

### Documentation format:

- Use **Markdown** for all documentation
- Include **code examples** where relevant
- Keep explanations **clear and concise**
- Add **screenshots/GIFs** for UI features

## 🤝 Pull Request Process

1. **Ensure tests pass**
2. **Update documentation** if needed
3. **Add changelog entry** (unreleased section)
4. **Request review** from maintainers
5. **Address feedback** promptly

### PR Checklist

- [ ] Code follows project style guidelines
- [ ] Tests pass locally
- [ ] Documentation updated (if applicable)
- [ ] Changelog updated
- [ ] No merge conflicts
- [ ] PR description is clear

## 🏷️ Release Process

Releases follow [Semantic Versioning](https://semver.org/):

- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, backward compatible
- **Patch** (0.0.X): Bug fixes, backward compatible

## 📞 Getting Help

- **Issues**: Create a GitHub issue
- **Discussions**: Use GitHub Discussions for questions
- **Discord**: Join our community Discord (link in README)

## 🙏 Recognition

Contributors will be recognized in:

- **README.md** contributors section
- **CHANGELOG.md** for each release
- **GitHub releases** notes

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to make Claude Code + Neovim integration better for everyone! 🎉