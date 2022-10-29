@echo Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force | Clip
Powershell.exe -Command "& {Start-Process Powershell.exe -Verb RunAs}"