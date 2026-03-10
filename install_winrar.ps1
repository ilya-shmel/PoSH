<#
.SYNOPSIS
    Автоматическая фоновая установка WinRAR
.DESCRIPTION
    Скрипт скачивает последнюю версию WinRAR с официального сайта и устанавливает
    в тихом режиме без участия пользователя
.NOTES
    Требует прав администратора
    Версия: 1.0
#>

#Requires -RunAsAdministrator

# === НАСТРОЙКИ ===
$ErrorActionPreference = "Stop"

# URL для скачивания WinRAR (актуальная версия на момент написания)
# Актуальные ссылки всегда можно найти на https://www.win-rar.com/download.html
$winrarUrl = "https://www.win-rar.com/fileadmin/winrar-versions/winrar-x64-701.exe"
$winrarPath = "$env:TEMP\winrar-installer.exe"
$logFile = "$env:TEMP\winrar-install.log"

# === ФУНКЦИЯ ЛОГИРОВАНИЯ ===
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Type] $Message"
    
    # Выводим в консоль
    switch ($Type) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
    
    # Пишем в лог-файл
    Add-Content -Path $logFile -Value $logEntry
}

# === ПРОВЕРКА, УСТАНОВЛЕН ЛИ УЖЕ WINRAR ===
function Test-WinRARInstalled {
    $paths = @(
        "C:\Program Files\WinRAR\WinRAR.exe",
        "C:\Program Files (x86)\WinRAR\WinRAR.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $true
        }
    }
    
    # Также проверяем через реестр
    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($key in $uninstallKeys) {
        $winrar = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | 
                  Where-Object { $_.DisplayName -like "*WinRAR*" }
        if ($winrar) {
            return $true
        }
    }
    
    return $false
}

# === ОСНОВНАЯ ЛОГИКА ===
try {
    Write-Log "=== НАЧАЛО УСТАНОВКИ WINRAR ==="
    
    # Проверяем, не установлен ли уже WinRAR
    if (Test-WinRARInstalled) {
        Write-Log "WinRAR уже установлен. Пропускаем..." "WARNING"
        exit 0
    }
    
    # Скачиваем установщик
    Write-Log "Скачиваю WinRAR с $winrarUrl..."
    
    try {
        Invoke-WebRequest -Uri $winrarUrl -OutFile $winrarPath -UseBasicParsing
        Write-Log "Скачивание завершено" "SUCCESS"
    }
    catch {
        # Если не сработала прямая ссылка, пробуем через официальный сайт
        Write-Log "Не удалось скачать по прямой ссылке, пробую через rarlab.com..." "WARNING"
        
        $rarlabUrl = "https://www.rarlab.com/rar/winrar-x64-701.exe"
        Invoke-WebRequest -Uri $rarlabUrl -OutFile $winrarPath -UseBasicParsing
        Write-Log "Скачивание завершено (rarlab.com)" "SUCCESS"
    }
    
    # Проверяем, скачался ли файл
    if (-not (Test-Path $winrarPath)) {
        throw "Файл установщика не был скачан"
    }
    
    Write-Log "Размер файла: $([math]::Round((Get-Item $winrarPath).Length/1MB, 2)) MB"
    
    # Запускаем тихую установку
    Write-Log "Запускаю тихую установку WinRAR..."
    
    # Ключи установки:
    # /S - тихая установка (silent)
    # /D=путь - указать директорию установки (опционально)
    $process = Start-Process -FilePath $winrarPath -ArgumentList "/S" -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Log "✅ WinRAR успешно установлен!" "SUCCESS"
        
        # Проверяем, появился ли WinRAR
        if (Test-Path "C:\Program Files\WinRAR\WinRAR.exe") {
            Write-Log "WinRAR найден в Program Files" "SUCCESS"
            
            # Добавляем в PATH (опционально)
            $winrarDir = "C:\Program Files\WinRAR"
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            if ($currentPath -notlike "*$winrarDir*") {
                [Environment]::SetEnvironmentVariable("Path", "$currentPath;$winrarDir", "Machine")
                Write-Log "WinRAR добавлен в системный PATH" "SUCCESS"
            }
        }
    }
    else {
        throw "Ошибка установки. Код возврата: $($process.ExitCode)"
    }
    
    # Удаляем установщик
    Remove-Item $winrarPath -Force -ErrorAction SilentlyContinue
    Write-Log "Временные файлы удалены"
    
    Write-Log "=== УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО ===" "SUCCESS"
    exit 0
}
catch {
    Write-Log "❌ КРИТИЧЕСКАЯ ОШИБКА: $_" "ERROR"
    Write-Log "Подробности: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}