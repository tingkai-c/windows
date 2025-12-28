#!/usr/bin/env pwsh
# Flutter SDK Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppName = "Flutter SDK"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

# Check if Flutter is already installed
function Test-FlutterInstalled {
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) {
        Write-InstallLog "Flutter found in PATH: $($flutterCmd.Source)" -Level "INFO"
        return $true
    }
    return $false
}

# Installation
try {
    # Skip if already installed
    if (Test-FlutterInstalled) {
        Write-InstallLog "$AppName already installed, skipping" -Level "SUCCESS"

        # Verify it's functional
        try {
            $versionOutput = & flutter --version 2>&1
            Write-InstallLog "Flutter version check: $($versionOutput[0])" -Level "INFO"
        }
        catch {
            Write-InstallLog "Flutter is installed but may not be functional: $_" -Level "WARNING"
        }

        exit 0
    }

    # Verify Chocolatey is available
    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $chocoCmd) {
        throw "Chocolatey is not installed. Please run main-setup.ps1 to install Chocolatey first."
    }

    # Install Flutter using Chocolatey
    Write-InstallLog "Installing $AppName via Chocolatey..." -Level "INFO"
    Write-InstallLog "This may take several minutes..." -Level "INFO"

    $args = @(
        "install",
        "flutter",
        "-y",
        "--accept-license"
    )

    $process = Start-Process -FilePath "choco" -ArgumentList $args -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode

    if ($exitCode -eq 0) {
        Write-InstallLog "$AppName installed successfully via Chocolatey" -Level "SUCCESS"
    }
    else {
        throw "Chocolatey installation failed with exit code: $exitCode"
    }
}
catch {
    Write-InstallLog "Failed to install $AppName : $_" -Level "ERROR"
    exit 1
}

# Post-installation validation
try {
    Write-InstallLog "Running Flutter doctor for initial setup..." -Level "INFO"
    Write-InstallLog "This may take a few minutes as Flutter performs first-run initialization..." -Level "INFO"

    # Refresh environment variables to pick up new PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Check if flutter command is now available
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) {
        Write-InstallLog "Flutter command is available in PATH" -Level "SUCCESS"

        # Run flutter doctor with --verbose for detailed output
        $doctorOutput = & flutter doctor -v 2>&1

        # Log the output
        foreach ($line in $doctorOutput) {
            Write-InstallLog "  $line" -Level "INFO"
        }

        Write-InstallLog "Flutter doctor completed. Review output above for any required dependencies" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: Flutter command not found in PATH after installation" -Level "WARNING"
        Write-InstallLog "You may need to restart your terminal or system" -Level "INFO"
    }
}
catch {
    Write-InstallLog "Post-installation validation failed: $_" -Level "WARNING"
    Write-InstallLog "You can manually run 'flutter doctor' after restarting your terminal" -Level "INFO"
}

exit 0
