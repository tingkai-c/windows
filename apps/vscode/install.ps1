#!/usr/bin/env pwsh
# VS Code Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppId = "Microsoft.VisualStudioCode"
$AppName = "Visual Studio Code"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

# Installation
try {
    # Configure installation options via MERGETASKS
    # - !runcode: Don't auto-launch VSCode after installation
    # - desktopicon: Create desktop shortcut
    # - addcontextmenufiles: Add "Open with Code" to file context menu
    # - addcontextmenufolders: Add "Open with Code" to folder context menu
    # - associatewithfiles: Register Code as editor for supported file types
    # - addtopath: Add VSCode to PATH environment variable
    $overrideParams = "/SILENT /MERGETASKS=`"!runcode,desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath`""

    $result = Invoke-WingetInstall -Id $AppId -Name $AppName -SkipIfInstalled -Override $overrideParams

    if (-not $result.Success) {
        throw "Installation failed: $($result.Message)"
    }

    Write-InstallLog "$AppName installed successfully" -Level "SUCCESS"
}
catch {
    Write-InstallLog "Failed to install $AppName : $_" -Level "ERROR"
    exit 1
}

# Post-installation configuration
try {
    Write-InstallLog "Copying VS Code settings..." -Level "INFO"

    $settingsSource = Join-Path $PSScriptRoot "settings.json"
    $settingsDestination = "$env:APPDATA\Code\User\settings.json"

    if (Test-Path $settingsSource) {
        $copied = Copy-ConfigFile -Source $settingsSource -Destination $settingsDestination -CreateDirectory

        if ($copied) {
            Write-InstallLog "VS Code settings configured successfully" -Level "SUCCESS"
        }
        else {
            Write-InstallLog "Failed to copy VS Code settings" -Level "WARNING"
        }
    }
    else {
        Write-InstallLog "No settings.json file found, skipping configuration" -Level "INFO"
    }
}
catch {
    Write-InstallLog "Post-installation configuration failed: $_" -Level "WARNING"
}

exit 0
