Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install azure-cli
choco install dotnetcore-sdk
choco install dotnetcore