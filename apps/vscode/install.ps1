#!/usr/bin/env pwsh
# VS Code Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$PackageName = "vscode.install"  # Use .install package for custom params
$AppName = "Visual Studio Code"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

# Installation
try {
    # Note: Chocolatey's vscode.install defaults already match our requirements:
    # - Desktop icon: enabled
    # - Context menu (files): enabled
    # - Context menu (folders): enabled
    # - File associations: enabled
    # - Add to PATH: enabled
    # - Don't auto-launch: enabled

    $result = Invoke-ChocoInstall -PackageName $PackageName -Name $AppName -SkipIfInstalled

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

    # Refresh PATH environment variable to pick up newly installed VS Code
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

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

# Post-installation validation
try {
    Write-InstallLog "Validating VS Code installation..." -Level "INFO"

    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        Write-InstallLog "VS Code command is available in PATH: $($codeCmd.Source)" -Level "SUCCESS"

        # Get VS Code version
        try {
            $versionOutput = & code --version 2>&1
            if ($versionOutput) {
                Write-InstallLog "VS Code version: $($versionOutput[0])" -Level "INFO"
            }
        }
        catch {
            Write-InstallLog "Could not retrieve VS Code version" -Level "WARNING"
        }
    }
    else {
        Write-InstallLog "Warning: VS Code command not found in PATH after installation" -Level "WARNING"
        Write-InstallLog "You may need to restart your terminal or system" -Level "INFO"
    }
}
catch {
    Write-InstallLog "Post-installation validation failed: $_" -Level "WARNING"
}

exit 0
