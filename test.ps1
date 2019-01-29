az login
$extensionName = 'azure-devops'
$extension = az extension list  --query "[?contains( @.name, '$extensionName')]" | ConvertFrom-Json

if (!$extension) {

    Write-Verbose "Installing powershell extension $extensionName..."
    az extension add --name $extensionName;

    Write-Verbose "Done Installing extension..."

}
az extension list

Remove-Module flintgroup -Verbose
Copy-Item "S:\powershell-scripts\flintgroup" -Destination "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules" -Force -Recurse -Container 
Import-Module flintgroup -Verbose

  az artifacts universal download --organization "https://722610.visualstudio.com/"  --feed "ArtifactsFeed" --name "flintgroup-api-artifact" --version "0.1.0" --path './'
  az artifacts universal download --organization "https://722610.visualstudio.com/"  --feed "ArtifactsFeed" --name "flintgroup-daemon-artifact" --version "0.1.0" --path './'
