Set-StrictMode Latest
$ErrorActionPreference = 'SilentlyContinue' 
Write-Verbose "Installing modules..."
import-module flintgroup -Verbose

$configuration = Get-ConfigurationObject -ConfigFilePath './config.json'

if(!configuration)
{
    Write-Error "No configuration found, aborting installation... "
    return;
}

# Login to Azure 
Connect-Azure

Write-Information "Successfully logged in to Azure"


# Set variables from config 
$feed                      = $configuration.daemon.feed
$daemonArtifactsSourcePath = $configuration.daemon.artifactsSourcePath;
$name                      = $configuration.daemon.name
$organisation              = $configuration.daemon.organisation
$version                   = $configuration.daemon.version
$projects                  = $configuration.daemon.projects

# Download artifacts files and place them in $daemonArtifactsSourcePath
Get-Artifact -Feed $feed `
             -ArtifactsSourcePath $daemonArtifactsSourcePath `
             -Name $name `
             -Organisation $organisation `
             -Version $version

Start-ProcessProject -Projects $projects -ArtifactsFolder $daemonArtifactsSourcePath

Write-Verbose "Fetched configuration..."
 
