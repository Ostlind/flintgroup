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


# Login to Azure 
Connect-Azure

Write-Information "Successfully logged in to Azure"

# Set variables from config 
$projects = $Configuration.projects

# Start processing/installing the migrations.  
Start-ProcessMigrations -Projects $projects 

Write-Verbose "Fetched configuration..."
