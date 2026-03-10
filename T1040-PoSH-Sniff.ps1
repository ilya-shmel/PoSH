New-NetEventSession -Name Capture007 -LocalFilePath "$ENV:Temp\sniff.etl";
Add-NetEventPacketCaptureProvider -SessionName Capture007 -TruncationLength 100;
Start-NetEventSession -Name Capture007;
Stop-NetEventSession -Name Capture007;
Remove-NetEventSession -Name Capture007