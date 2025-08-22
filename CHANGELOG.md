# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup with comprehensive architecture
- File watcher service for monitoring Claude Code changes
- Neovim plugin with real-time synchronization
- Interactive diff preview windows
- Accept/reject mechanism for individual changes
- IPC communication via Unix sockets
- Configuration system with sensible defaults
- Installation script with virtual environment support
- Cross-platform support (Linux, macOS, Windows WSL)
- Comprehensive documentation and examples

### Technical Details
- Python file watcher using `watchdog` library
- Lua-based Neovim plugin with modular architecture
- Diff calculation engine with line-by-line granularity
- Event-driven architecture with <100ms latency
- Secure IPC using Unix domain sockets
- Automatic buffer reloading and cursor position preservation
- Visual change indicators in sign column
- Configurable keybindings and appearance

## [1.0.0] - 2024-XX-XX

### Added
- Initial release
- Core functionality for Claude Code + Neovim integration
- Real-time file change synchronization
- Interactive diff previews
- Change acceptance/rejection workflow
- Installation and setup automation

---

## Release Notes Format

Each release will include:

### 🌟 **New Features**
- Major new functionality
- New commands or capabilities
- UI/UX improvements

### 🐛 **Bug Fixes**
- Resolved issues
- Performance improvements
- Stability enhancements

### ⚠️ **Breaking Changes**
- API changes
- Configuration changes
- Compatibility updates

### 🔧 **Technical Changes**
- Internal refactoring
- Dependency updates
- Architecture improvements

### 📚 **Documentation**
- Updated guides
- New examples
- API documentation

---

## Contributing to Changelog

When contributing, please:
1. Add entries to the `[Unreleased]` section
2. Follow the established format
3. Use clear, descriptive language
4. Reference issue numbers when applicable
5. Group related changes together

Example entry:
```markdown
### Added
- New `auto_accept` configuration option ([#123](https://github.com/jkhas8/claude-code-nvim/issues/123))
- Support for custom diff algorithms ([#124](https://github.com/jkhas8/claude-code-nvim/pull/124))

### Fixed
- Resolved race condition in file change detection ([#125](https://github.com/jkhas8/claude-code-nvim/issues/125))
- Fixed cursor position preservation after buffer reload ([#126](https://github.com/jkhas8/claude-code-nvim/issues/126))
```