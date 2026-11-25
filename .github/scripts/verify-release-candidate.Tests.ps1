BeforeAll {
    $script:verifier = Join-Path $PSScriptRoot 'verify-release-candidate.ps1'
    $script:commit = '0123456789abcdef0123456789abcdef01234567'
    $script:digest = 'a' * 64
    $global:CandidateAttestationFixture = @(
        @{
            verificationResult = @{
                statement = @{
                    predicate = @{
                        commit = $script:commit
                        version = '1.2.3'
                        kind = 'preview'
                        productionSha256 = $script:digest
                    }
                }
            }
        }
    ) | ConvertTo-Json -Depth 10 -AsArray
}

Describe 'Release candidate attestation policy' {
    BeforeEach {
        Mock gh {
            $global:LASTEXITCODE = 0
            $global:CandidateAttestationFixture
        }
        $script:parameters = @{
            File = 'candidate.vsix'
            Repository = 'example/repo'
            Commit = $script:commit
            Version = '1.2.3'
            Kind = 'preview'
            ProductionDigest = $script:digest
        }
    }

    It 'accepts a verified attestation bound to the candidate and production artifact' {
        { & $script:verifier @script:parameters } | Should -Not -Throw
    }

    It 'rejects a different release commit' {
        $script:parameters.Commit = 'f' * 40
        { & $script:verifier @script:parameters } | Should -Throw '*No verified*'
    }

    It 'rejects a different production artifact' {
        $script:parameters.ProductionDigest = 'b' * 64
        { & $script:verifier @script:parameters } | Should -Throw '*No verified*'
    }

    It 'rejects failed cryptographic verification' {
        Mock gh { $global:LASTEXITCODE = 1 }
        { & $script:verifier @script:parameters } | Should -Throw '*verification failed*'
    }

    It 'accepts multiline JSON emitted by the verifier' {
        Mock gh {
            $global:LASTEXITCODE = 0
            $global:CandidateAttestationFixture -split "`n"
        }
        { & $script:verifier @script:parameters } | Should -Not -Throw
    }
}
