# Installation

Set-ExecutionPolicy Bypass -Scope Process -Force; 
winget install --id Git.Git --exact --silent --accept-package-agreements --accept-source-agreements; 
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User");
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git $env:USERPROFILE\setup-repo; 
cd $env:USERPROFILE\setup-repo; 
.\main-setup.ps1