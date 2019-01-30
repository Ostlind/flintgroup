import-module  '../flintgroup' -Verbose
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

 $Projects | ForEach-Object  {


            $project = $_

            # Combine the artifact folder with source folder to get the whole path to the zip file.
            $sourceFolder = Join-Path -Path $ArtifactsFolder -ChildPath $project.sourceFolderName


            "project name: $($project.name)..."
            "source folder: $($sourceFolder)..."
            "artifacts folder: $($ArtifactsFolder)..."

            $service = $null

            $service = Stop-Daemon -Daemon $project 
           
            if ("Service does not exist" -eq $service) {

                # if the daemon doesn't exist create it. 
                New-Daemon -Daemon $project;
            }

            $destination = Join-BasePathAndDestination -type daemon -Destination $project.destinationFolderName  

            Copy-DaemonFiles -Source $sourceFolder -Destination $destination -CopyAppSetting:$project.CopyAppsetting
        
            #Run-Migration -DatabaseName $project.dataBaseName
            # ToDo Change-Appsetting
        
            #Start-Daemon -ServiceName $project.name 
            # The commands run in parallel on each disk.
        
     
            "Processing project: $($project.name)..."
        }

}
