BeforeAll {
    & (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'Import-BuiltCiModule.ps1') | Out-Null
    $script:InitializeTestChangelog = {
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

    $script:SetReleaseReadyChangelog = {
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
}

Describe 'Initialize-KeepAChangelogFile' {
    It 'creates a changelog template with standard headings and an Unreleased compare link when PreviousReleaseReference is provided' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        $result = Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -PreviousReleaseReference '1.0.0'
        $text = Get-Content -LiteralPath $path -Raw

        $result.Path | Should -Be $path
        $text | Should -Match '## \[Unreleased\]'
        $text | Should -Match '### Added'
        $text | Should -Match '### Security'
        $text | Should -Match '\[Unreleased\]: https://github\.com/example/repo/compare/1\.0\.0\.\.\.HEAD'
    }

    It 'creates a changelog template without footer links when PreviousReleaseReference is omitted' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        $result = Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -Force
        $text = Get-Content -LiteralPath $path -Raw

        $result.PreviousReleaseReference | Should -BeNullOrEmpty
        $text | Should -Match '## \[Unreleased\]'
        $text | Should -Not -Match '(?m)^\[Unreleased\]:'
    }

    It 'accepts develop as PreviousReleaseReference for projects without tags yet' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        $result = Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -PreviousReleaseReference 'develop' `
            -Force
        $text = Get-Content -LiteralPath $path -Raw

        $result.PreviousReleaseReference | Should -Be 'develop'
        $text | Should -Match '\[Unreleased\]: https://github\.com/example/repo/compare/develop\.\.\.HEAD'
    }

    It 'does not export the old New-KeepAChangelogFile command name' {
        { Get-Command -Name New-KeepAChangelogFile -ErrorAction Stop } | Should -Throw
    }
}

Describe 'Get-KeepAChangelogVersion' {
    It 'returns the loaded KeepAChangelog module version' {
        $result = Get-KeepAChangelogVersion

        $result | Should -Be ((Get-Module KeepAChangelog).Version.ToString())
    }
}

Describe 'Test-KeepAChangelogFile' {
    It 'returns a valid result for initialized changelog variants' {
        $caseList = @(
            @{
                PreviousReleaseReference = '1.0.0'
                ExpectedReference        = '1.0.0'
            }
            @{
                PreviousReleaseReference = $null
                ExpectedReference        = $null
            }
        )

        foreach ($case in $caseList) {
            $path = Join-Path $TestDrive "CHANGELOG-$($case.ExpectedReference ?? 'new').md"
            & $script:InitializeTestChangelog -Path $path -PreviousReleaseReference $case.PreviousReleaseReference
            $result = Test-KeepAChangelogFile -Path $path

            $result.IsValid | Should -BeTrue
            if ($null -eq $case.ExpectedReference) {
                $result.PreviousReleaseReference | Should -BeNullOrEmpty
                continue
            }

            $result.PreviousReleaseReference | Should -Be $case.ExpectedReference
        }
    }

    It 'reports a missing Unreleased section as invalid' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [1.0.0] - 2026-04-30

### Added

- Initial release.

[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD
[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Test-KeepAChangelogFile -Path $path

        $result.IsValid | Should -BeFalse
        $result.Errors | Should -Contain 'Could not find ## [Unreleased] section in CHANGELOG.md.'
    }

    It 'accepts release sections without footer links' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Added

## [1.0.0] - 2026-04-30

### Added

- Initial release.
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Test-KeepAChangelogFile -Path $path

        $result.IsValid | Should -BeTrue
        @($result.Errors).Count | Should -Be 0
        $result.UnreleasedCompareLinkPrefix | Should -BeNullOrEmpty
        $result.PreviousReleaseReference | Should -BeNullOrEmpty
        @($result.ReleaseVersions) | Should -Be @('1.0.0')
    }

    It 'accepts yanked release headings that follow the Keep a Changelog format' {
        $path = Join-Path $TestDrive 'CHANGELOG-YANKED.md'

        @'
# Changelog

## [Unreleased]

### Added

## [2.2.0] - 2026-05-06 [YANKED]

### Fixed

- Yanked because of a release regression.

[Unreleased]: https://github.com/example/repo/compare/2.2.0...HEAD
[2.2.0]: https://github.com/example/repo/releases/tag/2.2.0
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Test-KeepAChangelogFile -Path $path

        $result.IsValid | Should -BeTrue
        $result.Errors.Count | Should -Be 0
        @($result.ReleaseVersions) | Should -Be @('2.2.0')
        $result.PreviousReleaseReference | Should -Be '2.2.0'
    }

    It 'throws the validation errors when ThrowOnError is used' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        $errorMessage = $null

        @'
# Changelog
'@ | Set-Content -LiteralPath $path -Encoding utf8

        try {
            Test-KeepAChangelogFile -Path $path -ThrowOnError
        }
        catch {
            $errorMessage = $_.Exception.Message
        }

        $errorMessage | Should -Be 'Could not find ## [Unreleased] section in CHANGELOG.md.'
    }
}

Describe 'Move-UnreleasedChangelog' {
    It 'moves unreleased notes into a release section, clears Unreleased, and updates compare links' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Added

### Fixed

- Fixed CLI parsing.

## [1.5.0] - 2026-04-10

### Added

- Previous release notes.

[Unreleased]: https://github.com/example/repo/compare/1.5.0...HEAD
[1.5.0]: https://github.com/example/repo/compare/1.4.0...1.5.0
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0' -Date '2026-04-30'
        $updated = Get-Content -LiteralPath $path -Raw

        $result.ReleaseNotesBody | Should -Be "### Fixed`n`n- Fixed CLI parsing."
        $result.ClearedUnreleasedBody | Should -Be "### Added`n`n### Fixed"
        $result.TagMessageText | Should -Be "Fixed`n`nFixed CLI parsing."
        $updated | Should -Match '## \[1\.6\.0\] - 2026-04-30'
        $updated | Should -Match '(?s)## \[1\.6\.0\] - 2026-04-30\s+### Fixed\s+- Fixed CLI parsing\.\s+## \[1\.5\.0\] - 2026-04-10'
        $updated | Should -Match '(?s)## \[Unreleased\]\s+### Added\s+### Fixed'
        $updated | Should -Match '\[Unreleased\]: https://github\.com/example/repo/compare/1\.6\.0\.\.\.HEAD'
        $updated | Should -Match '\[1\.6\.0\]: https://github\.com/example/repo/compare/1\.5\.0\.\.\.1\.6\.0'
        $result.KeepAChangelogVersion | Should -Be (Get-KeepAChangelogVersion)
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

    It 'adds footer links on the first release when the changelog started without a previous release reference' {
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

        & $script:InitializeTestChangelog -Path $path -PreviousReleaseReference '1.0.0'

        $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0'

        $result.Release.Tag | Should -Be '1.6.0'
        $result.Release.Date | Should -Be $currentDate
    }

    It 'enforces release date ordering against the latest existing release' {
        $caseList = @(
            @{
                Name             = 'earlier date'
                ReleaseDate      = '2026-05-01'
                ExpectedMessage  = "Release.Date '2026-05-01' cannot be earlier than latest existing release date '2026-05-02'."
                ShouldThrow      = $true
            }
            @{
                Name             = 'equal date'
                ReleaseDate      = '2026-05-02'
                ExpectedDate     = '2026-05-02'
                ShouldThrow      = $false
            }
        )

        foreach ($case in $caseList) {
            $path = Join-Path $TestDrive "CHANGELOG-$($case.Name -replace ' ', '-').md"
            & $script:SetReleaseReadyChangelog `
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
        $errorMessage = $null

        & $script:SetReleaseReadyChangelog `
            -Path $path `
            -LatestRelease ([pscustomobject]@{
                Version         = '9.9.9'
                Date            = '2999-01-01'
                PreviousVersion = '9.9.8'
                Note            = '- Future release placeholder.'
            })

        try {
            Move-UnreleasedChangelog -Path $path -Version '10.0.0'
        }
        catch {
            $errorMessage = $_.Exception.Message
        }

        $errorMessage | Should -Be "Release.Date '$currentDate' cannot be earlier than latest existing release date '2999-01-01'."
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
}

