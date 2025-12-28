# Python Development Setup with uv

This setup installs modern Python development tools optimized for Windows:

- **uv**: Fast, Rust-based Python package and project manager (replaces pip, pipx, pyenv)
- **Python**: Latest stable version, managed by uv
- **IPython**: Enhanced interactive Python REPL

## What's Installed

1. **uv** - Python package manager
   - Installed via winget (`astral-sh.uv`)
   - Automatically added to PATH
   - Manages Python versions and dependencies

2. **Python** - Latest stable release
   - Installed via `uv python install --default`
   - Registered with Windows Registry (PEP 514)
   - Available as `python`, `python3`, and via `py` launcher

3. **IPython** - Enhanced REPL
   - Installed globally via `uv tool install ipython`
   - Syntax highlighting, tab completion, magic commands
   - Run with: `ipython`

## Quick Start

### Create a New Project
```powershell
# Initialize a new Python project
uv init my-project
cd my-project

# Add dependencies
uv add requests pandas

# Run your script
uv run python main.py
```

### Manage Python Versions
```powershell
# List installed versions
uv python list

# Install a specific version
uv python install 3.11

# Use specific version in project
uv python pin 3.11
```

### Work with Virtual Environments
```powershell
# Create virtual environment
uv venv

# Activate it
.venv\Scripts\activate

# Install packages
uv pip install numpy matplotlib
```

### Use IPython REPL
```powershell
# Launch enhanced REPL
ipython

# Or with specific packages temporarily
uvx --with pandas --with numpy ipython
```

## Why uv?

- **10-100x faster** than pip for dependency resolution and installation
- **All-in-one tool**: Replaces pip, pipx, pyenv, virtualenv, poetry
- **Zero Python required**: uv can install Python itself
- **Rust-powered**: Reliable and production-ready
- **Windows-native**: Proper PATH and registry integration

## Troubleshooting

### Python command redirects to Microsoft Store

This issue is automatically fixed by the installation script, which disables the Windows App Execution Aliases for `python.exe` and `python3.exe`.

If you still encounter this issue, you can manually disable the aliases:

1. Open **Settings** > **Apps** > **Apps & Features**
2. Click **App execution aliases** (or search for "App execution aliases")
3. Disable both **python.exe** and **python3.exe**

**Technical Details**: Windows 10/11 includes App Execution Aliases that redirect certain commands to the Microsoft Store. The installation script disables these by modifying registry values at `HKCU:\Software\Microsoft\Windows\CurrentVersion\AppExecutionAliases`.

### Commands not found after installation
Restart your terminal or PowerShell session to refresh PATH.

### Need different Python version
```powershell
uv python install 3.11.9
uv venv --python 3.11.9
```

### IPython not installed
```powershell
uv tool install ipython
```

## Learn More

- [uv Documentation](https://docs.astral.sh/uv/)
- [IPython Documentation](https://ipython.readthedocs.io/)
