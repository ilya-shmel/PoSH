$compressedFile  = "C:\arcs\File.zip"
$sourceFile = "C:\arcs\MyFile.txt"

New-Item -Path $sourceFile -ItemType File
Set-Content -Path $compressedFile -Value "That's T1560 odd text file!"

$sourceFile = "C:\Users\i.shmadchenko\1.txt"
$compressedFile = "C:\Users\i.shmadchenko\1.zip"
$input = [System.IO.File]::OpenRead($sourceFile)
$output = [System.IO.File]::Create($compressedFile)
$gzipStream = New-Object System.IO.Compression.GZipStream($output,[System.IO.Compression.CompressionMode]::Compress)
$input.CopyTo($gzipStream)
$gzipStream.Close()