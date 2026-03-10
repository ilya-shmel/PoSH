$myDownloadUrl = "https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://www.dll-files.com/sevenzipsharp.dll.html&ved=2ahUKEwi15a-3mN6SAxVUEhAIHeHILWgQFnoECB0QAQ&usg=AOvVaw3eJ-js742t7GD9we9ayTNX"
$myPath = "C:\sevenzipsharp.zip"
$pathToDll = "C:\payloads\SevenZipSharp.dll"
$dll7zFile = "C:\Program Files\7-Zip\7z.dll"
$pathTo7zDll = "C:\payloads\7z.dll"


Invoke-WebRequest $myDownloadUrl -OutFile $myPath 
New-Item -Path 'C:\payloads' -ItemType Directory -Force
Expand-Archive -Path $myPath -DestinationPath $pathToDll
Copy-Item -Path $dll7zFile -Destination "C:\Destination\file.txt"

[SevenZip.SevenZipCompressor]::SetLibraryPath($pathTo7zDll)

# --- Функция для сжатия папки ---
Function Compress-With7Zip {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceFolder,      # Путь к папке, которую нужно сжать
        [Parameter(Mandatory=$true)]
        [string]$DestinationArchive # Полный путь к итоговому архиву (например, C:\temp\backup.7z)
    )

    try {
        # Создаем объект компрессора
        $compressor = New-Object SevenZip.SevenZipCompressor

        # (Опционально) Настраиваем параметры сжатия
        $compressor.CompressionLevel = SevenZip.CompressionLevel.Ultra # Максимальное сжатие
        $compressor.ArchiveFormat = [SevenZip.OutArchiveFormat]::SevenZip # Формат .7z
        $compressor.CompressionMethod = [SevenZip.CompressionMethod]::Lzma2 # Метод сжатия

        Write-Host "Начинаю сжатие папки '$SourceFolder' в архив '$DestinationArchive'..."

        # Выполняем сжатие
        $compressor.CompressDirectory($SourceFolder, $DestinationArchive)

        Write-Host "✅ Сжатие успешно завершено!" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Ошибка при сжатии: $_"
    }
}

# --- Функция для распаковки архива ---
Function Expand-With7Zip {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ArchivePath,       # Путь к архиву, который нужно распаковать
        [Parameter(Mandatory=$true)]
        [string]$DestinationFolder  # Папка, куда распаковать
    )

    try {
        # Создаем папку назначения, если её нет
        if (-not (Test-Path $DestinationFolder)) {
            New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
        }

        # Создаем объект экстрактора
        $extractor = New-Object SevenZip.SevenZipExtractor($ArchivePath)

        Write-Host "Начинаю распаковку архива '$ArchivePath' в папку '$DestinationFolder'..."

        # Выполняем распаковку
        $extractor.ExtractArchive($DestinationFolder)
        $extractor.Dispose() # Важно освободить ресурсы

        Write-Host "✅ Распаковка успешно завершена!" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Ошибка при распаковке: $_"
    }
}

# --- Примеры использования ---
<#
# Сжать папку C:\Test в архив C:\temp\myarchive.7z
Compress-With7Zip -SourceFolder "C:\Test" -DestinationArchive "C:\temp\myarchive.7z"

# Распаковать архив в папку C:\Extracted
Expand-With7Zip -ArchivePath "C:\temp\myarchive.7z" -DestinationFolder "C:\Extracted"
#>