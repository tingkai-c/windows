# Windows PC Setup Automation

Automated setup script for quickly configuring new Windows PCs with all your favorite applications and settings.

## Quick Start

On a fresh Windows PC, open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force;
winget install --id Git.Git --exact --silent --accept-package-agreements --accept-source-agreements;
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User");
git clone https://github.com/tingkai-c/windows.git $env:USERPROFILE\setup-repo;
cd $env:USERPROFILE\setup-repo;
.\main-setup.ps1
```

This will:
1. Install Git
2. Clone this repository
3. Run the automated setup

## Repository Structure

```
windows/
├── setup.ps1              # Initial bootstrap script
├── main-setup.ps1         # Main orchestrator script
├── install.log            # Generated installation log
│
├── lib/                   # Shared utilities
│   └── Install-Utils.psm1 # PowerShell module with common functions
│
├── apps/                  # Application installations
│   ├── git/
│   │   ├── install.ps1    # Git installation script
│   │   └── config.inf     # Git configuration
│   │
│   ├── vscode/
│   │   ├── install.ps1    # VS Code installation script
│   │   └── settings.json  # VS Code settings
│   │
│   └── ...                # Add more apps here
│
└── cleanup/               # Bloatware removal
    ├── remove-bloat.ps1   # Removal script
    └── bloatware-list.json # List of apps to remove
```

## How It Works

1. **Bloatware Removal** - Removes unwanted preinstalled Windows apps (runs first)
2. **App Installation** - Automatically discovers and installs all apps in the `apps/` folder
3. **Configuration** - Each app can configure itself post-installation
4. **Summary Report** - Displays results with success/failure counts

## Adding New Apps

To add a new application:

1. Create a new folder in `apps/` with the app name (e.g., `apps/chrome/`)
2. Create an `install.ps1` script in that folder
3. Add any configuration files needed

### App Install Script Template

```powershell
#!/usr/bin/env pwsh
# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

$AppId = "Publisher.AppName"  # Winget package ID
$AppName = "App Display Name"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

try {
    # Basic installation
    $result = Invoke-WingetInstall -Id $AppId -Name $AppName -SkipIfInstalled

    if (-not $result.Success) {
        throw "Installation failed: $($result.Message)"
    }

    Write-InstallLog "$AppName installed successfully" -Level "SUCCESS"
}
catch {
    Write-InstallLog "Failed to install $AppName : $_" -Level "ERROR"
    exit 1
}

# Optional: Post-installation configuration
try {
    # Copy-ConfigFile -Source "$PSScriptRoot\config.json" -Destination "$env:APPDATA\App\config.json" -CreateDirectory
    Write-InstallLog "Post-installation configuration completed" -Level "SUCCESS"
}
catch {
    Write-InstallLog "Post-installation configuration failed: $_" -Level "WARNING"
}

exit 0
```

## Finding Winget Package IDs

To find the package ID for an app:

```powershell
winget search "app name"
```

Example:
```powershell
winget search "Google Chrome"
# Returns: Google.Chrome
```

## Customizing Bloatware Removal

Edit `cleanup/bloatware-list.json` to add apps you want to remove:

```json
{
  "appx_packages": [
    "Microsoft.Xbox.TCUI",
    "Microsoft.BingNews",
    "Microsoft.Getstarted"
  ],
  "capabilities": [
    "Browser.InternetExplorer"
  ]
}
```

Then update `cleanup/remove-bloat.ps1` to implement the removal logic.

## Advanced Usage

### Install a Single App (for testing)

```powershell
.\main-setup.ps1 -SingleApp git
```

### Skip Bloatware Removal

```powershell
.\main-setup.ps1 -SkipBloatwareRemoval
```

### Install Apps Only

```powershell
.\main-setup.ps1 -AppsOnly
```

## Features

- **Modular**: Each app is self-contained in its own folder
- **Scalable**: Add unlimited apps without modifying core scripts
- **Robust**: Continues on errors, displays comprehensive summary
- **Logged**: All operations logged to `install.log`
- **Testable**: Test individual apps with `-SingleApp` parameter

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges
- Internet connection

## Troubleshooting

### Execution Policy Error

If you get an execution policy error, run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### Winget Not Found

On older Windows 10 versions, you may need to install winget manually:
1. Download from [GitHub Releases](https://github.com/microsoft/winget-cli/releases)
2. Or install from Microsoft Store: "App Installer"

### Check Installation Log

View detailed logs:

```powershell
Get-Content install.log
```

## Contributing

To add more apps or improve the setup process, simply:
1. Add new app folders in `apps/`
2. Update bloatware list in `cleanup/`
3. Modify shared utilities in `lib/Install-Utils.psm1` if needed

## License

MIT License - feel free to use and modify as needed.
