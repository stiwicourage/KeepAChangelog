BeforeAll {
    & (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'Import-BuiltCiModule.ps1') | Out-Null
}

Describe 'Public command guard clauses' {
    It 'throws when Test-KeepAChangelogFile target file is missing' {
        {
            Test-KeepAChangelogFile -Path (Join-Path $TestDrive 'missing.md')
        } | Should -Throw "Could not find CHANGELOG file at '$(Join-Path $TestDrive 'missing.md')'."
    }

    It 'throws when Initialize-KeepAChangelogFile RepositoryUrl is blank' {
        {
            Initialize-KeepAChangelogFile -Path (Join-Path $TestDrive 'CHANGELOG.md') -RepositoryUrl '   '
        } | Should -Throw 'RepositoryUrl is required.'
    }

    It 'throws when Initialize-KeepAChangelogFile would overwrite an existing file without Force' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        '# Changelog' | Set-Content -LiteralPath $path -Encoding utf8

        {
            Initialize-KeepAChangelogFile -Path $path -RepositoryUrl 'https://github.com/example/repo'
        } | Should -Throw "File already exists at '$path'. Use -Force to overwrite it."
    }

    It 'throws when Move-UnreleasedChangelog version is blank' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        Initialize-KeepAChangelogFile -Path $path -RepositoryUrl 'https://github.com/example/repo' -Force | Out-Null

        {
            Move-UnreleasedChangelog -Path $path -Version '   '
        } | Should -Throw 'Version is required.'
    }

    It 'throws when Move-UnreleasedChangelog target file is missing' {
        $path = Join-Path $TestDrive 'missing.md'

        {
            Move-UnreleasedChangelog -Path $path -Version '1.0.0'
        } | Should -Throw "Could not find CHANGELOG file at '$path'."
    }

    It 'returns preview data without writing changes when Move-UnreleasedChangelog uses WhatIf' {
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
        $after | Should -Be $before
    }
}

Describe 'Private helper coverage' {
    It 'throws when a required release key is missing' {
        InModuleScope KeepAChangelog {
            {
                Assert-KeepAChangelogRelease -Release @{
                    Version = '1.0.0'
                    Tag     = '1.0.0'
                }
            } | Should -Throw 'Release.Date is required.'
        }
    }

    It 'throws when a required release value is blank' {
        InModuleScope KeepAChangelog {
            {
                Assert-KeepAChangelogRelease -Release @{
                    Version = '1.0.0'
                    Date    = '2026-05-03'
                    Tag     = '   '
                }
            } | Should -Throw 'Release.Tag is required.'
        }
    }

    It 'returns an empty string for whitespace-only release notes' {
        InModuleScope KeepAChangelog {
            (Get-ChangelogReleaseNotesBody -Body " `n`t ") | Should -Be ''
        }
    }

    It 'throws when the Unreleased section is missing' {
        InModuleScope KeepAChangelog {
            $errorMessage = $null

            try {
                Get-UnreleasedSectionMatch -Text '# Changelog'
            }
            catch {
                $errorMessage = $_.Exception.Message
            }

            $errorMessage | Should -Be 'Could not find ## [Unreleased] section in CHANGELOG.md.'
        }
    }

    It 'throws when release resolution starts from an invalid changelog' {
        InModuleScope KeepAChangelog {
            $errorMessage = $null

            try {
                Resolve-KeepAChangelogReleaseData -Text '# Changelog' -Release @{
                    Version = '1.0.0'
                    Date    = '2026-05-03'
                    Tag     = '1.0.0'
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
            }

            $errorMessage | Should -Be 'CHANGELOG.md is not valid. Could not find ## [Unreleased] section in CHANGELOG.md.'
        }
    }

    It 'derives the release link from the compare prefix when RepositoryUrl is omitted' {
        InModuleScope KeepAChangelog {
            $result = Get-UpdatedChangelogReferenceFooter `
                -Footer '' `
                -ReleaseVersion '1.0.0' `
                -ReleaseTag '1.0.0' `
                -UnreleasedCompareLinkPrefix 'https://github.com/example/repo/compare/' `
                -PreviousReleaseReference ''

            $result.Footer | Should -Be "[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD`n[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0"
        }
    }

    It 'preserves plain text and trims trailing blank lines in tag messages' {
        $result = Convert-ChangelogReleaseNotesToTagMessage -ReleaseNotes "Plain text line`n`n"

        $result | Should -Be 'Plain text line'
    }
}

Describe 'Validation result edge cases' {
    It 'reports release sections that do not use the required heading format' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## [Unreleased]

### Added

## [1.0.0]

### Added

- Initial release.

[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD
[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0
'@

            $result.Errors | Should -Contain "Release section '## [1.0.0]' must use '## [<version>] - <date>' format."
        }
    }

    It 'reports duplicate release sections' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## [Unreleased]

### Added

## [1.0.0] - 2026-04-30

### Added

- Initial release.

## [1.0.0] - 2026-04-29

### Fixed

- Duplicate release section.

[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD
[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0
'@

            $result.Errors | Should -Contain 'Release section [1.0.0] is duplicated.'
        }
    }

    It 'reports duplicate footer reference links' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## [Unreleased]

### Added

## [1.0.0] - 2026-04-30

### Added

- Initial release.

[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD
[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0
[1.0.0]: https://github.com/example/repo/compare/0.9.0...1.0.0
'@

            $result.Errors | Should -Contain 'Reference link [1.0.0] is duplicated.'
        }
    }

    It 'reports a missing Unreleased compare link when footer links exist' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## [Unreleased]

### Added

## [1.0.0] - 2026-04-30

### Added

- Initial release.

[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0
'@

            $result.Errors | Should -Contain 'Could not find an [Unreleased] compare link in CHANGELOG.md.'
        }
    }

    It 'reports multiple Unreleased compare links' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## [Unreleased]

### Added

## [1.0.0] - 2026-04-30

### Added

- Initial release.

[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD
[Unreleased]: https://github.com/example/repo/compare/main...HEAD
[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0
'@

            $result.Errors | Should -Contain 'CHANGELOG.md must contain exactly one [Unreleased] compare link.'
        }
    }
}
