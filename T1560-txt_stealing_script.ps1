## Variables

## Get-Content attack
# 1. Create hash table
$data = @{
    name = "John Doe"
    age = 30
    email = "john.doe@example.com"
    isActive = $true
    skills = @("PowerShell", "Python", "Linux")
    address = @{
        city = "Moscow"
        zip = "101000"
    }
}

# 2. Convert to JSON (with formatting)
$json = $data | ConvertTo-Json -Depth 3

# 3. Save to a file
$json | Out-File -FilePath "C:\Temp\data.json" -Encoding UTF8

Write-Host "✅ JSON файл создан: C:\Temp\data.json"

#---
Get-Content C:\Temp\data.json


## Xcopy attack
New-Item -Path "C:\Temp\backup" -ItemType Directory
New-Item -Path "C:\Temp\database.config" -ItemType File
"server=localhost`nport=5432`ndatabase=test_db`nuser=admin`npassword=P@ssw0rd" | Set-Content C:\Temp\database.config
xcopy  C:\Temp\database.config C:\Temp\backup\
