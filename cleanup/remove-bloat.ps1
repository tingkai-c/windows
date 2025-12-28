#!/usr/bin/env pwsh
# Windows Bloatware Removal Script
# Placeholder - add your bloatware removal logic here

$UtilsPath = Join-Path $PSScriptRoot "..\lib\Install-Utils.psm1"
Import-Module $UtilsPath -Force

Write-InstallLog "Bloatware removal placeholder - no items configured yet" -Level "INFO"

# TODO: Add bloatware removal logic
# Load bloatware-list.json and remove specified packages
