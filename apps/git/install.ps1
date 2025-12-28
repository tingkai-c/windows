#!/usr/bin/env pwsh
# Git Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppId = "Git.Git"
$AppName = "Git"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

# Installation
try {
    # Install with custom INF config
    $configFile = Join-Path $PSScriptRoot "config.inf"

    if (Test-Path $configFile) {
        $result = Invoke-WingetInstall -Id $AppId -Name $AppName -Override "/VERYSILENT /LOADINF=`"$configFile`""
    }
    else {
        Write-InstallLog "Config file not found, installing with defaults" -Level "WARNING"
        $result = Invoke-WingetInstall -Id $AppId -Name $AppName
    }

    if (-not $result.Success) {
        throw "Installation failed: $($result.Message)"
    }

    Write-InstallLog "$AppName installed successfully" -Level "SUCCESS"
}
catch {
    Write-InstallLog "Failed to install $AppName : $_" -Level "ERROR"
    exit 1
}

exit 0
