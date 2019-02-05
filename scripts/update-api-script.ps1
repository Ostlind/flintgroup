param(
    # The configuration object
    [Parameter(Mandatory = $true)]
    [PSCustomObject]
    $Configuration
)

# If configuration is null abort script. 
if ( $null -eq $configuration) {
    Write-Error "No configuration found, aborting installation... "
    return;
}



Write-Information "Successfully logged in to Azure"

# Set variables from config 
$feed = $Configuration.feed
$apiArtifactsSourcePath = $Configuration.artifactsSourcePath;
$name = $Configuration.name
$organisation = $Configuration.organisation
$version = $Configuration.version
$projects = $Configuration.projects


# Specify version of package to download
$version = Read-Host -Prompt "Please enter package version (in format 0.0.0)"

while ($version -notmatch '^\d{1}.\d{1}.\d{1}$' ) {

    Write-Error "Version number '($version)' is in the wrong format. Use i.e (1.0.0)..."
    $version = Read-Host -Prompt "Please enter package version (in format 0.0.0)..."
}

# Download artifacts files and place them in $daemonArtifactsSourcePath
Get-Artifact -Feed $feed `
    -ArtifactsSourcePath $apiArtifactsSourcePath `
    -Name $name `
    -Organisation $organisation `
    -Version $version


# Start processing/installing the Apis.  
Start-ProcessApis -Projects $projects -ArtifactsFolder $apiArtifactsSourcePath

Write-Verbose "Fetched configuration..."
 
