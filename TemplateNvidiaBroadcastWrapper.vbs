command = "powershell.exe -nologo -windowstyle hidden -ExecutionPolicy bypass -File ""@INSTALLPATH@"""
set shell = CreateObject("WScript.Shell")
shell.Run command,0
