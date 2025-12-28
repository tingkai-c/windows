#!/usr/bin/env pwsh
# Tailscale Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppId = "Tailscale.Tailscale"
$AppName = "Tailscale"

Write-InstallLog "Starting installation of $AppName (all users)" -Level "INFO"

# Installation
try {
    # Check if already installed
    if (Test-AppInstalled -WingetId $AppId) {
        Write-InstallLog "$AppName already installed, skipping" -Level "SUCCESS"
        exit 0
    }

    # Install with specific override parameters for all users
    Write-InstallLog "Installing $AppName for all users with custom parameters" -Level "INFO"

    $overrideParams = "/quiet ALLUSERS=1 TS_INSTALLUPDATES=always TS_ADMINCONSOLE=show"

    $result = Invoke-WingetInstall -Id $AppId -Name $AppName -Override $overrideParams

    if (-not $result.Success) {
        throw "Installation failed: $($result.Message)"
    }

    Write-InstallLog "$AppName installed successfully for all users" -Level "SUCCESS"
}
catch {
    Write-InstallLog "Failed to install $AppName : $_" -Level "ERROR"
    exit 1
}

# Post-installation validation
try {
    Write-InstallLog "Validating Tailscale installation..." -Level "INFO"

    # Check if Tailscale service exists and is running
    $service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue

    if ($service) {
        Write-InstallLog "Tailscale service found. Status: $($service.Status)" -Level "SUCCESS"

        if ($service.Status -ne "Running") {
            Write-InstallLog "Attempting to start Tailscale service..." -Level "INFO"
            try {
                Start-Service -Name "Tailscale"
                Write-InstallLog "Tailscale service started successfully" -Level "SUCCESS"
            }
            catch {
                Write-InstallLog "Failed to start Tailscale service: $_" -Level "WARNING"
            }
        }
    }
    else {
        Write-InstallLog "Warning: Tailscale service not found" -Level "WARNING"
    }

    # Check for Tailscale executable
    $tailscalePath = "${env:ProgramFiles}\Tailscale\tailscale.exe"
    if (Test-Path $tailscalePath) {
        Write-InstallLog "Tailscale executable found at $tailscalePath" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: Tailscale executable not found at expected location" -Level "WARNING"
    }
}
catch {
    Write-InstallLog "Post-installation validation failed: $_" -Level "WARNING"
}

exit 0
