# valid key names can be ASCII codes:
$key = 13
    
# this is the c# definition of a static Windows API method:
$MethodDefinition = @'
		[DllImport("user32.dll")]
		public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
	
'@

$user32 = Add-Type -MemberDefinition $MethodDefinition -Name "user32" -Namespace 'Win32' -PassThru
    
Write-Host "Press A within the next second!"

$result = $False
while (-Not $result){
    $result = [bool]($user32::GetAsyncKeyState($key) -eq -32767)
}
$a = $user32::GetForegroundWindow()
$WH = get-process | ? { $_.mainwindowhandle -eq $a }

