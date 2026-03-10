$zipPath  = "C:\arcs\File.zip"
$filePath = "C:\arcs\MyFile.txt"

New-Item -Path $filePath -ItemType File
Set-Content -Path $filePath -Value "That's T1560 odd text file!"

Add-Type -AssemblyName System.IO.Compression.FileSystem


Write-Host "ZipPath:  $zipPath"
Write-Host "FilePath: $filePath"

if (-not (Test-Path $filePath)) {
    Write-Host "ERROR: File not found: $filePath"
    exit 1
}

try {
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    $zip.CreateEntryFromFile($filePath, "1.txt")
    $zip.Dispose()
    Write-Host "OK: Zip created: $zipPath"
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}