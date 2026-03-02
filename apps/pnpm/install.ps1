#!/usr/bin/env pwsh
# pnpm Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppId = "pnpm.pnpm"
$AppName = "pnpm"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

# Install pnpm
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

exit 0
