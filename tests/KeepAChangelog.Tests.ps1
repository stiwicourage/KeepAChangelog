BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'KeepAChangelog.psd1') -Force
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

Describe 'Test-KeepAChangelogFile' {
    It 'returns a valid result for a generated changelog file' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -PreviousReleaseReference '1.0.0' `
            -Force | Out-Null

        $result = Test-KeepAChangelogFile -Path $path

        $result.IsValid | Should -BeTrue
        $result.PreviousReleaseReference | Should -Be '1.0.0'
    }

    It 'returns a valid result for a brand-new changelog without footer links' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -Force | Out-Null

        $result = Test-KeepAChangelogFile -Path $path

        $result.IsValid | Should -BeTrue
        $result.PreviousReleaseReference | Should -BeNullOrEmpty
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

    It 'reports missing footer links as invalid once releases exist' {
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

        $result.IsValid | Should -BeFalse
        $result.Errors | Should -Contain 'CHANGELOG.md must end with reference links once releases exist.'
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

    It 'requires RepositoryUrl for the first release when the changelog has no compare link yet' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        $errorMessage = $null

        @'
# Changelog

## [Unreleased]

### Added

- Initial release notes.
'@ | Set-Content -LiteralPath $path -Encoding utf8

        try {
            Move-UnreleasedChangelog -Path $path -Version '1.0.0' -Date '2026-05-01'
        } catch {
            $errorMessage = $_.Exception.Message
        }

        $errorMessage | Should -Be 'RepositoryUrl is required for the first release when CHANGELOG.md has no [Unreleased] compare link.'
    }

    It 'uses the version as the tag and the current date when Date is omitted' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        $currentDate = Get-Date -Format 'yyyy-MM-dd'

        Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -PreviousReleaseReference '1.0.0' `
            -Force | Out-Null

        $result = Move-UnreleasedChangelog -Path $path -Version '1.6.0'

        $result.Release.Tag | Should -Be '1.6.0'
        $result.Release.Date | Should -Be $currentDate
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
