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
        $result.KeepAChangelogVersion | Should -Be (Get-KeepAChangelogVersion)
        $after | Should -Be $before
    }
}

Describe 'Private helper coverage' {
    It 'returns the loaded module version through the public version cmdlet' {
        $result = Get-KeepAChangelogVersion

        $result | Should -Be ((Get-Module KeepAChangelog).Version.ToString())
    }

    It 'validates required release fields' {
        InModuleScope KeepAChangelog {
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
                -Release ([pscustomobject]@{
                    Version = '1.0.0'
                    Tag     = '1.0.0'
                }) `
                -Context ([pscustomobject]@{
                    RepositoryUrl               = $null
                    UnreleasedCompareLinkPrefix = 'https://github.com/example/repo/compare/'
                    PreviousReleaseReference    = ''
                })

            $result.Footer | Should -Be "[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD`n[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0"
        }
    }

    It 'preserves plain text and trims trailing blank lines in tag messages' {
        $result = Convert-ChangelogReleaseNotesToTagMessage -ReleaseNotes "Plain text line`n`n"

        $result | Should -Be 'Plain text line'
    }

    It 'does not add blank tag-message lines when blank lines are not allowed yet' {
        InModuleScope KeepAChangelog {
            $lineList = [System.Collections.Generic.List[string]]::new()

            $result = Add-ChangelogTagMessageBlankLine -LineList $lineList -AllowBlankLine $false

            $result | Should -BeFalse
            $lineList.Count | Should -Be 0
        }
    }

    It 'normalizes tag-message lines for headings, bullets, and plain text' {
        InModuleScope KeepAChangelog {
            (Get-ChangelogTagMessageLine -TrimmedLine '### Fixed') | Should -Be 'Fixed'
            (Get-ChangelogTagMessageLine -TrimmedLine '- Fixed CLI parsing.') | Should -Be 'Fixed CLI parsing.'
            (Get-ChangelogTagMessageLine -TrimmedLine 'Plain text line') | Should -Be 'Plain text line'
        }
    }

    It 'removes trailing blank tag-message lines' {
        InModuleScope KeepAChangelog {
            $lineList = [System.Collections.Generic.List[string]]::new()
            $null = $lineList.Add('Fixed')
            $null = $lineList.Add('')
            $null = $lineList.Add(' ')

            $lineList = Get-TrimmedChangelogTagMessageLineList -LineList $lineList

            $lineList | Should -Be @('Fixed')
        }
    }

    It 'extracts the target from release tag links' {
        InModuleScope KeepAChangelog {
            $result = Get-ChangelogReleaseTargetReference -Link 'https://github.com/example/repo/releases/tag/1.0.0'

            $result | Should -Be '1.0.0'
        }
    }

    It 'returns null when a link is not a compare or tag link' {
        InModuleScope KeepAChangelog {
            $result = Get-ChangelogReleaseTargetReference -Link 'https://github.com/example/repo/issues/123'

            $result | Should -BeNullOrEmpty
        }
    }

    It 'returns null when no usable previous release reference can be recovered' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogPreviousReleaseReference `
                -Footer @'
[0.9.0]: https://github.com/example/repo/releases/tag/1.0.0
'@ `
                -Validation ([pscustomobject]@{
                    PreviousReleaseReference = '1.0.0'
                    ReleaseVersions          = @('0.9.0')
                }) `
                -Release ([pscustomobject]@{
                    Tag = '1.0.0'
                })

            $result | Should -BeNullOrEmpty
        }
    }

    It 'returns the latest existing release date from the changelog body' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogLatestReleaseDate -Body @'
## [Unreleased]

## [1.1.0] - 2026-05-02

## [1.0.0] - 2026-05-01
'@

            $result | Should -Be '2026-05-02'
        }
    }

    It 'returns null when no released versions exist yet' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogLatestReleaseDate -Body @'
## [Unreleased]

### Added
'@

            $result | Should -BeNullOrEmpty
        }
    }

    It 'allows first-release date ordering when no previous release exists' {
        InModuleScope KeepAChangelog {
            {
                Assert-KeepAChangelogReleaseDateOrder -Body '## [Unreleased]' -Release ([pscustomobject]@{
                    Date = '2026-05-03'
                })
            } | Should -Not -Throw
        }
    }

    It 'returns the current module version from the shared helper' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogModuleVersion

            $result | Should -Be ((Get-Module KeepAChangelog).Version.ToString())
        }
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

            $result.Errors | Should -Contain "Release section '## [1.0.0]' must use '## [<version>] - <date>' format, optionally followed by ' [YANKED]'."
        }
    }

    It 'accepts yanked release sections that follow the Keep a Changelog heading format' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## [Unreleased]

### Added

## [1.0.0] - 2026-04-30 [YANKED]

### Fixed

- Yanked because of a release regression.

[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD
[1.0.0]: https://github.com/example/repo/releases/tag/1.0.0
'@

            $result.IsValid | Should -BeTrue
            $result.Errors.Count | Should -Be 0
            @($result.ReleaseVersions) | Should -Be @('1.0.0')
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

    It 'accepts release sections when no footer reference links are present' {
        InModuleScope KeepAChangelog {
            $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## [Unreleased]

### Added

## [1.0.0] - 2026-04-30

### Added

- Initial release.
'@

            $result.IsValid | Should -BeTrue
            @($result.Errors).Count | Should -Be 0
            $result.UnreleasedCompareLinkPrefix | Should -BeNullOrEmpty
            $result.PreviousReleaseReference | Should -BeNullOrEmpty
            @($result.ReleaseVersions) | Should -Be @('1.0.0')
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

    It 'returns an empty footer update when no footer links should be written' {
        InModuleScope KeepAChangelog {
            $result = Get-UpdatedChangelogReferenceFooter `
                -Footer '' `
                -Release ([pscustomobject]@{
                    Tag     = '1.0.0'
                    Version = '1.0.0'
                }) `
                -Context ([pscustomobject]@{
                    ShouldWriteReferenceFooter = $false
                })

            $result.Footer | Should -Be ''
            $result.UpdatedUnreleasedLink | Should -BeNullOrEmpty
            $result.NewReleaseCompareLink | Should -BeNullOrEmpty
            $result.NewReleaseLink | Should -BeNullOrEmpty
        }
    }
}
