param(
    # The configuration object
    [Parameter(Mandatory = $true)]
    [PSCustomObject]
    $Configuration
)

if ( $null -eq $configuration) {
    Write-Error "No configuration found, aborting installation... "
    return;
}

# Set variables from config 
$feed = $Configuration.feed
$daemonArtifactsSourcePath = $Configuration.artifactsSourcePath;
$name = $Configuration.name
$organisation = $Configuration.organisation
$version = $Configuration.version
$projects = $Configuration.projects
$shouldDownload = $Configuration.download
$useLatest = $Configuration.useLatest

if ($useLatest -and $shouldDownload) {

    $version = Get-ArtifactVersion -Feed $feed;

    Write-Host "Downloading artifact: $name, version: $version..."

    Get-Artifact -Feed $feed `
        -ArtifactsSourcePath $daemonArtifactsSourcePath `
        -Name $name `
        -Organisation $organisation `
        -Version $version

}

if ($shouldDownload -and (!useLatest)) {

    # Specify version of package to download
    $version = Read-Host -Prompt "Please enter artifact ($name) version (in format 0.0.0)..."

    while ($version -notmatch '^\d{1,4}.\d{1,4}.\d{1,4}$' ) {

        Write-Error "Version number '($version)' is in the wrong format. Use i.e (0.0.0)..."
        $version = Read-Host -Prompt "Please enter artifact ($name) version (in format 0.0.0)..."
    }

    #Download artifacts files and place them in $daemonArtifactsSourcePath
    Get-Artifact -Feed $feed `
        -ArtifactsSourcePath $daemonArtifactsSourcePath `
        -Name $name `
        -Organisation $organisation `
        -Version $version
}



Start-ProcessDaemons -Projects $projects -ArtifactsFolder $daemonArtifactsSourcePath

$project | ForEach-Object { Start-Daemon -ServiceName $_.name}

Write-Verbose "Fetched configuration..."
 
