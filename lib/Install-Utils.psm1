#!/usr/bin/env pwsh
# Install-Utils.psm1
# Shared utility functions for Windows setup automation

# Get the repository root directory
$script:RepoRoot = Split-Path -Parent $PSScriptRoot
$script:LogFile = Join-Path $RepoRoot "install.log"

function Write-InstallLog {
    <#
    .SYNOPSIS
        Writes a log message with timestamp and color coding

    .PARAMETER Message
        The message to log

    .PARAMETER Level
        The log level (INFO, SUCCESS, WARNING, ERROR)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Choose color based on level
    $color = switch ($Level) {
        "INFO"    { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }

    # Write to console with color
    Write-Host $logMessage -ForegroundColor $color

    # Append to log file
    try {
        Add-Content -Path $script:LogFile -Value $logMessage -ErrorAction SilentlyContinue
    }
    catch {
        # Silently continue if log file write fails
    }
}

function Invoke-WingetInstall {
    <#
    .SYNOPSIS
        Installs an application using winget with error handling

    .PARAMETER Id
        The winget package ID (e.g., "Git.Git")

    .PARAMETER Name
        Display name for logging

    .PARAMETER Override
        Optional override parameters (e.g., "/VERYSILENT /LOADINF=...")

    .PARAMETER SkipIfInstalled
        Check if already installed and skip if so

    .RETURNS
        A hashtable with Success (bool) and Message (string)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Id,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [string]$Override = "",

        [Parameter(Mandatory=$false)]
        [switch]$SkipIfInstalled
    )

    # Check if already installed
    if ($SkipIfInstalled) {
        if (Test-AppInstalled -WingetId $Id) {
            return @{
                Success = $true
                Message = "Already installed, skipping"
            }
        }
    }

    # Build winget command
    $args = @(
        "install",
        "--id", $Id,
        "--exact",
        "--source", "winget",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    if ($Override) {
        $args += "--override"
        $args += $Override
    }

    # Execute winget
    Write-InstallLog "Installing $Name (ID: $Id)..." -Level "INFO"

    try {
        $process = Start-Process -FilePath "winget" -ArgumentList $args -Wait -PassThru -NoNewWindow
        $exitCode = $process.ExitCode

        # Interpret exit code
        $result = Get-WingetExitCode -ExitCode $exitCode

        if ($result.IsSuccess) {
            Write-InstallLog "$Name installed successfully" -Level "SUCCESS"
            return @{
                Success = $true
                Message = $result.Message
            }
        }
        else {
            Write-InstallLog "$Name installation failed: $($result.Message)" -Level "ERROR"
            return @{
                Success = $false
                Message = $result.Message
            }
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-InstallLog "Error installing $Name : $errorMsg" -Level "ERROR"
        return @{
            Success = $false
            Message = $errorMsg
        }
    }
}

function Copy-ConfigFile {
    <#
    .SYNOPSIS
        Copies a configuration file to a destination

    .PARAMETER Source
        Source file path

    .PARAMETER Destination
        Destination file path

    .PARAMETER CreateDirectory
        Create parent directory if it doesn't exist

    .RETURNS
        Boolean indicating success
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Source,

        [Parameter(Mandatory=$true)]
        [string]$Destination,

        [Parameter(Mandatory=$false)]
        [switch]$CreateDirectory
    )

    # Check if source exists
    if (-not (Test-Path $Source)) {
        Write-InstallLog "Source file not found: $Source" -Level "ERROR"
        return $false
    }

    # Create parent directory if requested
    if ($CreateDirectory) {
        $parentDir = Split-Path -Parent $Destination
        if (-not (Test-Path $parentDir)) {
            try {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                Write-InstallLog "Created directory: $parentDir" -Level "INFO"
            }
            catch {
                Write-InstallLog "Failed to create directory: $parentDir" -Level "ERROR"
                return $false
            }
        }
    }

    # Copy file
    try {
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-InstallLog "Copied config: $(Split-Path -Leaf $Source) -> $Destination" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-InstallLog "Failed to copy file: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Test-AppInstalled {
    <#
    .SYNOPSIS
        Checks if an application is installed via winget

    .PARAMETER WingetId
        The winget package ID to check

    .RETURNS
        Boolean indicating if app is installed
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$WingetId
    )

    try {
        $output = winget list --id $WingetId --exact 2>&1
        $outputString = $output | Out-String

        # If the package ID appears in the output, it's installed
        if ($outputString -match [regex]::Escape($WingetId)) {
            return $true
        }

        return $false
    }
    catch {
        # If command fails, assume not installed
        return $false
    }
}

function Get-WingetExitCode {
    <#
    .SYNOPSIS
        Interprets winget exit codes

    .PARAMETER ExitCode
        The exit code from winget

    .RETURNS
        Hashtable with IsSuccess (bool) and Message (string)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$ExitCode
    )

    switch ($ExitCode) {
        0 {
            return @{
                IsSuccess = $true
                Message = "Installation completed successfully"
            }
        }
        -1978335189 {
            # 0x8A15000B - No applicable update found / already installed
            return @{
                IsSuccess = $true
                Message = "Already installed or no update needed"
            }
        }
        -1978335153 {
            # 0x8A15002F - Package not found
            return @{
                IsSuccess = $false
                Message = "Package not found in winget repository"
            }
        }
        default {
            return @{
                IsSuccess = $false
                Message = "Installation failed with exit code: $ExitCode"
            }
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Write-InstallLog',
    'Invoke-WingetInstall',
    'Copy-ConfigFile',
    'Test-AppInstalled',
    'Get-WingetExitCode'
)
