Write-Host "=== COM/DCOM TEST SUITE ===" -ForegroundColor Cyan
          
# 1. COM Registry Hijacking (TreatAs)
Write-Host "[1] Testing COM Hijacking detection (TreatAs)" -ForegroundColor Yellow
reg add "HKLM\SOFTWARE\Classes\CLSID\{0BE35203-8F91-11CE-9DE3-00AA004BB851}" /v TreatAs /t REG_SZ /d "{00000000-0000-0000-0000-000000000000}" /f

# 2. Per-user COM override
Write-Host "[2] Testing per-user COM override" -ForegroundColor Yellow
reg add "HKCU\Software\Classes\CLSID\{13709620-C279-11CE-A49E-444553540000}\InprocServer32" /ve /t REG_SZ /d "shell32.dll" /f

# 3. .NET Framework DCOM keys
Write-Host "[3] Testing DCOM Reflection keys" -ForegroundColor Yellow
reg add "HKLM\SOFTWARE\Microsoft\.NETFramework" /v AllowDCOMReflection /t REG_DWORD /d 1 /f

# 4. Local DCOM activation (MMC20)
Write-Host "[4] Testing local DCOM activation" -ForegroundColor Yellow
$com = [Type]::GetTypeFromCLSID("49B2791A-B1AE-4C90-9B8E-E860BA07F889")
$mmcApp = [System.Activator]::CreateInstance($com)

Write-Host "✅ Test complete. Check your SIEM for:" -ForegroundColor Green
Write-Host "  - Sysmon EventID 12,13 (Registry modifications)"
Write-Host "  - Sysmon EventID 1 (Process creation: regsvcs?)"
Write-Host "  - ETW/DCOM events (COMmander or similar)"
Write-Host "  - Security EventID 4688, 4624 (Logon type 3 for remote)"