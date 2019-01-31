Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue' 
Write-Verbose "Installing modules..."
$root = $PSScriptRoot
#Todo Change this to flintgroup later
import-module "../flintgroup" -Verbose

$configuration = Get-ConfigurationObject -ConfigFilePath "$root/config.json"

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
    -ArtifactsSourcePath $daemonArtifactsSourcePath `
    -Name $name `
    -Organisation $organisation `
    -Version $version

. "$root\start-processdaemon-workflow.ps1"             

Set-PSBreakpoint -Script "$root\start-processdaemon-workflow.ps1" -Line 21 

Start-ProcessApis -Projects $projects -ArtifactsFolder $apiArtifactsSourcePath

Write-Verbose "Fetched configuration..."
 
