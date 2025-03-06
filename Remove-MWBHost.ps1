[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]    
    [string]$ConfigJSON,
    [Parameter(Mandatory=$false)]    
    [string]$HostsFile,
    [Parameter(Mandatory=$false)]
    [string]$Hosts
)
#$ConfigJSON = ".\config.json"

# Acceptable formats for ingesting hostnames --->
# 1) Put hostnames in a text file, going line by line for each hostname value, using the -HostsFile parameter
#$HostsFile = ".\MWB_hosts.txt"

# 2) Give individual hostname, using the -Hosts parameter
# NOTE: If only giving one hostname, don't need to encase in quotes --> "" or ''
#$Hosts = 'CLIENT01'

# 3) Give a comma-seperated list of hostnames, using the -Hosts parameter
# NOTE: Required to be encased in quotes, recommend using '' to avoid accidental shell interpretation
#$Hosts = 'CLIENT01, CLIENT02, SERVER01'
#$Hosts = 'CLIENT01,CLIENT02,SERVER01'

# Checks that all required configs are present, as well as hostnames to process. 
# Exits if no hosts provided
$CONF = Get-Content -Path $ConfigJSON | ConvertFrom-Json
if ($null -eq $Hosts -and $null -eq $HostsFile) {
    Write-Host "ERROR:`tScript requires hostnames to process, either individualy or multiple in a file"
    Exit 1
} elseif ($null -ne $HostsFile -and $HostsFile -ne '') {
    $HOSTNAME_LIST = Get-Content -Path $HostsFile
} else {
    $HOSTNAME_LIST = (($Hosts -split ",").Trim() -split " ").Trim()
}

# Initialize variables, counts total host removed or not removed from script
$HOST_REMOVAL_COUNTER = 0
$HOST_WARNING_COUNTER = 0

# Appends keywords to end or Nebula URL for easy API access
function Get-NebulaUrl {
    param (
        [string]$path
    )
    return "https://api.malwarebytes.com$path"
}

# Creates interactable PowerShell object that is used for API requests/responses
function Get-NebulaClient {
    param (
        [string]$clientId,
        [string]$clientSecret,
        [string]$clientAccount
    )

    $clientScope = @("read write")
    $headers = @{
        "accountid" = $clientAccount
    }

    $body = @{
        "grant_type" = "client_credentials"
        "scope" = $clientScope -join " "
    }

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $clientId, $clientSecret)))

    $tokenResponse = Invoke-RestMethod -Uri (Get-NebulaUrl "/oauth2/token") -Method Post -Headers @{
        "Authorization" = "Basic $base64AuthInfo"
    } -Body $body

    $headers.Add("Authorization", "Bearer $($tokenResponse.access_token)")

    return $headers
}

# API client object, connects to our MWB tenant
$nebulaClient = Get-NebulaClient -clientId $CONF.MWB_ClientID -clientSecret $CONF.MWB_ClientSecret -clientAccount $CONF.MWB_AccountID

# Finds host in our MWB systems through API, then removes the host by it's MWB ID
# Loop this process for each host
foreach ($h in $HOSTNAME_LIST) {
    $ReqBody = @{
        "domain_name" = "ms.nsd.org"
        "host_name" = $h
    }

    # Attempts to grab info from MWB for hostname
    $REQUEST = Invoke-RestMethod -Uri (Get-NebulaUrl "/nebula/v1/endpoints") -Headers $nebulaClient -Method Post -Body $ReqBody

    if ($REQUEST | Select-Object -ExpandProperty total_count) {
        # Select MWB ID for the host, if found in MWB systems
        $HOST_ID = $REQUEST | Select-Object -ExpandProperty endpoints | Select-Object -ExpandProperty machine | Select-Object -ExpandProperty id

        Write-Host "PROGRESS:`tID found! Deleting host ($h) from MWB..."
        $HOST_REMOVAL_COUNTER += 1
        
        # Deletes host using ID value, if found in MWB systems
        Invoke-RestMethod -Uri (Get-NebulaUrl "/nebula/v1/endpoints/$HOST_ID") -Headers $nebulaClient -Method Delete
    } else {
        Write-Host "WARNING:`tNo valid ID in MWB for host ($h)! Continuing to next host..."
        $HOST_WARNING_COUNTER += 1
        continue
    }
}

# Script output of results, sorted by success vs. warnings
if ($HOST_REMOVAL_COUNTER -gt 0) {
    Write-Host "SUCCESS!`tRemoved a total of $HOST_REMOVAL_COUNTER hosts from MWB tenant!"
}
if ($HOST_WARNING_COUNTER -gt 0) {
    Write-Host "WARNING!`t$HOST_WARNING_COUNTER hosts could not be removed from MWB tenant, check output above..."
}