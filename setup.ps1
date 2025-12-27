# 1. Download the Git Config file from your repo to a temp folder
$tempInf = "$env:TEMP\git_setup.inf"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/USER/REPO/main/configs/git_setup.inf" -OutFile $tempInf

# 2. Install Git with your custom options
Write-Host "Installing Git..."
winget install --id Git.Git --exact --override "/VERYSILENT /LOADINF=$tempInf" --accept-package-agreements --accept-source-agreements