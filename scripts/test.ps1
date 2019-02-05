# az login
# $extensionName = 'azure-devops'
# $extension = az extension list  --query "[?contains( @.name, '$extensionName')]" | ConvertFrom-Json

# if (!$extension) {

#     Write-Verbose "Installing powershell extension $extensionName..."
#     az extension add --name $extensionName;

#     Write-Verbose "Done Installing extension..."

# }

# az extension list

# Remove-Module flintgroup -Verbose
# Copy-Item "S:\powershell-scripts\flintgroup" -Destination "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules" -Force -Recurse -Container 
# Import-Module flintgroup -Verbose

# az artifacts universal download --organization "https://722610.visualstudio.com/"  --feed "ArtifactsFeed" --name "flintgroup-api-artifact" --version "0.7.0" --path './'
# az artifacts universal download --organization "https://722610.visualstudio.com/"  --feed "ArtifactsFeed" --name "flintgroup-daemon-artifact" --version "0.7.0" --path './'


# Set-Location C:\MomServices\executor\bin

# $ef = "C:\Users\A501205\.nuget\packages\microsoft.entityframeworkcore.tools\2.2.1\tools\netcoreapp2.0\any\ef.dll"

# dotnet exec --depsfile '.\Af.Mom.Services.Executor.Daemon.deps.json' --runtimeconfig '.\Af.Mom.Services.Executor.Daemon.runtimeconfig.json' 'C:\Users\A501205\.nuget\packages\microsoft.entityframeworkcore.tools\2.2.1\tools\netcoreapp2.0\any\ef.dll' database update --assembly '.\Af.Mom.Services.Executor.Daemon.dll' --root-namespace 'Af.Mom.Services.Executor.Deamon' --project-dir '\.' --verbose
# dotnet exec 
  
# $depsfile           = '.\Af.Mom.Services.Executor.Daemon.deps.json' 
# $runtimeconfig      = '.\Af.Mom.Services.Executor.Daemon.runtimeconfig.json' 
# $ef                 = 'C:\MomServices\ef.dll' 
# $assembly           = '.\Af.Mom.Services.Executor.Daemon.dll' 
# ${root-namespace}   = 'Af.Mom.Services.Executor.Deamon' 
# $projectDir         = '.\'
 
# dotnet exec --depsfile $depsfile --runtimeconfig $runtimeconfig  $ef  database update --assembly $assembly --root-namespace ${root-namespace} --project-dir $projectDir --verbose


# Start-Migration -DaemonNameSpace 'Af.Mom.Services.Executor.Deamon' -DaemonBinPath  "C:\MomServices\executor\bin"

$config = Get-ConfigurationObject -ConfigFilePath '..\config\config.json'

# $daemon = $config.migration.projects[0]
# $daemon.dbContexts | Start-Migration -DaemonBinPath  $(Join-Path $daemon.basePath -ChildPath $daemon.destinationFolderName) -DaemonNameSpace $daemon.projectName



$project  = $config.daemon.projects[0]

$sourceFolder = Join-Path -Path "C:\MomServices\artifacts\drop" -ChildPath $project.sourceFolderName
$destination = Join-BasePathAndDestination -type daemon -Destination $project.destinationFolderName  

Copy-ProjectFiles -Source $sourceFolder -Destination $destination -CopyAppSetting:$project.CopyAppsetting