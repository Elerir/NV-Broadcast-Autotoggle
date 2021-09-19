command = "powershell.exe -nologo -windowstyle hidden -ExecutionPolicy bypass -File ""D:\git-repo\NV-Broadcast-Autotoggle\NvidiaBroadcastController.ps1"""
set shell = CreateObject("WScript.Shell")
shell.Run command,0
