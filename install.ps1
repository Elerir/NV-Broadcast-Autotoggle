if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$((Get-Location).Path)`"" -Verb RunAs; exit
}
$InstallPath = $args[0]
$global:DataFilter = $null

$global:XMLQuery = "<QueryList>"
$global:XMLProcessCreation = "*[System[band(Keywords,9007199254740992) and EventID=4688 ]] and "
$global:XMLProcessTermination = "*[System[band(Keywords,9007199254740992) and  EventID=4689]] and "
$global:QueryNumber = 0

# Could be usefull to know if rtx voice or broadcast are installed
$DenoiserSoftware = $null
$InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($obj in $InstalledSoftware){
    if ($obj.GetValue("DisplayName") -ne $null -and $obj.GetValue("DisplayName").contains("RTX Voice")){
	    if ($DenoiserSoftware -eq $null -or $DenoiserSoftware -eq "RTXVoice"){
		    $DenoiserSoftware = "RTXVoice"
		}
		else{
		    $DenoiserSoftware = "Both"
			Write-Host "Both rtx voice and nvbroadcast are installed, please keep only one"
		}
	}
	if ($obj.GetValue("DisplayName") -ne $null -and $obj.GetValue("DisplayName").contains("NVIDIA Broadcast")){
	    if ($DenoiserSoftware -eq $null -or $DenoiserSoftware -eq "NVBroadcast"){
		    $DenoiserSoftware = "NVBroadcast"
		}
		else{
		    $DenoiserSoftware = "Both"
			Write-Host "Both rtx voice and nvbroadcast are installed, please keep only one"
		}
	}
}
if ($DenoiserSoftware -eq $null){
    Write-Host "Neither RTXVoice or NVidia Broadcast was found, please open a github issue if you have one of these softwares"
}

### Discord ###

function isDiscordInstalled(){
	$user = New-Object System.Security.Principal.NTAccount($env:username) 
	$userSID = $user.Translate([System.Security.Principal.SecurityIdentifier])
	New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
	$discordKeyPath = "HKU:\"+$userSID+"_Classes\Discord\DefaultIcon"

	$discordIsInstalled = $null
	if ($(Test-Path -Path $discordKeyPath)){
		try{
			$DiscordBinaryPath = $($(Get-ItemProperty -path $discordKeyPath).'(default)').split(',')[0].replace('"','')
			$discordIsInstalled = $True
			$currentQuery = `
				'<Query Id="'+$global:QueryNumber+'" Path="Security">'+`
					'<Select Path="Security">'+$global:XMLProcessCreation+`
						'*[EventData[Data[@Name="NewProcessName"]="'+$DiscordBinaryPath+'"]]'+`
					'</Select>'+`
				'</Query>'
			$global:QueryNumber += 1
			$currentQuery += `
				'<Query Id="'+$global:QueryNumber+'" Path="Security">'+`
					'<Select Path="Security">'+$global:XMLProcessTermination+`
						'*[EventData[Data[@Name="ProcessName"]="'+$DiscordBinaryPath+'"]]'+`
					'</Select>'+`
				'</Query>'
			$global:QueryNumber += 1
			$global:XMLQuery += $currentQuery
			$global:DataFilter += "Data='"+$DiscordBinaryPath+"'"
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
	return $discordIsInstalled
}

### Zoom ###
function isZoomInstalled(){
$ZoomBinaryPath = $env:AppData+"\Zoom\bin\Zoom.exe"
    $zoomIsInstalled = $null
	if ($(Test-Path -Path $ZoomBinaryPath)){
	    $zoomIsInstalled = $True
		$currentQuery = `
				'<Query Id="'+$global:QueryNumber+'" Path="Security">'+`
					'<Select Path="Security">'+$global:XMLProcessCreation+`
						'*[EventData[Data[@Name="NewProcessName"]="'+$ZoomBinaryPath+'"]]'+`
					'</Select>'+`
				'</Query>'
		$global:QueryNumber += 1
		$currentQuery += `
				'<Query Id="'+$global:QueryNumber+'" Path="Security">'+`
					'<Select Path="Security">'+$global:XMLProcessTermination+`
						'*[EventData[Data[@Name="ProcessName"]="'+$ZoomBinaryPath+'"]]'+`
					'</Select>'+`
				'</Query>'
		$global:QueryNumber += 1
		$global:XMLQuery += $currentQuery

	}
	else{
	    $zoomIsInstalled = $False
		Write-Host "Could not find Zoom binary, please post your issue on github if Zoom is supposed to be installed" -ForegroundColor white -BackgroundColor DarkRed
	}
	return $zoomIsInstalled
}

isDiscordInstalled
isZoomInstalled

write-host $global:XMLQuery
$global:XMLQuery += "</QueryList>"
$global:XMLQuery = $global:XMLQuery.replace("<","&lt;").replace(">","&gt;")
$LenXMLQuery = $global:XMLQuery.length
$LenEmptyXMLQuery = "<QueryList></QueryList>".replace("<","&lt;").replace(">","&gt;").length
if ($LenXMLQuery -gt $LenEmptyXMLQuery -and $DenoiserSoftware -ne $null){
	Write-Host "Enabling Process tracking"
	auditpol /set /subcategory:"{0CCE922B-69AE-11D9-BED3-505054503030}" /success:enable /failure:disable
	auditpol /set /subcategory:"{0CCE922C-69AE-11D9-BED3-505054503030}" /success:enable /failure:disable
	Write-Host "Process tracking enabled"
	Write-Host "Preparing Scheduled task with user variables"
	(Get-Content $InstallPath/TemplateNvidiaBroadcastController.ps1).replace('@DENOISERSOFTWARE@', $DenoiserSoftware) | Set-Content $InstallPath/NvidiaBroadcastController.ps1
	(Get-Content $InstallPath/TemplateAutoToggleNvidiaBroadcast.xml).replace('@INSTALLPATH@', $InstallPath) | Set-Content $InstallPath/AutoToggleNvidiaBroadcast.xml
	(Get-Content $InstallPath/TemplateNvidiaBroadcastWrapper.vbs).replace('@INSTALLPATH@', $InstallPath) | Set-Content $InstallPath/NvidiaBroadcastWrapper.vbs
	(Get-Content $InstallPath/AutoToggleNvidiaBroadcast.xml).replace('@XMLQUERY@', $global:XMLQuery) | Set-Content $InstallPath/AutoToggleNvidiaBroadcast.xml

	Write-Host "Creating Scheduled task"
	Register-ScheduledTask -xml (Get-Content $InstallPath'/AutoToggleNvidiaBroadcast.xml' | Out-String) -TaskName "AutoToggleNvidiaBroadcast" -Force
	Write-Host "============================================================================================="
	Write-Host "==================================  Installation complete  =================================="
	Write-Host "============================================================================================="
	Write-Host "Please do not move the scripts or the scheduled task will stop working"
}
pause
