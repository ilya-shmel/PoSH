<#
.SYNOPSIS
    Демонстрация явного вызова методов COM-объектов через InvokeMember в PowerShell
.DESCRIPTION
    Скрипт показывает, как работать с COM-объектами без использования прямого синтаксиса
    PowerShell, а через низкоуровневый вызов методов интерфейса.
.NOTES
    Автор: Caldera Security Researcher
    Требует: PowerShell 5.1 или выше, права администратора для некоторых операций
#>

#Requires -Version 5.0

# Вспомогательная функция для вызова методов COM
function Invoke-COMMethod {
    <#
    .SYNOPSIS
        Вызывает метод COM-объекта через InvokeMember
    .PARAMETER ComObject
        Объект типа __ComObject
    .PARAMETER MethodName
        Имя вызываемого метода
    .PARAMETER Arguments
        Массив аргументов метода (опционально)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.__ComObject]$ComObject,
        
        [Parameter(Mandatory=$true)]
        [string]$MethodName,
        
        [Parameter(Mandatory=$false)]
        [array]$Arguments = $null
    )
    
    try {
        $result = [System.__ComObject].InvokeMember(
            $MethodName,
            [System.Reflection.BindingFlags]::InvokeMethod,
            $null,
            $ComObject,
            $Arguments
        )
        Write-Host "✅ Метод '$MethodName' вызван успешно" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "❌ Ошибка при вызове метода '$MethodName': $_"
        return $null
    }
}

# Вспомогательная функция для получения свойства COM
function Get-COMProperty {
    <#
    .SYNOPSIS
        Получает значение свойства COM-объекта
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.__ComObject]$ComObject,
        
        [Parameter(Mandatory=$true)]
        [string]$PropertyName
    )
    
    try {
        $value = [System.__ComObject].InvokeMember(
            $PropertyName,
            [System.Reflection.BindingFlags]::GetProperty,
            $null,
            $ComObject,
            $null
        )
        Write-Host "📦 Свойство '$PropertyName' получено" -ForegroundColor Cyan
        return $value
    }
    catch {
        Write-Error "❌ Ошибка при получении свойства '$PropertyName': $_"
        return $null
    }
}

# Вспомогательная функция для установки свойства COM
function Set-COMProperty {
    <#
    .SYNOPSIS
        Устанавливает значение свойства COM-объекта
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.__ComObject]$ComObject,
        
        [Parameter(Mandatory=$true)]
        [string]$PropertyName,
        
        [Parameter(Mandatory=$true)]
        [object]$Value
    )
    
    try {
        [System.__ComObject].InvokeMember(
            $PropertyName,
            [System.Reflection.BindingFlags]::SetProperty,
            $null,
            $ComObject,
            @($Value)  # ВАЖНО: значение в массиве!
        )
        Write-Host "⚙️ Свойство '$PropertyName' установлено в '$Value'" -ForegroundColor Yellow
    }
    catch {
        Write-Error "❌ Ошибка при установке свойства '$PropertyName': $_"
    }
}

# ============================================================================
# ПРИМЕР 1: Работа с Shell.Application
# ============================================================================
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "ПРИМЕР 1: Shell.Application (управление окнами)" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta

