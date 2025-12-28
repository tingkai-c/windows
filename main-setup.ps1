#!/usr/bin/env pwsh
#Requires -RunAsAdministrator
# Main Setup Orchestrator
# Coordinates bloatware removal and application installation

param(
    [switch]$SkipBloatwareRemoval,
    [switch]$AppsOnly,
    [string]$SingleApp = ""  # Install only one app (for testing)
)

# Setup
$ErrorActionPreference = "Continue"  # Don't stop on errors
$RepoRoot = $PSScriptRoot

# Import utilities
Import-Module "$RepoRoot\lib\Install-Utils.psm1" -Force

# Initialize results tracking
$Results = @{
    StartTime = Get-Date
    BloatwareRemoval = $null
    Apps = @()
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Windows Setup Automation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Phase 1: Bloatware Removal
if (-not $SkipBloatwareRemoval -and -not $AppsOnly) {
    Write-InstallLog "Phase 1: Removing bloatware" -Level "INFO"

    $bloatScript = Join-Path $RepoRoot "cleanup\remove-bloat.ps1"
    if (Test-Path $bloatScript) {
        try {
            & $bloatScript
            $Results.BloatwareRemoval = "Success"
        }
        catch {
            Write-InstallLog "Bloatware removal failed: $_" -Level "ERROR"
            $Results.BloatwareRemoval = "Failed"
        }
    }
    else {
        Write-InstallLog "Bloatware removal script not found, skipping" -Level "WARNING"
    }

    Write-Host "`n"
}

# Phase 1.5: Ensure Chocolatey is Installed
Write-InstallLog "Phase 1.5: Checking Chocolatey installation" -Level "INFO"

try {
    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue

    if ($chocoCmd) {
        Write-InstallLog "Chocolatey is already installed" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Installing Chocolatey..." -Level "INFO"

        # Download and execute Chocolatey installation script
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Verify installation
        $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoCmd) {
            Write-InstallLog "Chocolatey installed successfully" -Level "SUCCESS"
        }
        else {
            Write-InstallLog "Chocolatey installation may have failed, continuing anyway..." -Level "WARNING"
        }
    }
}
catch {
    Write-InstallLog "Error during Chocolatey installation: $_" -Level "WARNING"
    Write-InstallLog "Some apps may fail to install without Chocolatey" -Level "WARNING"
}

Write-Host "`n"

# Phase 2: Application Installation
Write-InstallLog "Phase 2: Installing applications" -Level "INFO"

$appsDir = Join-Path $RepoRoot "apps"

# Get all app folders
if ($SingleApp) {
    $appFolders = @(Get-ChildItem -Path $appsDir -Directory | Where-Object Name -eq $SingleApp)
    if ($appFolders.Count -eq 0) {
        Write-InstallLog "App '$SingleApp' not found in apps directory" -Level "ERROR"
    }
}
else {
    $appFolders = Get-ChildItem -Path $appsDir -Directory | Sort-Object Name
}

if ($appFolders.Count -eq 0) {
    Write-InstallLog "No applications found to install" -Level "WARNING"
}

# Install each app
foreach ($appFolder in $appFolders) {
    $installScript = Join-Path $appFolder.FullName "install.ps1"

    if (-not (Test-Path $installScript)) {
        Write-InstallLog "Skipping $($appFolder.Name): no install.ps1 found" -Level "WARNING"
        $Results.Apps += @{Name = $appFolder.Name; Status = "Skipped"; Message = "No install script"}
        continue
    }

    Write-Host "`n--- Installing: $($appFolder.Name) ---" -ForegroundColor Cyan

    try {
        # Execute in app's directory context
        Push-Location $appFolder.FullName
        & $installScript
        $exitCode = $LASTEXITCODE
        Pop-Location

        if ($exitCode -eq 0) {
            $Results.Apps += @{Name = $appFolder.Name; Status = "Success"; Message = "Installed"}
        }
        else {
            $Results.Apps += @{Name = $appFolder.Name; Status = "Failed"; Message = "Exit code: $exitCode"}
        }
    }
    catch {
        Pop-Location
        Write-InstallLog "Error installing $($appFolder.Name): $_" -Level "ERROR"
        $Results.Apps += @{Name = $appFolder.Name; Status = "Failed"; Message = $_.Exception.Message}
    }
}

# Summary Report
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Installation Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($Results.BloatwareRemoval) {
    $bloatColor = if ($Results.BloatwareRemoval -eq "Success") { "Green" } else { "Yellow" }
    Write-Host "Bloatware Removal: $($Results.BloatwareRemoval)" -ForegroundColor $bloatColor
}

$successful = ($Results.Apps | Where-Object Status -eq "Success").Count
$failed = ($Results.Apps | Where-Object Status -eq "Failed").Count
$skipped = ($Results.Apps | Where-Object Status -eq "Skipped").Count

Write-Host "`nApplications:" -ForegroundColor White
Write-Host "  Successful: $successful" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Gray" })
Write-Host "  Skipped: $skipped" -ForegroundColor Yellow

if ($failed -gt 0) {
    Write-Host "`nFailed installations:" -ForegroundColor Red
    $Results.Apps | Where-Object Status -eq "Failed" | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Message)" -ForegroundColor Red
    }
}

$duration = (Get-Date) - $Results.StartTime
Write-Host "`nTotal time: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray

Write-Host "`nLog file: $RepoRoot\install.log" -ForegroundColor Gray
Write-Host "`n========================================`n" -ForegroundColor Cyan
