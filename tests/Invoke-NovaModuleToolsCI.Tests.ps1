BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:novaModuleToolsCiScriptPath = Join-Path $script:repoRoot 'scripts/build/ci/Invoke-NovaModuleToolsCI.ps1'

    function Invoke-NovaModuleToolsCIRunner {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][string]$RunnerContent
        )

        $runnerPath = Join-Path $TestDrive 'Run-Invoke-NovaModuleToolsCI.ps1'
        $content = @"
$RunnerContent

if (`$null -ne `$LASTEXITCODE) {
    exit `$LASTEXITCODE
}

if (`$?) {
    exit 0
}

exit 1
"@
        Set-Content -LiteralPath $runnerPath -Value $content -Encoding utf8

        $output = & pwsh -NoLogo -NoProfile -File $runnerPath 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = @($output)
        }
    }
}

Describe 'Invoke-NovaModuleToolsCI' {
    It 'forwards ExcludeTag to Test-NovaBuild and copies the NUnit and JaCoCo artifacts to the requested output directory' {
        $projectRoot = Join-Path $TestDrive 'project'
        $outputDirectory = Join-Path $TestDrive 'artifacts-out'
        $excludeTagLogPath = Join-Path $TestDrive 'exclude-tags.txt'
        $artifactsDir = Join-Path $projectRoot 'artifacts'
        $testResultPath = Join-Path $artifactsDir 'TestResults.xml'
        $coveragePath = Join-Path $artifactsDir 'coverage.xml'

        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
        Set-Content -LiteralPath $testResultPath -Value '<test-results />' -Encoding utf8
        Set-Content -LiteralPath $coveragePath -Value '<report />' -Encoding utf8

        $runnerContent = @"
function Import-Module {
    [CmdletBinding()]
    param(
        [string]`$Name,
        [switch]`$Force
    )
}

function Invoke-NovaBuild {}

function Get-NovaProjectInfo {
    return [pscustomobject]@{
        OutputModuleDir = '$projectRoot/dist/KeepAChangelog'
        ProjectName = 'KeepAChangelog'
        ProjectRoot = '$projectRoot'
    }
}

function Remove-Module {
    [CmdletBinding()]
    param([string]`$Name)
}

function Test-NovaBuild {
    [CmdletBinding()]
    param([string[]]`$ExcludeTagFilter)

    Set-Content -LiteralPath '$excludeTagLogPath' -Value (`$ExcludeTagFilter -join ',') -Encoding utf8
}

& '$script:novaModuleToolsCiScriptPath' -OutputDirectory '$outputDirectory' -ExcludeTag 'slow','integration'
"@
        $result = Invoke-NovaModuleToolsCIRunner -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        (Get-Content -LiteralPath $excludeTagLogPath -Raw).Trim() | Should -Be 'slow,integration'
        (Get-Content -LiteralPath (Join-Path $outputDirectory 'keepachangelog-nunit.xml') -Raw).Trim() | Should -Be '<test-results />'
        (Get-Content -LiteralPath (Join-Path $outputDirectory 'coverage.xml') -Raw).Trim() | Should -Be '<report />'
    }

    It 'returns a non-zero exit code after copying artifacts when Test-NovaBuild fails' {
        $projectRoot = Join-Path $TestDrive 'project-failure'
        $outputDirectory = Join-Path $TestDrive 'artifacts-out-failure'
        $artifactsDir = Join-Path $projectRoot 'artifacts'
        $testResultPath = Join-Path $artifactsDir 'TestResults.xml'
        $coveragePath = Join-Path $artifactsDir 'coverage.xml'

        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
        Set-Content -LiteralPath $testResultPath -Value '<failed-test-results />' -Encoding utf8
        Set-Content -LiteralPath $coveragePath -Value '<failed-report />' -Encoding utf8

        $runnerContent = @"
function Import-Module {
    [CmdletBinding()]
    param(
        [string]`$Name,
        [switch]`$Force
    )
}

function Invoke-NovaBuild {}

function Get-NovaProjectInfo {
    return [pscustomobject]@{
        OutputModuleDir = '$projectRoot/dist/KeepAChangelog'
        ProjectName = 'KeepAChangelog'
        ProjectRoot = '$projectRoot'
    }
}

function Remove-Module {
    [CmdletBinding()]
    param([string]`$Name)
}

function Test-NovaBuild {
    throw 'boom'
}

& '$script:novaModuleToolsCiScriptPath' -OutputDirectory '$outputDirectory'
"@
        $result = Invoke-NovaModuleToolsCIRunner -RunnerContent $runnerContent
        $outputText = $result.Output -join [Environment]::NewLine

        $result.ExitCode | Should -Be 1
        $outputText | Should -Match 'Test-NovaBuild failed: boom'
        (Get-Content -LiteralPath (Join-Path $outputDirectory 'keepachangelog-nunit.xml') -Raw).Trim() | Should -Be '<failed-test-results />'
        (Get-Content -LiteralPath (Join-Path $outputDirectory 'coverage.xml') -Raw).Trim() | Should -Be '<failed-report />'
    }
}
