param(
    [Parameter(Mandatory)] [string] $File,
    [Parameter(Mandatory)] [string] $Repository,
    [Parameter(Mandatory)] [string] $Commit,
    [Parameter(Mandatory)] [string] $Version,
    [Parameter(Mandatory)] [ValidateSet('production', 'preview')] [string] $Kind,
    [string] $ProductionDigest
)

$ErrorActionPreference = 'Stop'
if ($Kind -eq 'preview' -and $ProductionDigest -notmatch '^[0-9a-f]{64}$') {
    throw 'A production SHA-256 digest is required for preview verification.'
}
$predicateType = 'https://github.com/jessehouwing/azure-pipelines-agent-screenshot/attestations/release-candidate/v1'
$result = gh attestation verify $File --repo $Repository `
    --signer-workflow "$Repository/.github/workflows/release.yml" `
    --predicate-type $predicateType --format json
if ($LASTEXITCODE -ne 0) { throw "Candidate attestation verification failed for $File." }

$verified = @(($result -join "`n") | ConvertFrom-Json)
$match = @($verified | Where-Object {
    $predicate = $_.verificationResult.statement.predicate
    $predicate.commit -ceq $Commit -and $predicate.version -ceq $Version -and $predicate.kind -ceq $Kind -and
        ($Kind -ne 'preview' -or $predicate.productionSha256 -ceq $ProductionDigest)
})
if ($match.Count -eq 0) { throw "No verified $Kind attestation matches candidate $Commit and version $Version." }
Write-Host "Verified $Kind artifact for candidate $Commit and version $Version."
