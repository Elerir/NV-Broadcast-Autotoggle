if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$((Get-Location).Path)`"" -Verb RunAs; exit
}
$InstallPath = $args[0]

$DataFilter = $null

### Discord ###
$user = New-Object System.Security.Principal.NTAccount($env:username) 
$userSID = $user.Translate([System.Security.Principal.SecurityIdentifier])
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
$discordKeyPath = "HKU:\"+$userSID+"_Classes\Discord\DefaultIcon"

$discordIsInstalled = $null
if ($(Test-Path -Path $discordKeyPath)){
    try{
		$DiscordBinaryPath = $($(Get-ItemProperty -path $discordKeyPath).'(default)').split(',')[0].replace('"','')
	    $discordIsInstalled = $True
		$DataFilter += "Data='"+$DiscordBinaryPath+"'"
	}
	catch{
	$discordIsInstalled = $False
    Write-Host "Could not find Discord binary, please post your issue on github if Discord is supposed to be installed"	-ForegroundColor white -BackgroundColor DarkRed
}
}
else{
	$discordIsInstalled = $False
    Write-Host "Could not find Discord registry key, please post your issue on github if Discord is supposed to be installed" -ForegroundColor white -BackgroundColor DarkRed
}

### Zoom ###
$ZoomBinaryPath = $env:AppData+"\Zoom\bin\Zoom.exe"
if ($(Test-Path -Path $ZoomBinaryPath)){
	if ($discordIsInstalled){
		$DataFilter += " or Data='"+$ZoomBinaryPath+"'"
	}
	else{
		$DataFilter += "Data='"+$ZoomBinaryPath+"'"
	}
}
else{
    Write-Host "Could not find Zoom binary, please post your issue on github if Zoom is supposed to be installed" -ForegroundColor white -BackgroundColor DarkRed
}

if ($DataFilter){
	Write-Host "Enabling Process tracking"
	auditpol /set /subcategory:"{0CCE922B-69AE-11D9-BED3-505054503030}" /success:enable /failure:disable
	auditpol /set /subcategory:"{0CCE922C-69AE-11D9-BED3-505054503030}" /success:enable /failure:disable
	Write-Host "Process tracking enabled"
	Write-Host "Preparing Scheduled task with user variables"
	(Get-Content $InstallPath/TemplateAutoToggleNvidiaBroadcast.xml).replace('@INSTALLPATH@', $InstallPath) | Set-Content $InstallPath/AutoToggleNvidiaBroadcast.xml
	(Get-Content $InstallPath/NvidiaBroadcastWrapper.vbs).replace('@INSTALLPATH@', $InstallPath) | Set-Content $InstallPath/NvidiaBroadcastWrapper.vbs
	(Get-Content $InstallPath/AutoToggleNvidiaBroadcast.xml).replace('@DATAFILTER@', $DataFilter) | Set-Content $InstallPath/AutoToggleNvidiaBroadcast.xml

	Write-Host "Creating Scheduled task"
	Register-ScheduledTask -xml (Get-Content $InstallPath'/AutoToggleNvidiaBroadcast.xml' | Out-String) -TaskName "AutoToggleNvidiaBroadcast" -Force
	Write-Host "============================================================================================="
	Write-Host "==================================  Installation complete  =================================="
	Write-Host "============================================================================================="
	Write-Host "Please do not move the scripts or the scheduled task will stop working"
}
pause
