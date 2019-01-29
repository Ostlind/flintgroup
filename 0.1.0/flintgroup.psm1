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


Workflow Stop-Daemon {
    param(
        # Service Name
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Daemon
    )
    InlineScript {

        Try {

            $service = Get-Service -Name $Daemon.name -ErrorAction SilentlyContinue

            if ($null -eq $service) {

                $binaryPath = Join-Path -ChildPath $Daemon.destinationFolderName -ChildPath $Daemon.exeName

                $service =  New-Service -Name $Daemon.name -BinaryPathName $binaryPath  -DisplayName $Daemon.displayName -StartupType Automatic  

            }

            $service.WaitForStatus('Stopped', '00:00:10') 
        }
        Catch {

            Break
        }

    }
}

function Copy-DaemonFiles {

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

    $tempFolderName = 'C:/Temp/filesToCopy'
    Expand-Archive $Source -DestinationPath $tempFolderName
    
    if ($CopyAppSetting) {
        $itemsToCopy = Get-ChildItem -Path $tempFolderName -Recurse 
    }
    else {
         
        $itemsToCopy = Get-ChildItem -Path $tempFolderName -Recurse -Exclude "*appsettings*.json"; 
    }

    $itemsToCopy | Copy-Item -Destination $Destination

}

workflow Start-ProcessProject {
    param (

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $Projects,

        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ })]
        [string]
        $ArtifactsFolder
    )

    ForEach -Parallel ($project in $Projects) {
           
        inlineScript {
        
            $sourceFolder = Join-Path -Path $ArtifactsFolder -ChildPath $project.sourceFolderName

            Stop-Daemon -ServiceName $project.name 
            
            Copy-DaemonFiles -Source $sourceFolder -Destination $project.destinationFolderName CopyAppSetting:$project.CopyAppsetting
        
            Run-Migration -DatabaseName $project.dataBaseName
            # ToDo Change-Appsetting
        
            Start-Daemon -ServiceName $project.name 
            # The commands run in parallel on each disk.
        
     
            "Processing project: $($Using:project.name)..."
        }
    }
    
}


Export-ModuleMember -Function Connect-Azure, Get-Artifact, Get-ConfigurationObject, Stop-Daemon, Start-ProcessProject, Copy-DaemonFiles