$debug = $False

function logging($msg){
    if ($debug){
        Add-Content -Path "@INSTALLPATH@\debug.log" -Value "$([datetime]::Now.ToString('yyyy-mm-dd-HH:mm:ss')) [INFO] $msg"
	}
	Write-host $msg
}

if (Test-Path -Path "@INSTALLPATH@\mutex"){
    logging("script already running, closing")
    exit
}
$script_pid = $(Get-WMIObject -Class Win32_Process -Filter "Name='PowerShell.EXE'" | Where {$_.CommandLine -Like "*NvidiaBroadcastController.ps1"}).ProcessId
Add-Content -Path "@INSTALLPATH@\mutex" -Value "$script_pid"

$MethodDefinition = @'

[DllImport("user32.dll", SetLastError = true)]
public static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

[System.Runtime.InteropServices.DllImport("User32.dll", EntryPoint="ShowWindow")]
public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);

[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr FindWindow(String sClassName, String sAppName);

[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr FindWindowEx(System.IntPtr hWndParent, System.IntPtr hWndChildAfter, String sClassName, String sAppName);

[DllImport("user32.dll", CharSet = CharSet.Auto)]
public static extern IntPtr GetDlgCtrlID(IntPtr hWnd);

'@

$global:DenoiserSoftware = "@DENOISERSOFTWARE@"

$user32 = Add-Type -MemberDefinition $MethodDefinition -Name 'user32' -Namespace 'Win32' -PassThru
# https://wiki.winehq.org/List_Of_Windows_Messages
$WM_COMMAND = 0x0111 

# https://docs.microsoft.com/fr-fr/windows/win32/controls/bn-clicked?redirectedfrom=MSDN
# Generate BM_CLICKED using BM_CLICK
# https://docs.microsoft.com/en-us/windows/win32/controls/bm-click
# Button notification control
$BM_CLICK = 0x00F5
$BM_GETCHECK = 0x00F0
$BM_SETCHECK = 0x00F1
$hwnd = 0


function buildWmcommandParams($btn_ctl_id, $notification_control){
	return $(($btn_ctl_id -band 0xFFFF) -bor ($notification_control -shl 16))
}

if ($DenoiserSoftware -eq "NVBroadcast"){
    $hwnd = $user32::FindWindow("RTXVoiceWindowClass","Nvidia BROADCAST")
	$btn_control_id = 0x806E #btn handler #should change aswell!
	$WPARAM = buildWmcommandParams $btn_control_id $BM_CLICK
}else{
    $hwnd = $user32::FindWindow("RTXVoiceWindowClass","")
	$btn_hwnd = $user32::FindWindowEx($hwnd,0,"Button","Remove background noise from my microphone") #try with btn control id
	$WPARAM = $user32::GetDlgCtrlID($btn_hwnd)
}

if (-Not $Debug){
    $user32::ShowWindow($hwnd, 0)
}

function getDenoisingState(){
    if($global:DenoiserSoftware -eq "NVBroadcast"){
	    $value = $(Get-ItemProperty -path 'HKCU:\SOFTWARE\NVIDIA Corporation\NVIDIA Broadcast\Settings' -Name 'MicDenoising').MicDenoising
	}else{
	    $value = $(Get-ItemProperty -path 'HKCU:\SOFTWARE\NVIDIA Corporation\NVIDIA RTX Voice\Settings' -Name 'MicDenoising').MicDenoising
	}
	logging("getDenoisingState $value")
	return $value
}

function isZoomRunning(){
    logging("isZoomRunning")
	try{
	    return $(Get-Process zoom -ErrorAction Stop | Where-Object {$_.Path -like "*Zoom\bin\Zoom.exe"})
	}catch{
	    return $null
	}
}

function isDiscordRunning(){
    logging("isDiscordRunning")
	try{
		return $(Get-Process discord -ErrorAction Stop | Where-Object {$_.Path -like "*\discord.exe"})
	}catch{
	    return $null
	}
}

function changeDenoisingState($hwnd, $WM_COMMAND, $WPARAM, $LPARAM){
	logging("changeDenoisingState")
	if ($hwnd -eq 0){
		logging("cant find denoising process")
	}
	$ret = $user32::PostMessage($hwnd, $WM_COMMAND, $WPARAM, $LPARAM);
}

$timeout = 60
$retry = 0
if ($(isDiscordRunning) -or $(isZoomRunning)){
	if (-Not $(getDenoisingState)){
	    # then enable
		changeDenoisingState $hwnd $WM_COMMAND $WPARAM $btn_control_id  # Should work with $btn_control_id instead of 0 : TODO CHECK IT WITH NVIDIA BROADCAST
        while ($retry -lt $timeout){
		    if ($(getDenoisingState)){
		    # Might give a look to something like wait-message
			    sleep(1)
			    break
			}else{
		    # Might give a look to something like wait-message
			    sleep(1)
				$timeout += 1
			}
		}
	}
}else{
	if ($(getDenoisingState)){
	    ## then disable
		changeDenoisingState $hwnd $WM_COMMAND $WPARAM 0 
		while ($retry -lt $timeout){
			if (-Not $(getDenoisingState)){
				# Might give a look to something like wait-message
				sleep(1)
				break
			}
			else{
				# Might give a look to something like wait-message
				sleep(1)
				$timeout += 1
			}
		}
	}
}

Remove-Item -Path "@INSTALLPATH@\mutex"
