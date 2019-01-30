
Remove-Module flintgroup -Verbose -ErrorAction SilentlyContinue
Copy-Item "S:\powershell-scripts\flintgroup" -Destination "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules" -Force -Recurse -Container 
Import-Module flintgroup -Verbose
. '.\start-processdaemon-workflow.ps1'
Start-ProcessDaemons -Projects $configuration.daemon.projects -ArtifactsFolder $configuration.daemon.artifactsSourcePath