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

            Write-Information "Couldn't find service with name $($Daemon.name)..."
            return "Service does not exist" 
        }

        $service.Stop()

        $service.WaitForStatus('Stopped', '00:00:10') 

    }
    Catch {

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

    Expand-Archive $Source -DestinationPath $tempFolderName -Force
    
    if ($CopyAppSetting) {
        
        Copy-Item -path $tempFolderName -Destination $Destination  -Force -Recurse   
    }
    else {
        
        Copy-Item -path $tempFolderName  -Destination $Destination  -Force -Recurse  -Exclude "appsettings.json"
         
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

    $configuration = Get-ConfigurationObject -ConfigFilePath './config.json'

    Join-Path -Path $configuration.$type.basePath -ChildPath $Destination

}


function Get-DestinationFolder {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Project,

        #The source where the files are copied from  
        [Parameter(Mandatory = $true)]
        [String]
        $basePath

    )

    Join-Path -Path 

}



Export-ModuleMember -Function Connect-Azure, Get-Artifact, Get-ConfigurationObject, Stop-Daemon, Copy-DaemonFiles, New-Daemon, Join-BasePathAndDestination
