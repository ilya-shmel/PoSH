$SecurePassword = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force

New-ADUser -Name "maxim" `
           -SamAccountName "maxim" `
           -UserPrincipalName "maxim@corp.local" `
           -AccountPassword $SecurePassword `
           -PasswordNeverExpires $true `
           -Enabled $true `
           -ChangePasswordAtLogon $false

Add-LocalGroupMember -Group "Administrators" -Member "maxim"