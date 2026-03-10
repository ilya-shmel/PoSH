# --- 1. Включение командной строки в событиях создания процессов ---
$regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force }
Set-ItemProperty -Path $regPath -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1 -Type DWord

Write-Host "Настройка командной строки завершена." -ForegroundColor Green

# --- 2. Настройка расширенных политик аудита через auditpol ---

# Функция для удобства
function Set-Audit {
    param($name, $success, $failure)
    $s = if($success) {"enable"} else {"disable"}
    $f = if($failure) {"enable"} else {"disable"}
    # Используем английские названия, так как они универсальны для auditpol
    auditpol /set /subcategory:"$name" /success:$s /failure:$f
}

Write-Host "Применяю политики аудита..." -ForegroundColor Cyan

# Account Logon
Set-Audit "Credential Validation" -success $true -failure $true
Set-Audit "Kerberos Authentication Service" -success $true -failure $true
Set-Audit "Kerberos Service Ticket Operations" -success $true -failure $true
Set-Audit "Other Account Logon Events" -success $true -failure $true

# Account Management
Set-Audit "Application Group Management" -success $true -failure $true
Set-Audit "Computer Account Management" -success $true -failure $true
Set-Audit "Distribution Group Management" -success $true -failure $true
Set-Audit "Other Account Management Events" -success $true -failure $true
Set-Audit "Security Group Management" -success $true -failure $true
Set-Audit "User Account Management" -success $true -failure $true

# Detailed Tracking
Set-Audit "DPAPI Activity" -success $false -failure $false
Set-Audit "Process Creation" -success $true -failure $true
Set-Audit "Process Termination" -success $true -failure $true
Set-Audit "RPC Events" -success $false -failure $false

# DS Access (Доступ к AD)
Set-Audit "Detailed Directory Service Replication" -success $false -failure $false
Set-Audit "Directory Service Access" -success $true -failure $true
Set-Audit "Directory Service Changes" -success $true -failure $true
Set-Audit "Directory Service Replication" -success $false -failure $false

# Logon/Logoff
Set-Audit "Account Lockout" -success $true -failure $true
Set-Audit "IPsec Extended Mode" -success $false -failure $false
Set-Audit "IPsec Main Mode" -success $false -failure $false
Set-Audit "IPsec Quick Mode" -success $false -failure $false
Set-Audit "Logoff" -success $true -failure $false
Set-Audit "Logon" -success $true -failure $true
Set-Audit "Network Policy Server" -success $false -failure $false
Set-Audit "Other Logon/Logoff Events" -success $true -failure $true
Set-Audit "Special Logon" -success $true -failure $true

# Object Access
Set-Audit "Application Generated" -success $false -failure $false
Set-Audit "Detailed File Share" -success $false -failure $false
Set-Audit "File Share" -success $true -failure $true
Set-Audit "File System" -success $true -failure $true
Set-Audit "Filtering Platform Connection" -success $false -failure $false
Set-Audit "Filtering Platform Packet Drop" -success $false -failure $false
Set-Audit "Handle Manipulation" -success $false -failure $false
Set-Audit "Kernel Object" -success $false -failure $false
Set-Audit "Other Object Access Events" -success $false -failure $false
Set-Audit "Registry" -success $true -failure $true
Set-Audit "SAM" -success $false -failure $false

# Policy Change
Set-Audit "Audit Policy Change" -success $true -failure $true
Set-Audit "Authentication Policy Change" -success $true -failure $true
Set-Audit "Authorization Policy Change" -success $true -failure $true
Set-Audit "Filtering Platform Policy Change" -success $false -failure $false
Set-Audit "MPSSVC Rule-Level Policy Change" -success $true -failure $true
Set-Audit "Other Policy Change Events" -success $true -failure $true

# Privilege Use
Set-Audit "Sensitive Privilege Use" -success $true -failure $true
Set-Audit "Non-Sensitive Privilege Use" -success $true -failure $true

# System
Set-Audit "IPsec Driver" -success $false -failure $false
Set-Audit "Other System Events" -success $false -failure $false
Set-Audit "Security State Change" -success $true -failure $true
Set-Audit "Security System Extension" -success $true -failure $true
Set-Audit "System Integrity" -success $true -failure $true

# Принудительное обновление политик
gpupdate /force

Write-Host "Все настройки успешно применены!" -ForegroundColor Green