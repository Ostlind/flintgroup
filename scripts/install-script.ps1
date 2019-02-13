#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
$InformationPreference = 'Continue' 
Write-Host "Installing modules..." -BackgroundColor Yellow
$root = Split-Path  $PSScriptRoot -Parent

#Import modules. 
#Todo Change this to flintgroup later.
Import-Module "$root" -Global
Import-Module WebAdministration -Global


# Login to Azure 
 $account = Connect-Azure

# Load the configuration file.
$configuration = Get-ConfigurationObject -ConfigFilePath "$root\config\config.json"

&"$root\scripts\update-daemon-script.ps1" -Configuration $configuration.daemon

&"$root\scripts\update-api-script.ps1" -Configuration $configuration.api

&"$root\scripts\update-migration-script.ps1" -Configuration $configuration.migration