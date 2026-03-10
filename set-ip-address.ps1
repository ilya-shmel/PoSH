$Index = 4 # ТВОЙ ИНДЕКС
$NewIP = "172.30.253.170"
$Prefix = 24
$Gateway = "172.30.253.105"

# 1. Сбрасываем старый адрес, если он мешает
Remove-NetIPAddress -InterfaceIndex $Index -Confirm:$false

# 2. Устанавливаем новый адрес
New-NetIPAddress -InterfaceIndex $Index -IPAddress $NewIP -PrefixLength $Prefix -DefaultGateway $Gateway