# 1. Load the "Database" of apps
$config = Get-Content ".\apps.json" | ConvertFrom-Json

# 2. Iterate through the apps
foreach ($app in $config.apps) {
    Write-Host "Installing $($app.name)..." -ForegroundColor Cyan
    
    # Check if we need to use a local config file (like for Git)
    $params = $app.parameters
    if ($params -match "LOADINF") {
        # Point to the local file in the /configs folder
        $localInf = Join-Path (Get-Location) "configs\git_setup.inf"
        $params = $params -replace "LOCAL_PATH_HOLDER", $localInf
    }

    $command = "winget install --id $($app.id) --exact --accept-package-agreements --accept-source-agreements $params"
    Invoke-Expression $command
}

# 3. Post-Installation: Copy VS Code Settings
$vcodeSettings = "$env:APPDATA\Code\User\settings.json"
Copy-Item ".\configs\vscode-settings.json" -Destination $vcodeSettings -Force