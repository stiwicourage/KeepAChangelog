BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..' 'src' 'KeepAChangelog.psd1') -Force
}

Describe 'New-KeepAChangelogFile' {
    It 'creates a changelog template with standard headings and an Unreleased compare link when PreviousReleaseReference is provided' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        $result = New-KeepAChangelogFile `
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

        $result = New-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -Force
        $text = Get-Content -LiteralPath $path -Raw

        $result.PreviousReleaseReference | Should -BeNullOrEmpty
        $text | Should -Match '## \[Unreleased\]'
        $text | Should -Not -Match '(?m)^\[Unreleased\]:'
    }
}

Describe 'Test-KeepAChangelogFile' {
    It 'returns a valid result for a generated changelog file' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        New-KeepAChangelogFile `
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

        New-KeepAChangelogFile `
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

Describe 'Publish-KeepAChangelogRelease' {
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

        $release = @{
            Version = '1.6.0'
            Date    = '2026-04-30'
            Tag     = '1.6.0'
        }

        $result = Publish-KeepAChangelogRelease -Path $path -Release $release
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

        $release = @{
            Version = '1.6.0'
            Date    = '2026-04-30'
            Tag     = '1.6.0'
        }

        $result = Publish-KeepAChangelogRelease -Path $path -Release $release
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

        Publish-KeepAChangelogRelease -Path $path -Release @{
            Version = '1.6.0'
            Date    = '2026-04-30'
            Tag     = '1.6.0'
        } | Out-Null

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

        $result = Publish-KeepAChangelogRelease `
            -Path $path `
            -Release @{
                Version = '1.0.0'
                Date    = '2026-05-01'
                Tag     = '1.0.0'
            } `
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
            Publish-KeepAChangelogRelease -Path $path -Release @{
                Version = '1.0.0'
                Date    = '2026-05-01'
                Tag     = '1.0.0'
            }
        } catch {
            $errorMessage = $_.Exception.Message
        }

        $errorMessage | Should -Be 'RepositoryUrl is required for the first release when CHANGELOG.md has no [Unreleased] compare link.'
    }

    It 'requires release version, date, and tag' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        New-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -PreviousReleaseReference '1.0.0' `
            -Force | Out-Null

        {
            Publish-KeepAChangelogRelease -Path $path -Release @{
                Version = '1.6.0'
                Date    = '2026-04-30'
            }
        } | Should -Throw 'Release.Tag is required.'
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
