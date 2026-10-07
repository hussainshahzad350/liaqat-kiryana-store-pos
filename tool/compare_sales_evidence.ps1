$ErrorActionPreference = 'Stop'
$salesEvidenceRoot = Join-Path $PSScriptRoot '../build/sales-phase3-review'
$salesEvidenceRoot = (Resolve-Path -LiteralPath $salesEvidenceRoot).Path
$compared = 0
foreach ($beforeFile in Get-ChildItem -LiteralPath $salesEvidenceRoot -Filter 'before-*.json') {
    $afterFile = Join-Path $salesEvidenceRoot ($beforeFile.Name -replace '^before-', 'after-')
    $normalized = @()
    foreach ($snapshotFile in @($beforeFile.FullName, $afterFile)) {
        $snapshot = Get-Content -LiteralPath $snapshotFile -Raw | ConvertFrom-Json -AsHashtable
        foreach ($invoice in $snapshot.invoices) {
            if ($invoice.notes) {
                $notes = $invoice.notes | ConvertFrom-Json -AsHashtable
                # Cancellation clock values differ between isolated runs.
                if ($notes.cancellation) { $notes.cancellation.Remove('at') | Out-Null }
                $invoice.notes = $notes | ConvertTo-Json -Depth 30 -Compress
            }
        }
        $normalized += ($snapshot | ConvertTo-Json -Depth 50 -Compress)
    }
    if ($normalized[0] -cne $normalized[1]) { throw "Financial evidence differs: $($beforeFile.Name)" }
    Write-Output "MATCH $($beforeFile.Name)"
    $compared++
}
if ($compared -ne 8) { throw "Expected eight posted/cancelled snapshots; found $compared." }
$protected = Get-Content -LiteralPath (Join-Path $salesEvidenceRoot 'protected-before.json') -Raw | ConvertFrom-Json
foreach ($entry in $protected) {
    if ((Get-FileHash -LiteralPath $entry.Path).Hash -ne $entry.Hash) {
        throw "Protected implementation changed: $($entry.Path)"
    }
}
Write-Output "$compared financial snapshots match; $($protected.Count) protected implementation files unchanged."
