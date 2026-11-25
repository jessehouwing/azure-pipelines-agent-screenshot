BeforeAll {
    $script:checker = Join-Path $PSScriptRoot 'check-release-state.ps1'
    $script:commit = '0123456789abcdef0123456789abcdef01234567'
}

Describe 'Release retry state' {
    BeforeEach {
        $script:previousOutput = $env:GITHUB_OUTPUT
        $env:GITHUB_OUTPUT = Join-Path $TestDrive 'output.txt'
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item -LiteralPath $env:GITHUB_OUTPUT }
        $script:file = Join-Path $TestDrive 'candidate.vsix'
        Set-Content -LiteralPath $script:file -Value 'candidate'
        $global:ReleaseTagLines = @("$script:commit`trefs/tags/v1.2.3")
        $global:ReleaseApiExit = 0
        $global:ReleaseApiResult = @{
            draft = $true
            assets = @(@{
                name = 'candidate.vsix'
                digest = 'sha256:' + (Get-FileHash -LiteralPath $script:file -Algorithm SHA256).Hash.ToLowerInvariant()
            })
        } | ConvertTo-Json -Depth 5
        $global:ReleaseGitWrites = 0
        $global:ReleaseGitQueryExit = 0
        Mock gh {
            $global:LASTEXITCODE = $global:ReleaseApiExit
            $global:ReleaseApiResult
        }
        Mock git {
            $global:LASTEXITCODE = 0
            if ($args[0] -eq 'ls-remote') {
                $global:LASTEXITCODE = $global:ReleaseGitQueryExit
                $global:ReleaseTagLines
            }
            else { $global:ReleaseGitWrites++ }
        }
        $script:parameters = @{
            Version = 'v1.2.3'
            Commit = $script:commit
            File = $script:file
            Repository = 'example/repo'
        }
    }

    AfterEach { $env:GITHUB_OUTPUT = $script:previousOutput }

    It 'creates a tag when no release or tag exists' {
        $global:ReleaseApiExit = 1
        $global:ReleaseApiResult = 'gh: Not Found (HTTP 404)'
        $global:ReleaseTagLines = @()
        & $script:checker @script:parameters
        Get-Content $env:GITHUB_OUTPUT | Should -Contain 'create=true'
        $global:ReleaseGitWrites | Should -Be 4
    }

    It 'reuses a matching draft and artifact without changing the tag' {
        & $script:checker @script:parameters
        Get-Content $env:GITHUB_OUTPUT | Should -Contain 'create=false'
        $global:ReleaseGitWrites | Should -Be 0
    }

    It 'checks the target of an annotated tag' {
        $global:ReleaseTagLines = @(
            (("a" * 40) + "`trefs/tags/v1.2.3")
            "$script:commit`trefs/tags/v1.2.3^{}"
        )
        & $script:checker @script:parameters
        Get-Content $env:GITHUB_OUTPUT | Should -Contain 'create=false'
    }

    It 'rejects a tag for a different commit' {
        $global:ReleaseTagLines = @(("f" * 40) + "`trefs/tags/v1.2.3")
        { & $script:checker @script:parameters } | Should -Throw '*different commit*'
        $global:ReleaseGitWrites | Should -Be 0
    }

    It 'rejects an existing finalized release' {
        $global:ReleaseApiResult = '{"draft":false,"assets":[]}'
        { & $script:checker @script:parameters } | Should -Throw '*already finalized*'
    }

    It 'rejects a draft with different bytes' {
        $global:ReleaseApiResult = '{"draft":true,"assets":[{"name":"candidate.vsix","digest":"sha256:wrong"}]}'
        { & $script:checker @script:parameters } | Should -Throw '*does not contain the verified VSIX*'
    }

    It 'fails closed on a release lookup error' {
        $global:ReleaseApiExit = 1
        $global:ReleaseApiResult = 'gh: Forbidden (HTTP 403)'
        { & $script:checker @script:parameters } | Should -Throw '*Unable to query release*'
        $global:ReleaseGitWrites | Should -Be 0
    }

    It 'fails closed on a tag lookup error' {
        $global:ReleaseGitQueryExit = 1
        { & $script:checker @script:parameters } | Should -Throw '*Unable to query existing release tag*'
        $global:ReleaseGitWrites | Should -Be 0
    }
}
