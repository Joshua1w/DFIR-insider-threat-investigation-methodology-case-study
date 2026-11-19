<#
.SYNOPSIS
    Read-only export of Microsoft 365 evidence for one user and time window, with SHA-256
    hashing and a collection log. This is the "collect preserved server-side evidence" step
    of the case study.

.DESCRIPTION
    Exports:
      1. Unified audit log mailbox activity (send, delete and inbox-rule operations)
      2. Message trace for outbound mail from the user
      3. Entra ID sign-in logs (optional; requires Microsoft Graph PowerShell)

    Each export is written to CSV, hashed with SHA-256, and recorded in a collection log
    (operator, host, UTC timestamps, cmdlets run, module versions). The log and hashes go
    straight into the chain of custody record.

    All cmdlets used here are READ-ONLY. Nothing in the tenant is changed.

.NOTES
    - Run only with documented authority, under a case reference.
    - Requires: ExchangeOnlineManagement (Search-UnifiedAuditLog, Get-MessageTraceV2);
      Microsoft.Graph.Reports for sign-ins.
    - Which operations are audited depends on licensing (Audit Standard/Premium) and the
      mailbox audit configuration. Confirm what the tenant records before treating
      absence as meaningful.
    - Time parameters are UTC. Convert to the case reference time zone during analysis.
    - Validate in a test tenant before operational use.

.EXAMPLE
    .\Export-M365Evidence.ps1 -CaseRef "CASE-2026-014" -UserPrincipalName "user@contoso.com" `
        -StartUtc "2026-11-09T00:00:00Z" -EndUtc "2026-11-10T00:00:00Z" -OutputDir .\evidence
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]   $CaseRef,
    [Parameter(Mandatory)] [string]   $UserPrincipalName,
    [Parameter(Mandatory)] [datetime] $StartUtc,
    [Parameter(Mandatory)] [datetime] $EndUtc,
    [Parameter(Mandatory)] [string]   $OutputDir,
    [switch] $IncludeSignIns
)

$ErrorActionPreference = 'Stop'
$StartUtc = $StartUtc.ToUniversalTime()
$EndUtc   = $EndUtc.ToUniversalTime()

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$LogPath = Join-Path $OutputDir "$CaseRef-collection-log.txt"

function Write-CollectionLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-ddTHH:mm:ss.fffZ}  {1}' -f (Get-Date).ToUniversalTime(), $Message
    Add-Content -Path $LogPath -Value $line -Encoding utf8
    Write-Host $line
}

function Save-HashedExport {
    param([object[]] $Rows, [string] $Name)
    $path = Join-Path $OutputDir "$CaseRef-$Name.csv"
    if ($Rows -and $Rows.Count -gt 0) {
        $Rows | Export-Csv -Path $path -NoTypeInformation -Encoding utf8
    } else {
        # An empty result is itself a finding: record it rather than skipping the file.
        Set-Content -Path $path -Value '# no records returned for the query window' -Encoding utf8
    }
    $hash = (Get-FileHash -Path $path -Algorithm SHA256).Hash
    Write-CollectionLog ("EXPORT {0}  rows={1}  SHA256={2}" -f (Split-Path $path -Leaf), @($Rows).Count, $hash)
}

Write-CollectionLog "START case=$CaseRef operator=$env:USERNAME host=$env:COMPUTERNAME"
Write-CollectionLog "SCOPE user=$UserPrincipalName window=$($StartUtc.ToString('o'))..$($EndUtc.ToString('o'))"
$exo = Get-Module -ListAvailable ExchangeOnlineManagement | Sort-Object Version -Descending | Select-Object -First 1
Write-CollectionLog "MODULE ExchangeOnlineManagement $($exo.Version)"

# ---- 1. Unified audit log: mailbox send / delete / rule activity -----------------------------
$operations = @(
    'Send', 'SendAs', 'SendOnBehalf',                  # message leaving the mailbox
    'SoftDelete', 'HardDelete', 'MoveToDeletedItems',  # clean-up after sending
    'New-InboxRule', 'Set-InboxRule', 'UpdateInboxRules', 'Set-Mailbox'  # forwarding
)
Write-CollectionLog "RUN Search-UnifiedAuditLog -Operations $($operations -join ',')"

$sessionId = "$CaseRef-" + [guid]::NewGuid()
$audit = [System.Collections.Generic.List[object]]::new()
do {
    $page = Search-UnifiedAuditLog -StartDate $StartUtc -EndDate $EndUtc `
        -UserIds $UserPrincipalName -Operations $operations `
        -SessionId $sessionId -SessionCommand ReturnLargeSet -ResultSize 5000
    if ($page) { $audit.AddRange([object[]]$page) }
} while ($page -and $page.Count -eq 5000)

# ReturnLargeSet results are unsorted and can contain duplicates; de-duplicate on Identity.
$auditRows = $audit | Sort-Object Identity -Unique | Sort-Object CreationDate |
    Select-Object CreationDate, UserIds, Operations, RecordType, Identity, AuditData
Save-HashedExport -Rows $auditRows -Name 'ual-mailbox'

# ---- 2. Message trace: outbound mail from the user ------------------------------------------
# Get-MessageTraceV2 replaces the deprecated Get-MessageTrace. Each query covers at most
# 10 days, so split longer windows into chunks.
Write-CollectionLog "RUN Get-MessageTraceV2 -SenderAddress $UserPrincipalName"
$trace = [System.Collections.Generic.List[object]]::new()
$chunkStart = $StartUtc
while ($chunkStart -lt $EndUtc) {
    $chunkEnd = @($chunkStart.AddDays(10), $EndUtc) | Sort-Object | Select-Object -First 1
    $rows = Get-MessageTraceV2 -SenderAddress $UserPrincipalName -StartDate $chunkStart -EndDate $chunkEnd -ResultSize 5000
    if ($rows) { $trace.AddRange([object[]]$rows) }
    $chunkStart = $chunkEnd
}
$traceRows = $trace | Select-Object Received, SenderAddress, RecipientAddress, Subject, Status, Size, MessageId, MessageTraceId, FromIP
Save-HashedExport -Rows $traceRows -Name 'message-trace'

# ---- 3. Entra ID sign-ins (optional) --------------------------------------------------------
if ($IncludeSignIns) {
    $filter = "userPrincipalName eq '$UserPrincipalName' and createdDateTime ge $($StartUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')) and createdDateTime le $($EndUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    Write-CollectionLog "RUN Get-MgAuditLogSignIn -Filter `"$filter`""
    $signIns = Get-MgAuditLogSignIn -Filter $filter -All |
        Select-Object CreatedDateTime, UserPrincipalName, AppDisplayName, ClientAppUsed, IPAddress,
            @{n='City';e={$_.Location.City}}, @{n='Country';e={$_.Location.CountryOrRegion}},
            @{n='DeviceId';e={$_.DeviceDetail.DeviceId}}, @{n='DeviceName';e={$_.DeviceDetail.DisplayName}},
            @{n='ErrorCode';e={$_.Status.ErrorCode}}, ConditionalAccessStatus, Id
    Save-HashedExport -Rows $signIns -Name 'entra-signins'
}

Write-CollectionLog "END case=$CaseRef"
$logHash = (Get-FileHash -Path $LogPath -Algorithm SHA256).Hash
Write-Host "`nCollection log SHA-256: $logHash  (record this in the chain of custody form)"
