"""Version information for claude-code-nvim file watcher."""

__version__ = "1.0.0"
__version_info__ = tuple(int(i) for i in __version__.split("."))

# Compatibility versions
MIN_PYTHON_VERSION = (3, 8)
MIN_NEOVIM_VERSION = "0.8.0"

def check_python_version():
    """Check if Python version meets minimum requirements."""
    import sys
    return sys.version_info >= MIN_PYTHON_VERSION

def get_version_string():
    """Get formatted version string with build info."""
    import platform
    return f"claude-code-nvim v{__version__} (Python {platform.python_version()})"