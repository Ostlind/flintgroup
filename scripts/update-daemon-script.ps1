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
$feed = $configuration.daemon.feed
$daemonArtifactsSourcePath = $configuration.daemon.artifactsSourcePath;
$name = $configuration.daemon.name
$organisation = $configuration.daemon.organisation
$version = $configuration.daemon.version
$projects = $configuration.daemon.projects

#Download artifacts files and place them in $daemonArtifactsSourcePath

Get-Artifact -Feed $feed `
    -ArtifactsSourcePath $daemonArtifactsSourcePath `
    -Name $name `
    -Organisation $organisation `
    -Version $version


# Set-PSBreakpoint -Script "$root\start-processdaemon-workflow.ps1" -Line 21 

Start-ProcessDaemons -Projects $projects -ArtifactsFolder $daemonArtifactsSourcePath

Write-Verbose "Fetched configuration..."
 
