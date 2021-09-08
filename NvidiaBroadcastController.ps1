$MethodDefinition = @'

[DllImport("user32.dll", SetLastError = true)]
public static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

[System.Runtime.InteropServices.DllImport("User32.dll", EntryPoint="ShowWindow")]
public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);

[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr FindWindow(IntPtr sClassName, String sAppName);

[DllImport("user32.dll")] 
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

'@

$user32 = Add-Type -MemberDefinition $MethodDefinition -Name 'user32' -Namespace 'Win32' -PassThru
$hwnd = $user32::FindWindow([IntPtr]::Zero, 'Nvidia BROADCAST')

function getDenoisingState(){
	$value = $(Get-ItemProperty -path 'HKCU:\SOFTWARE\NVIDIA Corporation\NVIDIA Broadcast\Settings' -Name 'MicDenoising').MicDenoising
	Write-Host "getDenoisingState $value"
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
	$ret = $user32::PostMessage($hwnd, 0x0111, 16089198, 0);
}

if ($(isDiscordRunning)){
	if (-Not $(getDenoisingState)){
		changeDenoisingState
        $user32::ShowWindow($hwnd, 0)
	}
}
else{
	if ($(getDenoisingState)){
		changeDenoisingState
        $user32::ShowWindow($hwnd, 0)
	}
}