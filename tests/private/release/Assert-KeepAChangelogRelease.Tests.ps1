BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Assert-KeepAChangelogRelease.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Assert-KeepAChangelogRelease' {
    It 'returns a normalized release object for valid input' {
        $result = Assert-KeepAChangelogRelease -Release @{
            Version = '1.0.0'
            Date    = '2026-05-03'
            Tag     = '1.0.0'
        }

        $result.Version | Should -Be '1.0.0'
        $result.Date | Should -Be '2026-05-03'
        $result.Tag | Should -Be '1.0.0'
        $result.Reference | Should -Be '1.0.0'
    }

    It 'validates required release fields' {
        $caseList = @(
            @{
                Release = @{
                    Version = '1.0.0'
                    Tag     = '1.0.0'
                }
                ExpectedMessage = 'Release.Date is required.'
            }
            @{
                Release = @{
                    Version = '1.0.0'
                    Date    = '2026-05-03'
                    Tag     = '   '
                }
                ExpectedMessage = 'Release.Tag is required.'
            }
        )

        foreach ($case in $caseList) {
            {
                Assert-KeepAChangelogRelease -Release $case.Release
            } | Should -Throw $case.ExpectedMessage
        }
    }
}
