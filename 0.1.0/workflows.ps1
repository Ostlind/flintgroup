workflow Start-ProcessDaemons {
    param (

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $Projects,

        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path $_ })]
        [string]
        $ArtifactsFolder
    )

    ForEach -Parallel ($currentProject in $Projects) {
           
        InlineScript {




            import-module flintgroup -verbose

            $project = $using:currentProject

            # Combine the artifact folder with source folder to get the whole path to the zip file.
            $sourceFolder = Join-Path -Path $using:ArtifactsFolder -ChildPath $project.sourceFolderName


            "project name: $($project.name)..."
            "source folder: $($sourceFolder)..."
            "artifacts folder: $($using:ArtifactsFolder)..."

            $service = Stop-Daemon -ServiceName $project.name 
           
            if ($null -eq $service) {

                # if the daemon doesn't exist create it. 
                New-Daemon -Daemon $project;
            }

            $destination = Join-BasePathAndDestination -type daemon -Destination $project.destinationFolderName

            Copy-DaemonFiles -Source $sourceFolder -Destination $destination CopyAppSetting:$project.CopyAppsetting
        
            #Run-Migration -DatabaseName $project.dataBaseName
            # ToDo Change-Appsetting
        
            #Start-Daemon -ServiceName $project.name 
            # The commands run in parallel on each disk.
        
     
            "Processing project: $($project.name)..."

            $error
        }
    }
}