try {
    # Создаем COM-объект Shell.Application
    $shell = New-Object -ComObject "Shell.Application"
    Write-Host "✅ Shell.Application создан" -ForegroundColor Green
    
    # Получаем все открытые окна
    $windows = Get-COMProperty -ComObject $shell -PropertyName "Windows"
    Write-Host "📊 Открыто окон: $($windows.Count)" -ForegroundColor Cyan
    
    # Вызываем метод ToggleDesktop (свернуть все окна)
    Write-Host "🪟 Сворачиваем все окна..." -ForegroundColor Yellow
    Invoke-COMMethod -ComObject $shell -MethodName "ToggleDesktop"
    Start-Sleep -Seconds 2
    
    # Возвращаем окна обратно
    Write-Host "🪟 Разворачиваем окна..." -ForegroundColor Yellow
    Invoke-COMMethod -ComObject $shell -MethodName "ToggleDesktop"
    
    # Открываем окно проводника
    Write-Host "📁 Открываем проводник через Shell.Application..." -ForegroundColor Yellow
    Invoke-COMMethod -ComObject $shell -MethodName "Explore" -Arguments @("C:\")
    
    Write-Host "✅ Пример 1 завершен" -ForegroundColor Green
}
catch {
    Write-Error "Ошибка в примере 1: $_"
}

# ============================================================================
# ПРИМЕР 2: Создание и работа с Excel через COM
# ============================================================================
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "ПРИМЕР 2: Microsoft Excel" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta

try {
    # Проверяем, установлен ли Excel
    $excel = $null
    try {
        $excel = New-Object -ComObject "Excel.Application"
        Write-Host "✅ Excel.Application создан" -ForegroundColor Green
    }
    catch {
        Write-Warning "Excel не установлен на этой машине. Пропускаем пример 2."
        throw
    }
    
    # Устанавливаем свойство Visible через InvokeMember
    Set-COMProperty -ComObject $excel -PropertyName "Visible" -Value $true
    
    # Создаем новую книгу
    Write-Host "📘 Создаем новую книгу..." -ForegroundColor Yellow
    $workbooks = Get-COMProperty -ComObject $excel -PropertyName "Workbooks"
    $workbook = Invoke-COMMethod -ComObject $workbooks -MethodName "Add"
    
    # Получаем активный лист
    $sheets = Get-COMProperty -ComObject $excel -PropertyName "Sheets"
    $sheet = Get-COMProperty -ComObject $sheets -MethodName "Item" -Arguments @(1)
    
    # Записываем данные в ячейку
    $cells = Get-COMProperty -ComObject $sheet -PropertyName "Cells"
    Invoke-COMMethod -ComObject $cells -MethodName "Item" -Arguments @(1, 1)
    
    # Устанавливаем значение через свойство (особый случай)
    $range = Get-COMProperty -ComObject $sheet -PropertyName "Range" -Arguments @("A1")
    Set-COMProperty -ComObject $range -PropertyName "Value" -Value "Hello from Caldera COM!"
    
    Write-Host "📝 Данные записаны в ячейку A1" -ForegroundColor Cyan
    
    # Ждем, чтобы увидеть результат
    Start-Sleep -Seconds 3
    
    # Закрываем Excel без сохранения
    Write-Host "🚪 Закрываем Excel..." -ForegroundColor Yellow
    Invoke-COMMethod -ComObject $workbook -MethodName "Close" -Arguments @($false)
    Invoke-COMMethod -ComObject $excel -MethodName "Quit"
    
    Write-Host "✅ Пример 2 завершен" -ForegroundColor Green
}
catch {
    Write-Warning "Пропускаем пример 2: $_"
}

# ============================================================================
# ПРИМЕР 3: Работа с файловой системой через Scripting.FileSystemObject
# ============================================================================
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "ПРИМЕР 3: FileSystemObject" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta

try {
    # Создаем FSO
    $fso = New-Object -ComObject "Scripting.FileSystemObject"
    Write-Host "✅ FileSystemObject создан" -ForegroundColor Green
    
    # Создаем временную папку
    $tempPath = [System.IO.Path]::GetTempPath()
    $testFolder = Join-Path $tempPath "CalderaTest_$(Get-Random)"
    
    # Создаем папку
    Write-Host "📁 Создаем папку: $testFolder" -ForegroundColor Yellow
    $folder = Invoke-COMMethod -ComObject $fso -MethodName "CreateFolder" -Arguments @($testFolder)
    
    # Создаем файл в папке
    $filePath = Join-Path $testFolder "test.txt"
    $file = Invoke-COMMethod -ComObject $fso -MethodName "CreateTextFile" -Arguments @($filePath, $true)
    
    # Записываем данные
    Invoke-COMMethod -ComObject $file -MethodName "WriteLine" -Arguments @("Тестовая строка от Caldera")
    Invoke-COMMethod -ComObject $file -MethodName "Close"
    
    Write-Host "📄 Файл создан: $filePath" -ForegroundColor Cyan
    
    # Читаем файл обратно
    $readFile = Invoke-COMMethod -ComObject $fso -MethodName "OpenTextFile" -Arguments @($filePath, 1)  # 1 = ForReading
    $content = Invoke-COMMethod -ComObject $readFile -MethodName "ReadAll"
    Invoke-COMMethod -ComObject $readFile -MethodName "Close"
    
    Write-Host "📖 Прочитано из файла: $content" -ForegroundColor Green
    
    # Получаем информацию о файле
    $fileInfo = Get-COMProperty -ComObject $fso -PropertyName "GetFile" -Arguments @($filePath)
    $size = Get-COMProperty -ComObject $fileInfo -PropertyName "Size"
    $dateCreated = Get-COMProperty -ComObject $fileInfo -PropertyName "DateCreated"
    
    Write-Host "📊 Размер файла: $size байт" -ForegroundColor Cyan
    Write-Host "📅 Создан: $dateCreated" -ForegroundColor Cyan
    
    # Удаляем тестовую папку
    Write-Host "🗑️ Удаляем тестовые файлы..." -ForegroundColor Yellow
    Invoke-COMMethod -ComObject $fso -MethodName "DeleteFolder" -Arguments @($testFolder, $true)
    
    Write-Host "✅ Пример 3 завершен" -ForegroundColor Green
}
catch {
    Write-Error "Ошибка в примере 3: $_"
}

# ============================================================================
# ПРИМЕР 4: Internet Explorer (если доступен)
# ============================================================================
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "ПРИМЕР 4: Internet Explorer" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta

try {
    # Проверяем, доступен ли Internet Explorer
    $ie = $null
    try {
        $ie = New-Object -ComObject "InternetExplorer.Application"
        Write-Host "✅ Internet Explorer создан" -ForegroundColor Green
    }
    catch {
        Write-Warning "Internet Explorer не доступен. Пропускаем пример 4."
        throw
    }
    
    # Устанавливаем свойства
    Set-COMProperty -ComObject $ie -PropertyName "Visible" -Value $true
    Set-COMProperty -ComObject $ie -PropertyName "Width" -Value 800
    Set-COMProperty -ComObject $ie -PropertyName "Height" -Value 600
    
    # Навигируем на страницу
    Write-Host "🌐 Открываем страницу..." -ForegroundColor Yellow
    Invoke-COMMethod -ComObject $ie -MethodName "Navigate" -Arguments @("http://example.com")
    
    # Ждем загрузки (простой вариант)
    Start-Sleep -Seconds 3
    
    # Получаем заголовок страницы
    $document = Get-COMProperty -ComObject $ie -PropertyName "Document"
    $title = Get-COMProperty -ComObject $document -PropertyName "title"
    Write-Host "📑 Заголовок страницы: $title" -ForegroundColor Cyan
    
    # Закрываем IE
    Write-Host "🚪 Закрываем Internet Explorer..." -ForegroundColor Yellow
    Invoke-COMMethod -ComObject $ie -MethodName "Quit"
    
    Write-Host "✅ Пример 4 завершен" -ForegroundColor Green
}
catch {
    Write-Warning "Пропускаем пример 4: $_"
}

# ============================================================================
# БОНУС: Создание COM-объекта без ProgID (только по CLSID)
# ============================================================================
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "БОНУС: Создание COM-объекта через CLSID" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta

try {
    # CLSID для Shell.Application (можно заменить на любой другой)
    $clsid = New-Object Guid '13709620-C279-11CE-A49E-444553540000'
    
    # Получаем тип по CLSID
    $type = [Type]::GetTypeFromCLSID($clsid)
    if ($type) {
        # Создаем экземпляр через Activator
        $obj = [Activator]::CreateInstance($type)
        Write-Host "✅ COM-объект создан через CLSID: $clsid" -ForegroundColor Green
        
        # Проверяем, что это действительно Shell.Application
        $name = Get-COMProperty -ComObject $obj -PropertyName "Application"
        Write-Host "🔍 Объект создан: $(($name -ne $null))" -ForegroundColor Cyan
    }
    else {
        Write-Warning "Тип по CLSID $clsid не найден"
    }
}
catch {
    Write-Error "Ошибка при создании через CLSID: $_"
}

# ============================================================================
# ИТОГ
# ============================================================================
Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "✅ СКРИПТ ВЫПОЛНЕН" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green
Write-Host ""
Write-Host "📌 Ключевые моменты:" -ForegroundColor Yellow
Write-Host "   • Методы COM вызываются через [System.__ComObject].InvokeMember()" -ForegroundColor White
Write-Host "   • Аргументы всегда передаются как массив @(arg1, arg2, ...)" -ForegroundColor White
Write-Host "   • Свойства читаются через GetProperty, устанавливаются через SetProperty" -ForegroundColor White
Write-Host "   • Всегда оборачивайте вызовы в try/catch для обработки ошибок" -ForegroundColor White