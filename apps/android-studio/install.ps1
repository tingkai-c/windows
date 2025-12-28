#!/usr/bin/env pwsh
# Android Studio Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppId = "Google.AndroidStudio"
$AppName = "Android Studio"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

# Installation
try {
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

# Post-installation validation
try {
    Write-InstallLog "Validating Android Studio installation..." -Level "INFO"

    $studioPath = "${env:ProgramFiles}\Android\Android Studio\bin\studio64.exe"
    if (Test-Path $studioPath) {
        Write-InstallLog "Android Studio executable found at $studioPath" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: Android Studio executable not found at expected location" -Level "WARNING"
    }
}
catch {
    Write-InstallLog "Post-installation validation failed: $_" -Level "WARNING"
}

exit 0
