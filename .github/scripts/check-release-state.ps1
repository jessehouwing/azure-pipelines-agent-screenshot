param(
    [Parameter(Mandatory)] [string] $Version,
    [Parameter(Mandatory)] [string] $Commit,
    [Parameter(Mandatory)] [string] $File,
    [Parameter(Mandatory)] [string] $Repository
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$releaseResult = gh api "repos/$Repository/releases/tags/$Version" 2>&1
$releaseExit = $LASTEXITCODE
if ($releaseExit -ne 0 -and "$releaseResult" -notmatch '\(HTTP 404\)') {
    throw "Unable to query release ${Version}: $releaseResult"
}
$existingTag = @(git ls-remote --tags origin "refs/tags/$Version" "refs/tags/$Version^{}")
if ($LASTEXITCODE -ne 0) { throw 'Unable to query existing release tag.' }
if ($existingTag.Count -gt 0) {
    $peeled = @($existingTag | Where-Object { $_ -match '\^\{\}$' })
    $tagCommit = if ($peeled.Count -eq 1) { ($peeled[0] -split '\s+')[0] } else { ($existingTag[0] -split '\s+')[0] }
    if ($tagCommit -cne $Commit) { throw "Tag $Version points to a different commit." }
}
elseif ($releaseExit -eq 0) {
    throw "Release $Version exists but its tag is missing."
}
else {
    git config user.name "github-actions[bot]"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to configure Git author.' }
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to configure Git author.' }
    git tag -a "$Version" -m "Release $Version"
    if ($LASTEXITCODE -ne 0) { throw "Unable to create tag $Version." }
    git push origin "$Version"
    if ($LASTEXITCODE -ne 0) { throw "Unable to push tag $Version." }
}

if ($releaseExit -eq 0) {
    $release = ($releaseResult -join "`n") | ConvertFrom-Json
    if (-not $release.draft) { throw "Release $Version is already finalized." }
    $assets = @($release.assets | Where-Object { $_.name -ceq [IO.Path]::GetFileName($File) })
    $digest = 'sha256:' + (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($assets.Count -ne 1 -or $assets[0].digest -cne $digest) {
        throw "Existing draft $Version does not contain the verified VSIX."
    }
    'create=false' >> $env:GITHUB_OUTPUT
}
else {
    'create=true' >> $env:GITHUB_OUTPUT
}
