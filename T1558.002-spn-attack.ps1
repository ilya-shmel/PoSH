## 0. Set domain
$domain = "corp.local"

## 1. Run setspn
$spnOutput = setspn -T $domain -Q */* 2>$null | Out-String

## 2. Find "host/" (or "HOST/")
$pattern = '(host|HOST)/([^\s]+)'
$match = [regex]::Match($spnOutput, $pattern, 'IgnoreCase')

if ($match.Success) {
    $fullHostName = $match.Groups[2].Value.Trim()
    Write-Host "Found SPN: $fullHostName"
} else {
    Write-Host "setspn didn't return host/ SPN, trying ADSI fallback..."
    
## Fallback through ADSI
    try {
        $searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]"LDAP://$domain")
        $searcher.Filter = "(servicePrincipalName=*host*)"
        $searcher.PageSize = 1000
        $results = $searcher.FindAll()
        $spns = $results | ForEach-Object { $_.Properties.serviceprincipalname } | Where-Object { $_ -match '^host/' }
        $fullHostName = ($spns | Select-Object -First 1) -replace '^host/', ''
    } catch {
        Write-Error "ADSI fallback failed: $_"
        exit 1
    }
}

if (-not $fullHostName) {
    Write-Error "No host SPN found"
    exit 1
}

## 3. Form REALM (domain name in UPPERCASE)
$realm = $domain.ToUpper()
$spnForToken = "host/$fullHostName@$realm"

Write-Host "Using SPN: $spnForToken"

## 4. Create token
Add-Type -AssemblyName System.IdentityModel
$token = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $spnForToken

Write-Host "Token acquired successfully"