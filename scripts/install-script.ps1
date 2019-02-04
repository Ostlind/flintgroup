#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue' 
Write-Verbose "Installing modules..."
$root = Split-Path  $PSScriptRoot -Parent

#Import modules. 
#Todo Change this to flintgroup later.
Import-Module "$root" -Verbose -Global
Import-Module WebAdministration -Verbose -Global

# Load the configuration file.
$configuration = Get-ConfigurationObject -ConfigFilePath "$root/config/config.json"

#& '.\update-daemon-script.ps1' -Configuration $configuration.daemon

& '.\update-api-script.ps1' -Configuration $configuration.api