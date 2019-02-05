#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
$InformationPreference = 'Continue' 
Write-Verbose "Installing modules..."
$root = Split-Path  $PSScriptRoot -Parent

#Import modules. 
#Todo Change this to flintgroup later.
Import-Module "$root" -Global
Import-Module WebAdministration -Global


# Login to Azure 
Connect-Azure

# Load the configuration file.
$configuration = Get-ConfigurationObject -ConfigFilePath "$root\config\config.json"

& '.\update-daemon-script.ps1' -Configuration $configuration.daemon

& '.\update-api-script.ps1' -Configuration $configuration.api

& '.\update-migration-script.ps1' -Configuration $configuration.migration