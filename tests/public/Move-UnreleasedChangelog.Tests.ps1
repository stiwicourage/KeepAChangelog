function script:Initialize-TestChangelog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$PreviousReleaseReference
    )

    $parameters = @{
        Path          = $Path
        RepositoryUrl = 'https://github.com/example/repo'
        Force         = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($PreviousReleaseReference)) {
        $parameters.PreviousReleaseReference = $PreviousReleaseReference
    }

    Initialize-KeepAChangelogFile @parameters | Out-Null
}

function script:Set-ReleaseReadyChangelog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [pscustomobject]$LatestRelease
    )

    @"
# Changelog

## [Unreleased]

### Fixed

- Fixed CLI parsing.

## [$($LatestRelease.Version)] - $($LatestRelease.Date)

### Added

$($LatestRelease.Note)

[Unreleased]: https://github.com/example/repo/compare/$($LatestRelease.Version)...HEAD
[$($LatestRelease.Version)]: https://github.com/example/repo/compare/$($LatestRelease.PreviousVersion)...$($LatestRelease.Version)
"@ | Set-Content -LiteralPath $Path -Encoding utf8
}

function script:Get-ReferenceFooterText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$LineList,
        [switch]$SeparateWithBlankLines
    )

    $separator = if ($SeparateWithBlankLines) { "`n`n" } else { "`n" }
    return $LineList -join $separator
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/initialize/*.ps1'
        'src/private/shared/*.ps1'
        'src/private/validation/*.ps1'
        'src/private/release/*.ps1'
        'src/public/Initialize-KeepAChangelogFile.ps1'
        'src/public/Convert-ChangelogReleaseNotesToTagMessage.ps1'
        'src/public/Get-KeepAChangelogVersion.ps1'
        'src/public/Move-UnreleasedChangelog.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Move-UnreleasedChangelog' {
    It 'moves unreleased notes into a release section, clears Unreleased, and updates compare links' {
        $caseList = @(
            @{
                Name                   = 'compact-footer'
                SeparateWithBlankLines = $false
            }
            @{
                Name                   = 'spaced-footer'
                SeparateWithBlankLines = $true
            }
        )

        foreach ($case in $caseList) {
            $path = Join-Path $TestDrive "CHANGELOG-$($case.Name).md"
            $footer = Get-ReferenceFooterText `
                -LineList @(
                    '[Unreleased]: https://github.com/example/repo/compare/1.5.0...HEAD'
                    '[1.5.0]: https://github.com/example/repo/compare/1.4.0...1.5.0'
                ) `
                -SeparateWithBlankLines:$case.SeparateWithBlankLines

            @"
# Changelog

## [Unreleased]

### Added

### Fixed

- Fixed CLI parsing.

## [1.5.0] - 2026-04-10

### Added

- Previous release notes.

$footer
"@ | Set-Content -LiteralPath $path -Encoding utf8

            $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date '2026-04-30'
            $updated = Get-Content -LiteralPath $path -Raw

            $result.ReleaseNotesBody | Should -Be "### Fixed`n`n- Fixed CLI parsing."
            $result.ClearedUnreleasedBody | Should -Be "### Added`n`n### Fixed"
            $result.PreviousReleaseReference | Should -Be '1.5.0'
            $result.NewReleaseCompareLink | Should -Be 'https://github.com/example/repo/compare/1.5.0...1.6.0'
            $result.TagMessageText | Should -Be "Fixed`n`nFixed CLI parsing."
            $updated | Should -Match '## \[1\.6\.0\] - 2026-04-30'
            $updated | Should -Match '(?s)## \[1\.6\.0\] - 2026-04-30\s+### Fixed\s+- Fixed CLI parsing\.\s+## \[1\.5\.0\] - 2026-04-10'
            $updated | Should -Match '(?s)## \[Unreleased\]\s+### Added\s+### Fixed'
            $updated | Should -Match '\[Unreleased\]: https://github\.com/example/repo/compare/1\.6\.0\.\.\.HEAD'
            $updated | Should -Match '\[1\.6\.0\]: https://github\.com/example/repo/compare/1\.5\.0\.\.\.1\.6\.0'
            $result.KeepAChangelogVersion | Should -Be (Get-KeepAChangelogVersion)
        }
    }

    It 'supports simple unreleased notes without subsection headings' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

- Fixed CLI parsing.

## [1.5.0] - 2026-04-10

### Added

- Previous release notes.

[Unreleased]: https://github.com/example/repo/compare/1.5.0...HEAD
[1.5.0]: https://github.com/example/repo/compare/1.4.0...1.5.0
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date '2026-04-30'
        $updated = Get-Content -LiteralPath $path -Raw

        $result.ReleaseNotesBody | Should -Be '- Fixed CLI parsing.'
        $result.ClearedUnreleasedBody | Should -Be ''
        $updated | Should -Match '(?s)## \[Unreleased\]\s+## \[1\.6\.0\] - 2026-04-30'
        $updated | Should -Match '(?s)## \[1\.6\.0\] - 2026-04-30\s+- Fixed CLI parsing\.'
    }

    It 'does not duplicate an existing release compare link' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Fixed

- Fixed CLI parsing.

## [1.5.0] - 2026-04-10

### Added

- Previous release notes.

[Unreleased]: https://github.com/example/repo/compare/1.5.0...HEAD
[1.6.0]: https://github.com/example/repo/compare/1.5.0...1.6.0
[1.5.0]: https://github.com/example/repo/compare/1.4.0...1.5.0
'@ | Set-Content -LiteralPath $path -Encoding utf8

        Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date '2026-04-30' | Out-Null

        $updated = Get-Content -LiteralPath $path -Raw

        ([regex]::Matches($updated, '(?m)^\[1\.6\.0\]:').Count) | Should -Be 1
    }

    It 'reuses the last remaining release reference when the same version is released again' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Fixed

- Release notes moved back for editing.

## [0.0.1] - 2026-05-01

### Added

- Initial release.

[Unreleased]: https://github.com/example/repo/compare/0.1.0...HEAD
[0.0.1]: https://github.com/example/repo/compare/develop...0.0.1
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Move-UnreleasedChangelog -Path $path -Version '0.1.0' -Date '2026-05-04'
        $updated = Get-Content -LiteralPath $path -Raw

        $result.PreviousReleaseReference | Should -Be '0.0.1'
        $result.NewReleaseCompareLink | Should -Be 'https://github.com/example/repo/compare/0.0.1...0.1.0'
        $updated | Should -Match '\[Unreleased\]: https://github\.com/example/repo/compare/0\.1\.0\.\.\.HEAD'
        $updated | Should -Match '\[0\.1\.0\]: https://github\.com/example/repo/compare/0\.0\.1\.\.\.0\.1\.0'
        $updated | Should -Not -Match '\[0\.1\.0\]: https://github\.com/example/repo/compare/0\.1\.0\.\.\.0\.1\.0'
    }

    It 'adds footer links on the first release when RepositoryUrl is provided' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Added

- Initial release notes.
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Move-UnreleasedChangelog `
            -Path $path `
            -Version '1.0.0' `
            -Date '2026-05-01' `
            -RepositoryUrl 'https://github.com/example/repo'
        $updated = Get-Content -LiteralPath $path -Raw

        $result.PreviousReleaseReference | Should -BeNullOrEmpty
        $result.NewReleaseCompareLink | Should -Be 'https://github.com/example/repo/releases/tag/1.0.0'
        $result.NewReleaseLink | Should -Be 'https://github.com/example/repo/releases/tag/1.0.0'
        $updated | Should -Match '\[Unreleased\]: https://github\.com/example/repo/compare/1\.0\.0\.\.\.HEAD'
        $updated | Should -Match '\[1\.0\.0\]: https://github\.com/example/repo/releases/tag/1\.0\.0'
    }

    It 'keeps footer links omitted when RepositoryUrl is omitted on the first release' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Added

- Initial release notes.
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Move-UnreleasedChangelog -Path $path -Version '1.0.0' -Date '2026-05-01'
        $updated = Get-Content -LiteralPath $path -Raw

        $result.UpdatedUnreleasedLink | Should -BeNullOrEmpty
        $result.NewReleaseCompareLink | Should -BeNullOrEmpty
        $result.NewReleaseLink | Should -BeNullOrEmpty
        $updated | Should -Not -Match '(?m)^\[Unreleased\]:'
        $updated | Should -Not -Match '(?m)^\[1\.0\.0\]:'
    }

    It 'keeps footer links omitted when releasing a changelog that already has releases but no footer' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Fixed

- Follow-up release notes.

## [1.5.0] - 2026-04-10

### Added

- Previous release notes.
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date '2026-04-30'
        $updated = Get-Content -LiteralPath $path -Raw

        $result.UpdatedUnreleasedLink | Should -BeNullOrEmpty
        $result.NewReleaseCompareLink | Should -BeNullOrEmpty
        $result.NewReleaseLink | Should -BeNullOrEmpty
        $updated | Should -Match '## \[1\.6\.0\] - 2026-04-30'
        $updated | Should -Not -Match '(?m)^\[Unreleased\]:'
        $updated | Should -Not -Match '(?m)^\[1\.6\.0\]:'
    }

    It 'uses the version as the tag and the current date when Date is omitted' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        $currentDate = Get-Date -Format 'yyyy-MM-dd'

        Initialize-TestChangelog -Path $path -PreviousReleaseReference '1.0.0'

        $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0'

        $result.Release.Tag | Should -Be '1.6.0'
        $result.Release.Date | Should -Be $currentDate
    }

    It 'enforces release date ordering against the latest existing release' {
        $caseList = @(
            @{
                Name            = 'earlier-date'
                ReleaseDate     = '2026-05-01'
                ExpectedMessage = "Release.Date '2026-05-01' cannot be earlier than latest existing release date '2026-05-02'."
                ShouldThrow     = $true
            }
            @{
                Name         = 'equal-date'
                ReleaseDate  = '2026-05-02'
                ExpectedDate = '2026-05-02'
                ShouldThrow  = $false
            }
        )

        foreach ($case in $caseList) {
            $path = Join-Path $TestDrive "CHANGELOG-$($case.Name).md"
            Set-ReleaseReadyChangelog `
                -Path $path `
                -LatestRelease ([pscustomobject]@{
                    Version         = '1.5.0'
                    Date            = '2026-05-02'
                    PreviousVersion = '1.4.0'
                    Note            = '- Previous release notes.'
                })

            if ($case.ShouldThrow) {
                {
                    Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date $case.ReleaseDate
                } | Should -Throw $case.ExpectedMessage
                continue
            }

            $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date $case.ReleaseDate
            $result.Release.Date | Should -Be $case.ExpectedDate
        }
    }

    It 'rejects the resolved current date when it is earlier than the latest existing release date' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        $currentDate = Get-Date -Format 'yyyy-MM-dd'

        Set-ReleaseReadyChangelog `
            -Path $path `
            -LatestRelease ([pscustomobject]@{
                Version         = '9.9.9'
                Date            = '2999-01-01'
                PreviousVersion = '9.9.8'
                Note            = '- Future release placeholder.'
            })

        {
            Move-UnreleasedChangelog -Path $path -Version '10.0.0'
        } | Should -Throw "Release.Date '$currentDate' cannot be earlier than latest existing release date '2999-01-01'."
    }

    It 'rejects an explicit Date with the wrong format' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -PreviousReleaseReference '1.0.0' `
            -Force | Out-Null

        {
            Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date '05-02-2026'
        } | Should -Throw "Date must use yyyy-MM-dd format. Received: '05-02-2026'."
    }

    It 'throws when Version is blank' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        Initialize-KeepAChangelogFile -Path $path -RepositoryUrl 'https://github.com/example/repo' -Force | Out-Null

        {
            Move-UnreleasedChangelog -Path $path -Version '   '
        } | Should -Throw 'Version is required.'
    }

    It 'throws when the target file is missing' {
        $path = Join-Path $TestDrive 'missing.md'

        {
            Move-UnreleasedChangelog -Path $path -Version '1.0.0'
        } | Should -Throw "Could not find CHANGELOG file at '$path'."
    }

    It 'returns preview data without writing changes when WhatIf is used' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Fixed

- Fixed CLI parsing.

## [1.5.0] - 2026-04-10

### Added

- Previous release notes.

[Unreleased]: https://github.com/example/repo/compare/1.5.0...HEAD
[1.5.0]: https://github.com/example/repo/compare/1.4.0...1.5.0
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $before = Get-Content -LiteralPath $path -Raw

        $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date '2026-04-30' -WhatIf
        $after = Get-Content -LiteralPath $path -Raw

        $result.Release.Version | Should -Be '1.6.0'
        $result.KeepAChangelogVersion | Should -Be (Get-KeepAChangelogVersion)
        $after | Should -Be $before
    }
}
