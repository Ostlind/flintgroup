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


# If configuration is null abort script. 
if ( $null -eq $configuration) {
    Write-Error "No configuration found, aborting installation... "
    return;
}

# Login to Azure 
Connect-Azure

Write-Information "Successfully logged in to Azure"


# Set variables from config 
$feed = $configuration.api.feed
$apiArtifactsSourcePath = $configuration.api.artifactsSourcePath;
$name = $configuration.api.name
$organisation = $configuration.api.organisation
$version = $configuration.api.version
$projects = $configuration.api.projects

# Download artifacts files and place them in $daemonArtifactsSourcePath
Get-Artifact -Feed $feed `
    -ArtifactsSourcePath $apiArtifactsSourcePath `
    -Name $name `
    -Organisation $organisation `
    -Version $version


# Start processing/installing the Apis.  
Start-ProcessApis -Projects $projects -ArtifactsFolder $apiArtifactsSourcePath

Write-Verbose "Fetched configuration..."
 
