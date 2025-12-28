#!/usr/bin/env pwsh
# Parsec Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppId = "Parsec.Parsec"
$AppName = "Parsec"

Write-InstallLog "Starting installation of $AppName (all users)" -Level "INFO"

# Installation
try {
    # Check if already installed (system-wide check)
    if (Test-AppInstalled -WingetId $AppId) {
        Write-InstallLog "$AppName already installed, skipping" -Level "SUCCESS"
        exit 0
    }

    # Primary approach: Use --scope machine
    Write-InstallLog "Installing $AppName for all users with --scope machine" -Level "INFO"

    $args = @(
        "install",
        "--id", $AppId,
        "--exact",
        "--scope", "machine",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    $process = Start-Process -FilePath "winget" -ArgumentList $args -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode

    $result = Get-WingetExitCode -ExitCode $exitCode

    if (-not $result.IsSuccess) {
        # Fallback: Try with override flags
        Write-InstallLog "Primary installation failed, trying override approach..." -Level "WARNING"

        $result = Invoke-WingetInstall -Id $AppId -Name $AppName -Override "/silent /shared"

        if (-not $result.Success) {
            throw "Both installation methods failed: $($result.Message)"
        }
    }

    Write-InstallLog "$AppName installed successfully for all users" -Level "SUCCESS"
}
catch {
    Write-InstallLog "Failed to install $AppName : $_" -Level "ERROR"
    exit 1
}

# Post-installation validation
try {
    Write-InstallLog "Validating Parsec installation..." -Level "INFO"

    $parsecPath = "${env:ProgramFiles}\Parsec\parsecd.exe"
    if (Test-Path $parsecPath) {
        Write-InstallLog "Parsec executable found at $parsecPath" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: Parsec executable not found at expected location" -Level "WARNING"
    }
}
catch {
    Write-InstallLog "Post-installation validation failed: $_" -Level "WARNING"
}

exit 0
