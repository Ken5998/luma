#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Tag,
    [Parameter(Mandatory)][string] $Directory,
    [string] $ExistingNotes = '',
    [switch] $ReportOnly
)
. "$PSScriptRoot/virustotal-common.ps1"
if ([string]::IsNullOrWhiteSpace($env:VT_API_KEY)) { throw 'VT_API_KEY is not configured.' }
$assets = @(Get-LumaScanAssets $Directory $Tag)
$script:vtLastRequest = [DateTime]::MinValue
$notes = [Collections.Generic.List[string]]::new()
$results = [Collections.Generic.List[object]]::new()
$notes.Add("<!-- luma-virustotal:start -->`n## VirusTotal`n")
$notes.Add('These release files are public samples. Reports are informational: false positives are possible, and zero detections do not guarantee safety. This does not replace code signing or remove SmartScreen warnings.')
$notes.Add("`nLast checked: $([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm')) UTC.`n")
$hasErrors = $false
foreach ($asset in $assets) {
    $stage = 'existing analysis lookup'
    $result = [ordered]@{ name = $asset.Name; sha256 = $asset.Hash; url = $asset.Url; status = 'unavailable' }
    try {
        if ($ReportOnly) {
            $analysisId = Get-VirusTotalAnalysisId $ExistingNotes $asset
        } else {
            $stage = 'upload URL lookup'
            $uploadUrl = 'https://www.virustotal.com/api/v3/files'
            if ($asset.File.Length -gt 32MB) { $uploadUrl = (Invoke-VirusTotal 'https://www.virustotal.com/api/v3/files/upload_url').data }
            $stage = 'file upload'
            $uploaded = Invoke-VirusTotal $uploadUrl 'Post' $asset.File
            $analysisId = $uploaded.data.id
            if ($analysisId -cnotmatch '\A[A-Za-z0-9=_-]+\z') { throw 'Invalid analysis ID.' }
        }
        $result.analysisId = $analysisId
        $result.status = 'queued'
        $notes.Add("- [$($asset.Name)]($($asset.Url)) — submitted; analysis ID: ``$analysisId``.")
        $stage = 'analysis status'
        for ($poll = 0; $poll -lt 3; $poll++) {
            $analysis = Invoke-VirusTotal "https://www.virustotal.com/api/v3/analyses/$([Uri]::EscapeDataString($analysisId))"
            $attributes = $analysis.data.attributes
            if ($attributes.status -notin @('queued', 'in-progress', 'completed')) { throw 'Invalid analysis status.' }
            if ($attributes.status -eq 'completed') {
                foreach ($field in @('malicious', 'suspicious')) {
                    $value = $attributes.stats.$field
                    if ($null -eq $value -or [string]$value -notmatch '\A[0-9]+\z') { throw 'Missing analysis counts.' }
                }
                $result.stats = $attributes.stats
                $result.status = 'completed'
                $notes.Add("  Analysis completed: $($attributes.stats.malicious) malicious, $($attributes.stats.suspicious) suspicious engine results. See report for context.")
                break
            }
            $result.status = $attributes.status
        }
        if ($result.status -ne 'completed') { $notes.Add('  Analysis pending; refresh the results later or follow the report link. No final detection count is available yet.') }
    } catch {
        $hasErrors = $true
        $reason = 'Network, validation or response-format error.'
        if ($_.Exception.Message -match '^VirusTotal request unavailable \(HTTP [0-9]{1,3}\)\.$') { $reason = $_.Exception.Message }
        $result.status = 'unavailable'
        $result.errorStage = $stage
        if ($result.analysisId) {
            $notes.Add("  Analysis status unavailable. $reason Follow the report link or refresh results later.")
        } else {
            $notes.Add("- $($asset.Name): submission unavailable at $stage. $reason No clean-scan claim is made.")
        }
        Write-Warning "VirusTotal unavailable for $($asset.Name) at ${stage}: $reason"
    }
    $results.Add($result)
}
$notes.Add('<!-- luma-virustotal:end -->')
$notes | Set-Content -LiteralPath (Join-Path $Directory 'virustotal.md') -Encoding utf8NoBOM
ConvertTo-Json -InputObject @($results.ToArray()) -Depth 8 | Set-Content -LiteralPath (Join-Path $Directory 'virustotal-results.json') -Encoding utf8NoBOM
[pscustomobject]@{ HasErrors = $hasErrors; ReportPath = (Join-Path $Directory 'virustotal.md') }
