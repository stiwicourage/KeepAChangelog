BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Assert-KeepAChangelogReleaseDateOrder.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Assert-KeepAChangelogReleaseDateOrder' {
    It 'returns the latest existing release date from the changelog body' {
        $result = Get-KeepAChangelogLatestReleaseDate -Body @'
## [Unreleased]

## [1.1.0] - 2026-05-02

## [1.0.0] - 2026-05-01
'@

        $result | Should -Be '2026-05-02'
    }

    It 'returns null when no released versions exist yet' {
        $result = Get-KeepAChangelogLatestReleaseDate -Body @'
## [Unreleased]

### Added
'@

        $result | Should -BeNullOrEmpty
    }

    It 'allows first-release date ordering when no previous release exists' {
        {
            Assert-KeepAChangelogReleaseDateOrder -Body '## [Unreleased]' -Release ([pscustomobject]@{
                Date = '2026-05-03'
            })
        } | Should -Not -Throw
    }

    It 'throws when the new release date is earlier than the latest existing release date' {
        {
            Assert-KeepAChangelogReleaseDateOrder -Body @'
## [Unreleased]

## [1.1.0] - 2026-05-02
'@ -Release ([pscustomobject]@{
                Date = '2026-05-01'
            })
        } | Should -Throw "Release.Date '2026-05-01' cannot be earlier than latest existing release date '2026-05-02'."
    }
}
