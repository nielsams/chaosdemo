powershell.exe -ExecutionPolicy Unrestricted -Command "Install-WindowsFeature -Name Web-Server; Install-WindowsFeature NET-Framework-45-ASPNET; Install-WindowsFeature NET-Framework-45-Core; Install-WindowsFeature Web-Asp-Net45; Get-ChildItem -Path \"C:\\inetpub\\wwwroot\" -File | Remove-Item; Copy-Item -Path \"C:\\AzureData\\CustomData.bin\" -Destination \"C:\\inetpub\\wwwroot\\default.aspx\";"