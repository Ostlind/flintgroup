
Param(
	[string]$token, #Personal access token
    [string]$inPath, #file path in source reposiroty
    [string]$vsProject, #Azure DevOps project name
    [string]$vsAccount, #Azure DevOps account name
    [string]$outPath #path to save file in


)
Add-Type -AssemblyName System.Web

$org = '722610'
$user = 'filip.stojanovski@afconsult.com'
$token =  'kvr43qxoge46brgso7i7dqqvqehavuexsabgffxlrwgmxunoae6q'
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))

$uri = 'https://feeds.dev.azure.com/722610/_apis/packaging/Feeds/ArtifactsFeed/packages/'

$result = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

$result.value[1].versions[0].version



New-Item -ItemType Directory -Force -Path $outPath
$outPath = Join-Path -Path $outPath -ChildPath $inPath.Split("/")[-1]

Out-File -FilePath $outPath -InputObject $result -Encoding ascii



Invoke-RestMethod -Method Get -Uri 'https://feeds.dev.azure.com/722610/_apis/packaging/Feeds/ArtifactsFeed/packages/' -ContentType 'application/json'

$reponse