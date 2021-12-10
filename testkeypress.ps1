# valid key names can be ASCII codes:
$key = 65
    
# this is the c# definition of a static Windows API method:
$MethodDefinition = @'
		[DllImport("user32.dll")]
		public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
	
'@

$user32 = Add-Type -MemberDefinition $MethodDefinition -Name "user32" -Namespace 'Win32' -PassThru

$list = @()
$aPressed = $False
while ($Finished -eq $null -or $Finished.tolower() -ne "y" ){
	Write-Host "go to a window and press 'a'"
	while (-Not $aPressed){
		$aPressed = [bool]($user32::GetAsyncKeyState($key) -eq -32767)
	}
	$a = $user32::GetForegroundWindow()
	$WH = get-process | ? { $_.mainwindowhandle -eq $a }
	if (-Not $list.contains($WH.path)){
		Write-Host $WH.path
		$list += $WH.path
	}
	sleep(1)
	$Finished = Read-Host "Did you finish ? (y/n)"
}

Write-Host $list
Write-Host $list.count