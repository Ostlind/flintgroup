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

    $binaryPath = Join-Path -Path $Daemon.destinationFolderName -ChildPath $Daemon.exeName

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


    Expand-Archive $Source -DestinationPath $tempFolderName -Force
    
    if ($CopyAppSetting.IsPresent) {
        

        if (!(Test-Path -Path $Destination)) {
            New-Item -Path $Destination -Force
        }

        Copy-Item "$tempFolderName" -Destination "$Destination\"  -Recurse
    }
    else {
       
        if (!(Test-Path -Path $Destination)) {
            New-Item -Path $Destination -Force -ItemType Directory
        }

        Copy-Item  $tempFolderName\* -Destination "$Destination\" -Exclude "appsettings.json" -Recurse -Force 
        
    }

    Remove-Item -Path $tempFolderName\* -Confirm:$false -Force -Recurse
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

    $configuration = Get-ConfigurationObject -ConfigFilePath '../config/config.json'

    Join-Path -Path $configuration.$type.basePath -ChildPath $Destination

}

function Get-DefaultTypeConfiguration {

    param(
        [ValidateSet("daemon", "api")]
        [PSCustomObject]
        $type

    )

    $configuration = Get-ConfigurationObject -ConfigFilePath './config/config.json'

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

        # Start the database migration to the latest version.

        Start-Migration -DaemonProjectName $project.projectName -DaemonBinPath  $destination


        # ToDo Change-Appsetting

        # Start the daemons again. 
        Start-Daemon -ServiceName $project.name 
        
    }

}

function Start-Migration { 
    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $DaemonNameSpace,
    
        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ })]
        [String]
        $DaemonBinPath
    )

    Push-Location

    Write-Information "Setting location to: '$DaemonBinPath'..."

    Set-Location -Path $DaemonBinPath

    $depsfile = ".\$DaemonNameSpace.deps.json" 
    $runtimeconfig = ".\$DaemonNameSpace.runtimeconfig.json" 
    $ef = '..\artifacts\ef\ef.dll' 
    $assembly = ".\$DaemonNameSpace.dll" 
    ${root-namespace} = "$DaemonNameSpace" 
    $projectDir = '\.'
     
    dotnet exec --depsfile $depsfile --runtimeconfig $runtimeconfig  $ef  database update --assembly $assembly --root-namespace ${root-namespace} --project-dir $projectDir --verbose    

    Pop-Location

    Write-Information "Setting location to: '$((Get-Location).path)'..."
}

Export-ModuleMember -Function Connect-Azure, Get-Artifact, Get-ConfigurationObject, Stop-Daemon, Copy-ProjectFiles, New-Daemon, Join-BasePathAndDestination, Start-ProcessApis, Start-ProcessDaemons, Get-DefaultTypeConfiguration, Start-Migration
