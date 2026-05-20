BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/Split-KeepAChangelogText.ps1')
    . (Join-Path $projectRoot 'src/private/validation/Test-KeepAChangelogHasUnreleasedSection.ps1')
    . (Join-Path $projectRoot 'src/private/validation/Get-KeepAChangelogUnreleasedSectionError.ps1')
    . (Join-Path $projectRoot 'src/private/validation/Get-KeepAChangelogReleaseVersionList.ps1')
    . (Join-Path $projectRoot 'src/private/validation/Get-KeepAChangelogReferenceLabelCountMap.ps1')
    . (Join-Path $projectRoot 'src/private/validation/Add-KeepAChangelogDuplicateReferenceLinkError.ps1')
    . (Join-Path $projectRoot 'src/private/validation/Get-KeepAChangelogUnreleasedCompareLinkData.ps1')
    . (Join-Path $projectRoot 'src/private/validation/Get-KeepAChangelogValidationResult.ps1')
}

Describe 'Get-KeepAChangelogValidationResult' {
    It 'returns the actionable Unreleased error for a near-match heading' {
        $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## Unreleased

### Added

- Draft entry.
'@

        $result.IsValid | Should -BeFalse
        $result.Errors | Should -Be @(
            'Found an Unreleased heading, but it is formatted as `## Unreleased`. Expected `## [Unreleased]`.'
        )
    }

    It 'keeps the generic Unreleased error when no matching heading exists' {
        $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

## [1.0.0] - 2026-05-20

### Added
'@

        $result.IsValid | Should -BeFalse
        $result.Errors | Should -Be @(
            'Could not find ## [Unreleased] section in CHANGELOG.md.'
        )
    }

    It 'keeps the generic Unreleased error for unrelated headings that mention Unreleased' {
        $result = Get-KeepAChangelogValidationResult -Text @'
# Changelog

### Unreleased migration notes

## [1.0.0] - 2026-05-20

### Added
'@

        $result.IsValid | Should -BeFalse
        $result.Errors | Should -Be @(
            'Could not find ## [Unreleased] section in CHANGELOG.md.'
        )
    }

    It 'reports release sections that do not use the required heading format' {
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

    It 'accepts yanked release sections that follow the Keep a Changelog heading format' {
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

    It 'reports duplicate release sections' {
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

    It 'reports duplicate footer reference links' {
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

    It 'accepts release sections when no footer reference links are present' {
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

    It 'reports a missing Unreleased compare link when footer links exist' {
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

    It 'reports multiple Unreleased compare links' {
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