Describe 'Convert-ChangelogReleaseNotesToTagMessage' {
    It 'converts markdown release notes to plain text' {
        $releaseNotes = @'
### Fixed

- Fixed CLI parsing.
- Fixed release note formatting.
'@

        $result = Convert-ChangelogReleaseNotesToTagMessage -ReleaseNotes $releaseNotes

        $result | Should -Be "Fixed`n`nFixed CLI parsing.`nFixed release note formatting."
    }
}

Describe 'Get-UnreleasedCompareLinkMatch' {
    It 'extracts the compare prefix and previous release reference' {
        InModuleScope KeepAChangelog {
            $match = Get-UnreleasedCompareLinkMatch -Text @'
# Changelog

## [Unreleased]

[Unreleased]: https://github.com/example/repo/compare/1.5.0...HEAD
'@

            $match.Success | Should -BeTrue
            $match.Groups['prefix'].Value | Should -Be 'https://github.com/example/repo/compare/'
            $match.Groups['from'].Value | Should -Be '1.5.0'
        }
    }

    It 'throws when the Unreleased compare link is missing' {
        InModuleScope KeepAChangelog {
            $errorMessage = $null

            try {
                Get-UnreleasedCompareLinkMatch -Text @'
# Changelog

## [Unreleased]
'@
            }
            catch {
                $errorMessage = $_.Exception.Message
            }

            $errorMessage | Should -Be 'Could not find an [Unreleased] compare link in CHANGELOG.md.'
        }
    }
}
