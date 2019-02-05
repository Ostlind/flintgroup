function  Connect-Azure {


    $subscriptionName = 'Microsoft Azure Enterprise'

    $isNotLoggedIn = $null -eq (az account show) 

    if ($isNotLoggedIn) {

        Write-Verbose "Logging in to azure..."

        az login 

        $account = az account list --query "[?contains( @.name, '$subscriptionName')] | [0]" | ConvertFrom-Json

        az account set --subscription $account.name

    }

    Write-Verbose "User  $($account.user.name) is now logged in..." 
        
}

function Get-Artifact {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        [String]
        $ArtifactsSourcePath,

        [Parameter(Mandatory = $true)]
        [String]
        $Feed,

        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Organisation,
        
        [Parameter(Mandatory = $true)]
        [String]
        $Version
    )

    az artifacts universal download --organization $Organisation --feed $Feed --name $Name --version $Version --path $ArtifactsSourcePath

}
function Get-ConfigurationObject {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ })]
        [String]
        $ConfigFilePath
    )

    $tokenObj = Get-Content $ConfigFilePath | ConvertFrom-Json

    return $tokenObj;

}

function WaitUntilServices($searchString, $status) {
    # Get all services where DisplayName matches $searchString and loop through each of them.
    foreach ($service in (Get-Service -DisplayName $searchString)) {
        # Wait for the service to reach the $status or a maximum of 30 seconds
        $service.WaitForStatus($status, '00:00:30')
    }
}

function New-Daemon {

    param(
        # Current daemon passed in
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Daemon
    )

    Write-Information "Couldn't find any daemon with name $($Daemon.name)..."

    $destination = Join-BasePathAndDestination -type daemon -Destination $Daemon.destinationFolderName 

    $binaryPath = Join-Path -Path $destination -ChildPath $Daemon.exePath

    $service = New-Service -Name $Daemon.name -BinaryPathName $binaryPath  -DisplayName $Daemon.displayName -StartupType Automatic  

    Write-Information "Created daemon: $($service.name)..."

    return $service 

}

function Stop-Daemon {
    param(
        # Current Deamon passed in
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Daemon
    )

    Try {

        $service = Get-Service -Name $Daemon.name -ErrorAction SilentlyContinue
            
        if ($null -eq $service) {

            Write-Information "Couldn't stop daemon service with name $($Daemon.name) beacuse it was not found"
            return "Daemon service does not exist" 
        }

        $service.Stop()

        $service.WaitForStatus('Stopped', '00:00:10') 

    }
    Catch {

    }
}

function Copy-ProjectFiles {

    param(
        #The source where the files are copied from  
        [Parameter(Mandatory = $true)]
        [String]
        $Source,
        # The destination where the files are copied to
        [Parameter(Mandatory = $true)]
        [String]
        $Destination,
        #  Should the appsetting file be copied 
        [Parameter(Mandatory = $true)]
        [switch]
        $CopyAppSetting

    )

    $tempFolderName = 'C:\Temp\filesToCopy'

    if(Test-Path -Path $tempFolderName)
    {
        Remove-Item $tempFolderName -Force -Recurse
    }

    Expand-Archive $Source -DestinationPath $tempFolderName -Force 
    
    if ($CopyAppSetting.IsPresent) {
        
        if(!(Test-Path -Path $Destination))
        {
            New-Item -Path $Destination -ItemType Directory
        }

        Remove-Item "$Destination\*" -Force -Confirm:$false -Recurse 
        Copy-Item "$tempFolderName\*" -Destination $Destination  -Recurse -Container
    }
    else {

        if(!(Test-Path -Path $Destination))
        {
            New-Item -Path $Destination -ItemType Directory
        }

        Remove-Item "$Destination\*" -Force -Confirm:$false -Recurse -Exclude "appsettings.json"
        Copy-Item "$tempFolderName\*" -Destination $Destination -Recurse -Container -Exclude "appsettings.json"
    }

    Remove-Item -Path $tempFolderName -Confirm:$false -Force -Recurse
}

function Join-BasePathAndDestination {

    param(
        [ValidateSet("daemon", "api")]
        [string]
        $type,

        # The destination where the files are copied to
        [Parameter(Mandatory = $true)]
        [String]
        $Destination
    )


    $root = Split-Path  $PSScriptRoot -Parent

    $configuration = Get-ConfigurationObject -ConfigFilePath "$root/config/config.json"

    Join-Path -Path $configuration.$type.basePath -ChildPath $Destination

}

function Get-DefaultTypeConfiguration {

    param(
        [ValidateSet("daemon", "api")]
        [PSCustomObject]
        $type
    )

    $configuration = Get-ConfigurationObject -ConfigFilePath "/config/config.json"

    return $configuration.$type
}

