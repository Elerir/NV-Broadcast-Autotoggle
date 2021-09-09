if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$((Get-Location).Path)`" `"$([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData))`"" -Verb RunAs; exit
}
$InstallPath = $args[0]
$LocalAppData = $args[1]
$user = New-Object System.Security.Principal.NTAccount($env:username) 
$userSID = $user.Translate([System.Security.Principal.SecurityIdentifier])
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
$discordKeyPath = "HKU:\"+$userSID+"_Classes\Discord\DefaultIcon"
$DiscordBinaryPath = $($(Get-ItemProperty -path $discordKeyPath).'(default)').split(',')[0].replace('"','')
Write-Host "Enabling Process tracking"
auditpol /set /subcategory:"{0CCE922B-69AE-11D9-BED3-505054503030}" /success:enable /failure:disable
auditpol /set /subcategory:"{0CCE922C-69AE-11D9-BED3-505054503030}" /success:enable /failure:disable
Write-Host "Process tracking enabled"
Write-Host "Preparing Scheduled task with user variables"
(Get-Content $InstallPath/AutoToggleNvidiaBroadcast.xml).replace('@LOCALAPPDATADISCORD@', $LocalAppData) | Set-Content $InstallPath/AutoToggleNvidiaBroadcast.xml
(Get-Content $InstallPath/AutoToggleNvidiaBroadcast.xml).replace('@INSTALLPATH@', $InstallPath) | Set-Content $InstallPath/AutoToggleNvidiaBroadcast.xml
(Get-Content $InstallPath/NvidiaBroadcastWrapper.vbs).replace('@INSTALLPATH@', $InstallPath) | Set-Content $InstallPath/NvidiaBroadcastWrapper.vbs
(Get-Content $InstallPath/AutoToggleNvidiaBroadcast.xml).replace('@DISCORDBINARYPATH@', $DiscordBinaryPath) | Set-Content $InstallPath/AutoToggleNvidiaBroadcast.xml

Write-Host "Creating Scheduled task"
Register-ScheduledTask -xml (Get-Content $InstallPath'/AutoToggleNvidiaBroadcast.xml' | Out-String) -TaskName "AutoToggleNvidiaBroadcast" -Force
Write-Host "============================================================================================="
Write-Host "==================================  Installation complete  =================================="
Write-Host "============================================================================================="
Write-Host "Please do not move the scripts or the scheduled task will stop working"
pause
