# Создаем временный файл конфигурации
$cfgFile = "$env:TEMP\auditfix.inf"
$dbFile = "$env:TEMP\auditfix.sdb"

# Записываем в него настройку политики
@"
[Unicode]
Unicode=yes
[System Access]
[Event Audit]
[Registry Values]
MACHINE\System\CurrentControlSet\Control\Lsa\SCENoApplyLegacyAuditPolicy=4,1
[Privilege Rights]
[Version]
signature="`$CHICAGO`$"
Revision=1
"@ | Out-File $cfgFile -Encoding unicode

# Применяем конфигурацию к базе безопасности сервера
secedit /configure /db $dbFile /cfg $cfgFile /areas SECURITYPOLICY

# Обновляем политики
gpupdate /force

# Удаляем временные файлы
Remove-Item $cfgFile, $dbFile