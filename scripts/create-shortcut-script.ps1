$root = Split-Path -Path $PSScriptRoot 
#$TargetFile = "$root\scripts\install-script.ps1"

$exe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$parameters  =  '-noexit -noprofile  -command  ""&  "S:\powershell-scripts\flintgroup\scripts\install-script.ps1"'

$TargetFile = $exe + $parameters
$ShortcutFile = "$env:Public\Desktop\installscript.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.WorkingDirectory = $root
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
