#!/usr/bin/env pwsh
# NVM (Node Version Manager) Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppId = "CoreyButler.NVMforWindows"
$AppName = "NVM for Windows"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

# Phase 1: Install NVM
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

# Phase 2: Post-Installation Configuration
try {
    Write-InstallLog "Configuring Node.js environment with NVM..." -Level "INFO"

    # Refresh environment variables to pick up NVM in PATH
    # Note: We need to get NVM_HOME and NVM_SYMLINK env vars that were just set
    $nvmHome = [System.Environment]::GetEnvironmentVariable("NVM_HOME","Machine")
    if (-not $nvmHome) {
        $nvmHome = [System.Environment]::GetEnvironmentVariable("NVM_HOME","User")
    }

    # Expand the PATH with actual values instead of variable placeholders
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path","User")

    # Replace %NVM_HOME% and %NVM_SYMLINK% with actual values
    if ($nvmHome) {
        $nvmSymlink = [System.Environment]::GetEnvironmentVariable("NVM_SYMLINK","User")
        if (-not $nvmSymlink) {
            $nvmSymlink = [System.Environment]::GetEnvironmentVariable("NVM_SYMLINK","Machine")
        }

        $machinePath = $machinePath -replace '%NVM_HOME%', $nvmHome
        $machinePath = $machinePath -replace '%NVM_SYMLINK%', $nvmSymlink
        $userPath = $userPath -replace '%NVM_HOME%', $nvmHome
        $userPath = $userPath -replace '%NVM_SYMLINK%', $nvmSymlink
    }

    $env:Path = $machinePath + ";" + $userPath

    # Try to find NVM executable - check common installation locations
    $nvmPath = $null
    $nvmCmd = Get-Command nvm -ErrorAction SilentlyContinue

    if ($nvmCmd) {
        $nvmPath = $nvmCmd.Source
        Write-InstallLog "NVM is available in PATH: $nvmPath" -Level "SUCCESS"
    }
    else {
        # Try to find NVM using NVM_HOME environment variable or common paths
        $possiblePaths = @()

        if ($nvmHome) {
            $possiblePaths += Join-Path $nvmHome "nvm.exe"
        }

        $possiblePaths += @(
            "$env:LOCALAPPDATA\nvm\nvm.exe",
            "${env:ProgramFiles}\nvm\nvm.exe",
            "${env:ProgramFiles(x86)}\nvm\nvm.exe",
            "$env:APPDATA\nvm\nvm.exe"
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $nvmPath = $path
                Write-InstallLog "Found NVM at: $nvmPath" -Level "SUCCESS"
                break
            }
        }

        if (-not $nvmPath) {
            Write-InstallLog "Error: Could not locate NVM executable" -Level "ERROR"
            Write-InstallLog "NVM_HOME is set to: $nvmHome" -Level "INFO"
            Write-InstallLog "Please restart your terminal and run: nvm install lts && nvm use lts" -Level "INFO"
            exit 1
        }
    }

    # Install latest LTS version of Node.js
    Write-InstallLog "Installing Node.js LTS via NVM (this may take a few minutes)..." -Level "INFO"

    $installArgs = @("install", "lts")
    $process = Start-Process -FilePath $nvmPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode

    if ($exitCode -eq 0) {
        Write-InstallLog "Node.js LTS installed successfully via NVM" -Level "SUCCESS"
    }
    else {
        throw "Node.js installation failed with exit code: $exitCode"
    }

    # Set the LTS version as the active version
    Write-InstallLog "Setting Node.js LTS as the active version..." -Level "INFO"

    $useArgs = @("use", "lts")
    $process = Start-Process -FilePath $nvmPath -ArgumentList $useArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode

    if ($exitCode -eq 0) {
        Write-InstallLog "Node.js LTS set as active version" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: Could not set LTS as active version (exit code: $exitCode)" -Level "WARNING"
        Write-InstallLog "You can manually set it with: nvm use lts" -Level "INFO"
    }
}
catch {
    Write-InstallLog "Configuration failed: $_" -Level "ERROR"
    exit 1
}

# Phase 3: Validation
try {
    Write-InstallLog "Validating Node.js installation..." -Level "INFO"

    # Refresh PATH again to pick up newly installed Node.js
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Verify NVM version
    $nvmVersion = & nvm version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-InstallLog "NVM version: $nvmVersion" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: Could not verify NVM version" -Level "WARNING"
    }

    # List installed Node.js versions
    $nvmList = & nvm list 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-InstallLog "Installed Node.js versions:" -Level "INFO"
        $nvmList | ForEach-Object { Write-InstallLog "  $_" -Level "INFO" }
    }

    # Verify Node.js installation
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if ($nodeCmd) {
        $nodeVersion = & node --version 2>&1
        Write-InstallLog "Node.js available: $nodeVersion at $($nodeCmd.Source)" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: node command not found in PATH" -Level "WARNING"
        Write-InstallLog "You may need to restart your terminal or system" -Level "INFO"
    }

    # Verify npm installation
    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if ($npmCmd) {
        $npmVersion = & npm --version 2>&1
        Write-InstallLog "npm available: v$npmVersion at $($npmCmd.Source)" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: npm command not found in PATH" -Level "WARNING"
        Write-InstallLog "npm should be included with Node.js" -Level "INFO"
    }

    # Display quick start info
    Write-InstallLog "" -Level "INFO"
    Write-InstallLog "=== Node.js Setup Complete ===" -Level "SUCCESS"
    Write-InstallLog "Quick start commands:" -Level "INFO"
    Write-InstallLog "  nvm list                - List installed Node.js versions" -Level "INFO"
    Write-InstallLog "  nvm install <version>   - Install a specific Node.js version" -Level "INFO"
    Write-InstallLog "  nvm use <version>       - Switch to a specific Node.js version" -Level "INFO"
    Write-InstallLog "  node --version          - Check current Node.js version" -Level "INFO"
    Write-InstallLog "  npm --version           - Check npm version" -Level "INFO"
    Write-InstallLog "" -Level "INFO"
    Write-InstallLog "See apps/nvm/README.md for more examples" -Level "INFO"
}
catch {
    Write-InstallLog "Validation failed: $_" -Level "WARNING"
    Write-InstallLog "Node.js may still be functional after restarting your terminal" -Level "INFO"
}

exit 0
