# Helper functions to convert between IP string and integer values.
function Convert-IPToInt {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IPAddress
    )
    return [BitConverter]::ToUInt32(([System.Net.IPAddress]::Parse($IPAddress)).GetAddressBytes(), 0)
}

function Convert-IntToIP {
    param (
        [Parameter(Mandatory = $true)]
        [uint32]$IntIP
    )
    $bytes = [BitConverter]::GetBytes($IntIP)
    return [System.Net.IPAddress]::new($bytes).ToString()
}

# Krijg JSON
$config = Get-Content -Path "config.json" | ConvertFrom-Json

# Range naar int
$startIPInt = Convert-IPToInt -IPAddress $config.IPAddressRange.Start
$endIPInt   = Convert-IPToInt -IPAddress $config.IPAddressRange.End

# controleer of het ip address actief is
function Test-IPActive {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IPAddress
    )
    # Wacht
    $ping = Test-Connection -ComputerName $IPAddress -Count 1 -Quiet -ErrorAction SilentlyContinue -TimeoutSeconds 1
    return $ping
}

$availableIP = $null

# Loop over the range to find the first available IP
for ($ipInt = $startIPInt; $ipInt -le $endIPInt; $ipInt++) {
    $currentIP = Convert-IntToIP -IntIP $ipInt
    Write-Host "Checkt voor ip: $currentIP ..."
    if (-not (Test-IPActive -IPAddress $currentIP)) {
        Write-Host "Vrij IP: $currentIP"
        $availableIP = $currentIP
        break
    }
}

if (-not $availableIP) {
    Write-Error "Geen IP gevonden  $($config.IPAddressRange.Start) - $($config.IPAddressRange.End)."
    exit 1
}

# Covert /24 to 255
$subnetBits = ($config.SubnetMask -split "\.").ForEach({ [Convert]::ToString($_,2).PadLeft(8,'0') }) -join ''
$prefixLength = ($subnetBits -split '1').Count - 1

# Clear bestaande ip config
Write-Host "Verwijderd oude ip addressering $($config.InterfaceAlias)..."
Remove-NetIPAddress -InterfaceAlias $config.InterfaceAlias -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $config.InterfaceAlias -Confirm:$false -ErrorAction SilentlyContinue

# zet nieuwe ip address
Write-Host "Nieuwe IP address: $availableIP/$prefixLength..."
New-NetIPAddress -InterfaceAlias $config.InterfaceAlias -IPAddress $availableIP -PrefixLength $prefixLength -DefaultGateway $config.Gateway

# Zet DNS server
Write-Host "DNS Server instellen..."
Set-DnsClientServerAddress -InterfaceAlias $config.InterfaceAlias -ServerAddresses $config.DNS

Write-Host "IP aangepaast naar $availableIP!"
