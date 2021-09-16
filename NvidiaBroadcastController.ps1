$MethodDefinition = @'

[DllImport("user32.dll", SetLastError = true)]
public static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

[System.Runtime.InteropServices.DllImport("User32.dll", EntryPoint="ShowWindow")]
public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);

[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr FindWindow(IntPtr sClassName, String sAppName);

'@

$user32 = Add-Type -MemberDefinition $MethodDefinition -Name 'user32' -Namespace 'Win32' -PassThru
$hwnd = $user32::FindWindow([IntPtr]::Zero, 'Nvidia BROADCAST')
$user32::ShowWindow($hwnd, 0)

# https://wiki.winehq.org/List_Of_Windows_Messages
$WM_COMMAND = 0x0111 

# https://docs.microsoft.com/fr-fr/windows/win32/controls/bn-clicked?redirectedfrom=MSDN
# Generate BM_CLICKED using BM_CLICK
# https://docs.microsoft.com/en-us/windows/win32/controls/bm-click
# Button notification control
$BM_CLICK = 0x00F5
$BM_GETCHECK = 0x00F0
$BM_SETCHECK = 0x00F1
# Button control ID
$btn_control_id = 0x806E

function buildWmcommandParams($btn_ctl_id, $notification_control){
	return $(($btn_ctl_id -band 0xFFFF) -bor ($BM_CLICK -shl 16))
}

$WPARAM = buildWmcommandParams $btn_control_id $BM_CLICK

function getDenoisingState(){
	$value = $(Get-ItemProperty -path 'HKCU:\SOFTWARE\NVIDIA Corporation\NVIDIA Broadcast\Settings' -Name 'MicDenoising').MicDenoising
	Write-Host "getDenoisingState $value"
	return $value
}

function isZoomRunning(){
	$value = $(Get-Process | Where-Object { $_.Name -eq "zoom" }).count
	Write-Host "isZoomRunning $value"
	return $value 
}

function isDiscordRunning(){
	$value = $(Get-Process | Where-Object { $_.Name -eq "discord" }).count
	Write-Host "isDiscordRunning $value"
	return $value 
}

function changeDenoisingState(){
	Write-Host "changeDenoisingState"
	if ($hwnd -eq 0){
		Write-Host "cant find process"
	}
	$ret = $user32::PostMessage($hwnd, $WM_COMMAND, $WPARAM, 0);
}

if ($(isDiscordRunning) -or $(isZoomRunning)){
	if (-Not $(getDenoisingState)){
		changeDenoisingState
	}
}
else{
	if ($(getDenoisingState)){
		changeDenoisingState
	}
}