function Start-ProcessApis {
    param (

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $Projects,

        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ })]
        [string]
        $ArtifactsFolder
    )

    $Projects | ForEach-Object {

        $project = $_

        # Combine the artifact folder with source folder to get the whole path to the zip file.
        $sourceFolder = Join-Path -Path $ArtifactsFolder -ChildPath $project.sourceFolderName

        Write-Information "project name: $($project.name), source folder: $sourceFolder, artifacts folder: $ArtifactsFolder"

        $destination = Join-BasePathAndDestination -type api -Destination $project.destinationFolderName  

        Copy-ProjectFiles -Source $sourceFolder -Destination $destination -CopyAppSetting:$project.CopyAppsetting

        $webApplication = Get-ApiWebApplication -ApiApplication $project

        if ($webApplication -eq "WebApplication does not exist...") {
  
            $webApplication = New-ApiWebApplication -apiProject $project -SiteName 'Default Web Site'

            Write-Information "Created new web application with name: $($project.name)..."
  
        }
        
        Write-Information "Done processing project: $($project.name)..."
    }

    Write-Information "Finished processing web applications"

}
function Get-ApiWebApplication {

    param(
        # Current Deamon passed in
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $ApiApplication
    )

    $webApplication = Get-WebApplication -Name $ApiApplication.name

    if ($null -eq $webApplication) {
        
        Write-Information "Couldn't find a webapplication with name $($ApiApplication.name)..."
        
        return "WebApplication does not exist..." 
    }

    $webApplication

}
function New-ApiWebApplication { 

    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $apiProject,

        # Default site name
        [Parameter(Mandatory = $false)]
        [string]
        $SiteName 
    )

    $apiApplication = Get-WebApplication -Name $apiProject.name 

    if ($null -ne $apiApplication) {
        Write-Information "Api application already exist..."
        
        return
    }

    $physicalPath = Join-BasePathAndDestination -type api -Destination $project.destinationFolderName  
   
    $webApplication = New-WebApplication -Name $apiProject.Name -Site $SiteName -PhysicalPath $physicalPath -ApplicationPool $apiProject.applicationPool  

    return $webApplication

}

function Start-ProcessDaemons {
    param (

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $Projects,

        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ })]
        [string]
        $ArtifactsFolder
    )

    $Projects | ForEach-Object {

        $project = $_

        # Combine the artifact folder with source folder to get the whole path to the zip file.
        $sourceFolder = Join-Path -Path $ArtifactsFolder -ChildPath $project.sourceFolderName

        Write-Information "project name: $($project.name), source folder: $sourceFolder, artifacts folder: $ArtifactsFolder"

        $service = $null

        # Get the service. 
        $service = Stop-Daemon -Daemon $project 
           
        if ("Daemon service does not exist" -eq $service) {

            # if the daemon doesn't exist create it. 
            $service = New-Daemon -Daemon $project;
        }

        # The folder where daemons files are located.
        $destination = Join-BasePathAndDestination -type daemon -Destination $project.destinationFolderName  

        Copy-ProjectFiles -Source $sourceFolder -Destination $destination -CopyAppSetting:$project.CopyAppsetting

        # Start the daemons again. 
        Start-Daemon -ServiceName $project.name 
        
    }

}

function Start-ProcessMigrations {
    param (

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $Projects
    )

    $Projects | ForEach-Object {

        $project = $_


        # The folder where daemons files are located.
        $destination = Join-Path -Path $project.basePath  -ChildPath $project.destinationFolderName  

        # Start the database migration to the latest version.

        $project.dbContexts | Start-Migration -DaemonNameSpace $project.projectName -DaemonBinPath  $destination
        
    }

}

function Start-Daemon {

    param(
        # Name of daemon/service
        [Parameter(Mandatory = $true)]
        [string]
        $ServiceName
    )

    $service = Get-Service -Name $ServiceName

    if ($null -eq $service) {
        Write-Error "Could not find service with name: $ServiceName..."
    }

    Start-Service -Name $ServiceName 

    Write-Information "Started service $ServiceName...."
}

function Start-Migration { 
    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $DaemonNameSpace,
    
        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ })]
        [string]
        $DaemonBinPath,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $DbContextClassName


    )

    Push-Location

    Write-Information "Setting location to: '$DaemonBinPath'..."

    $root = Split-Path -Path $PSScriptRoot -Parent
    Set-Location -Path $DaemonBinPath

    $depsfile = ".\$DaemonNameSpace.deps.json" 
    $runtimeconfig = ".\$DaemonNameSpace.runtimeconfig.json" 
    $ef = "$root\artifacts\ef\ef.dll" 
    $assembly = ".\$DaemonNameSpace.dll" 
    ${root-namespace} = "$DaemonNameSpace" 
    $projectDir = '\.'

    
    $DbContextClassName | ForEach-Object {
    
        dotnet exec --depsfile $depsfile --runtimeconfig $runtimeconfig  $ef  database update --assembly $assembly --root-namespace ${root-namespace} --project-dir $projectDir --context $_ --verbose    

    }

    Pop-Location

    Write-Information "Setting location to: '$((Get-Location).path)'..."
}

Export-ModuleMember -Function Connect-Azure, Get-Artifact, Get-ConfigurationObject, Stop-Daemon, Copy-ProjectFiles, New-Daemon, Join-BasePathAndDestination, Start-ProcessApis, Start-ProcessDaemons, Get-DefaultTypeConfiguration, Start-Migration, Start-Daemon, Start-ProcessMigrations
