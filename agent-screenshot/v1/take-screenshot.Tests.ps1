BeforeAll {
    $script:scriptPath = Join-Path $PSScriptRoot 'take-screenshot.ps1'
    $script:taskJson = Get-Content (Join-Path $PSScriptRoot 'task.json') -Raw | ConvertFrom-Json
}

Describe 'agent-screenshot task definition' {
    It 'has a valid task.json pointing at an existing script' {
        $taskJson.name | Should -Be 'agent-screenshot'
        $taskJson.execution.PowerShell3.target | Should -Be 'take-screenshot.ps1'
        Test-Path (Join-Path $PSScriptRoot $taskJson.execution.PowerShell3.target) | Should -BeTrue
    }

    It 'has a valid GUID id and version' {
        { [guid]$taskJson.id } | Should -Not -Throw
        $taskJson.version.Major | Should -Be 1
    }
}

Describe 'take-screenshot.ps1' {
    It 'parses without syntax errors' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }

    It 'defines the screenshot helper functions' {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$null)
        $names = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true).Name
        $names | Should -Contain 'Get-Screenshot'
        $names | Should -Contain 'Get-ScreenResolution'
    }

    It 'uploads the screenshot as a task file' {
        Get-Content $scriptPath -Raw | Should -Match '##vso\[task\.uploadfile\]'
    }
}
