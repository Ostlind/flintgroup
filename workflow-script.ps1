
Import-module flintgroup -Verbose

workflow Start-ProcessProject {
    param (
        [PSCustomObject[]]$Projects
    )

    ForEach -Parallel ($project in $Projects)
    {
           
        inlineScript 
        {
        
            Stop-Daemon -ServiceName $project.name 
            Copy-DameonFiles -Source $project.sourceFolderName -Destination $project.destinationFolderName
        
        Run-Migration -DatabaseName $project.dataBaseName
        # ToDo Change-Appsetting
        
        Start-Daemon -ServiceName $project.name 
        # The commands run in parallel on each disk.
        
     
            "Processing project: $($Using:project.name)..."
        }
    }
    
}