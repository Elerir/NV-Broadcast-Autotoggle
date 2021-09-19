command = "powershell.exe -nologo -windowstyle hidden -ExecutionPolicy bypass -File ""@INSTALLPATH@\NvidiaBroadcastController.ps1"""
set shell = CreateObject("WScript.Shell")
shell.Run command,0
