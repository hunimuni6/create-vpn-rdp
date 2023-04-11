@cd/d "%~dp0"
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d RemoteSigned /f
powershell.exe -File %cd%/config/form.ps1