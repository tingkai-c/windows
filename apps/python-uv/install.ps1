#!/usr/bin/env pwsh
# Python (uv) Installation Script

# Import shared utilities
$UtilsPath = Join-Path $PSScriptRoot "..\..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

# Configuration
$AppId = "astral-sh.uv"
$AppName = "uv (Python Package Manager)"

Write-InstallLog "Starting installation of $AppName" -Level "INFO"

# Phase 1: Install uv
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

# Phase 2: Configure Python environment
try {
    Write-InstallLog "Configuring Python environment with uv..." -Level "INFO"

    # Refresh environment variables to pick up uv in PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Disable Windows App Execution Aliases that redirect python to Microsoft Store
    Write-InstallLog "Disabling Windows App Execution Aliases for Python..." -Level "INFO"
    try {
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppExecutionAliases"
        $aliasNames = @("python.exe", "python3.exe")

        # Check if registry path exists
        if (Test-Path $registryPath) {
            foreach ($aliasName in $aliasNames) {
                try {
                    # Check if the alias exists
                    $existingValue = Get-ItemProperty -Path $registryPath -Name $aliasName -ErrorAction SilentlyContinue

                    if ($null -eq $existingValue) {
                        Write-InstallLog "Alias '$aliasName' not found in registry (may already be removed)" -Level "INFO"
                        continue
                    }

                    $currentValue = $existingValue.$aliasName

                    # Check if already disabled (value = 0)
                    if ($currentValue -eq 0) {
                        Write-InstallLog "Alias '$aliasName' is already disabled" -Level "INFO"
                        continue
                    }

                    # Disable the alias by setting to 0
                    Set-ItemProperty -Path $registryPath -Name $aliasName -Value 0 -Type DWord -ErrorAction Stop
                    Write-InstallLog "Disabled App Execution Alias: $aliasName" -Level "SUCCESS"
                }
                catch {
                    Write-InstallLog "Warning: Could not disable alias '$aliasName': $_" -Level "WARNING"
                }
            }
        }
        else {
            Write-InstallLog "App Execution Aliases registry key not found (may not exist on this Windows version)" -Level "WARNING"
        }
    }
    catch {
        Write-InstallLog "Warning: Failed to disable App Execution Aliases: $_" -Level "WARNING"
        Write-InstallLog "You can manually disable them in: Settings > Apps > App execution aliases" -Level "INFO"
    }

    # Check if uv is now available
    $uvCmd = Get-Command uv -ErrorAction SilentlyContinue
    if (-not $uvCmd) {
        Write-InstallLog "Warning: uv command not found in PATH after installation" -Level "WARNING"
        Write-InstallLog "You may need to restart your terminal" -Level "INFO"
        exit 1
    }

    Write-InstallLog "uv is available in PATH: $($uvCmd.Source)" -Level "SUCCESS"

    # Install Python using uv (latest stable version with default flag)
    Write-InstallLog "Installing Python via uv (this may take a few minutes)..." -Level "INFO"

    $installArgs = @("python", "install", "--default")
    $process = Start-Process -FilePath "uv" -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode

    if ($exitCode -eq 0) {
        Write-InstallLog "Python installed successfully via uv" -Level "SUCCESS"
    }
    else {
        throw "Python installation failed with exit code: $exitCode"
    }

    # Install IPython globally using uv tool
    Write-InstallLog "Installing IPython (enhanced REPL) globally..." -Level "INFO"

    $ipythonArgs = @("tool", "install", "ipython")
    $process = Start-Process -FilePath "uv" -ArgumentList $ipythonArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode

    if ($exitCode -eq 0) {
        Write-InstallLog "IPython installed successfully" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "IPython installation failed with exit code: $exitCode" -Level "WARNING"
        Write-InstallLog "You can install it manually later with: uv tool install ipython" -Level "INFO"
    }
}
catch {
    Write-InstallLog "Configuration failed: $_" -Level "ERROR"
    exit 1
}

# Phase 3: Validation
try {
    Write-InstallLog "Validating Python installation..." -Level "INFO"

    # Refresh PATH again to pick up newly installed Python
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Verify uv version
    $uvVersion = & uv --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-InstallLog "uv version: $uvVersion" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: Could not verify uv version" -Level "WARNING"
    }

    # Verify Python installation
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        $pythonVersion = & python --version 2>&1
        Write-InstallLog "Python available: $pythonVersion at $($pythonCmd.Source)" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "Warning: python command not found in PATH" -Level "WARNING"
        Write-InstallLog "You may need to restart your terminal or system" -Level "INFO"
    }

    # Verify IPython installation
    $ipythonCmd = Get-Command ipython -ErrorAction SilentlyContinue
    if ($ipythonCmd) {
        Write-InstallLog "IPython available at $($ipythonCmd.Source)" -Level "SUCCESS"
    }
    else {
        Write-InstallLog "IPython not available in PATH (can be installed later)" -Level "INFO"
    }

    # Display quick start info
    Write-InstallLog "" -Level "INFO"
    Write-InstallLog "=== Python Setup Complete ===" -Level "SUCCESS"
    Write-InstallLog "Quick start commands:" -Level "INFO"
    Write-InstallLog "  uv python list          - List installed Python versions" -Level "INFO"
    Write-InstallLog "  uv init my-project      - Create a new Python project" -Level "INFO"
    Write-InstallLog "  uv run python script.py - Run Python script" -Level "INFO"
    Write-InstallLog "  ipython                 - Launch enhanced REPL" -Level "INFO"
    Write-InstallLog "" -Level "INFO"
    Write-InstallLog "See apps/python-uv/README.md for more examples" -Level "INFO"
}
catch {
    Write-InstallLog "Validation failed: $_" -Level "WARNING"
    Write-InstallLog "Python may still be functional after restarting your terminal" -Level "INFO"
}

exit 0
