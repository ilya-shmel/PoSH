$gpoGuid = "6ac1786c-016f-11d2-945f-00c04fb984f9"
$domain = "corp.local"
$user = "CORP\i.shmadchenko"

# Путь к объекту GPO
$path = "LDAP://CN={$gpoGuid},CN=Policies,CN=System,DC=$($domain.Replace('.',',DC='))"
$obj = [ADSI]$path

# Включаем доступ к Security Descriptor
$obj.PsBase.Options.SecurityMasks = [System.DirectoryServices.SecurityMasks]::Dacl -bor [System.DirectoryServices.SecurityMasks]::Owner

# Получаем текущий Security Descriptor
$sec = $obj.PsBase.ObjectSecurity

# Получаем SID пользователя
$userSid = (New-Object System.Security.Principal.NTAccount($user)).Translate([System.Security.Principal.SecurityIdentifier])

# Создаём правило на полный доступ
$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($userSid, "GenericAll", "Allow")

# Добавляем правило
$sec.AddAccessRule($ace)

# Сохраняем изменения
$obj.PsBase.CommitChanges()

Write-Host "✅ Права для $user назначены!" -ForegroundColor Green