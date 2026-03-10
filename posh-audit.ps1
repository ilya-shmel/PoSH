# 1. Настройка Script Block Logging (Event ID 4104)
# Записывает содержимое скриптов, даже если они обфусцированы.
$SBLPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
if (-not (Test-Path $SBLPath)) { New-Item -Path $SBLPath -Force }
Set-ItemProperty -Path $SBLPath -Name "EnableScriptBlockLogging" -Value 1 -Type DWord
Set-ItemProperty -Path $SBLPath -Name "EnableScriptBlockInvocationLogging" -Value 1 -Type DWord

# 2. Настройка Module Logging (Event ID 4103)
# Записывает выполнение конкретных модулей и команд.
$MLPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
if (-not (Test-Path $MLPath)) { New-Item -Path $MLPath -Force }
Set-ItemProperty -Path $MLPath -Name "EnableModuleLogging" -Value 1 -Type DWord

# Указываем, какие модули логировать (* означает ВСЕ)
$MLNamesPath = "$MLPath\ModuleNames"
if (-not (Test-Path $MLNamesPath)) { New-Item -Path $MLNamesPath -Force }
New-ItemProperty -Path $MLNamesPath -Name "*" -Value "*" -PropertyType String -Force

# 3. Увеличение размера журнала (опционально, но рекомендуется)
# Логи PowerShell очень шумные, стандартного размера может не хватить.
wevtutil sl Microsoft-Windows-PowerShell/Operational /ms:104857600 # Устанавливает 100 МБ

Write-Host "Аудит PowerShell (4103, 4104) успешно включен!" -ForegroundColor Green