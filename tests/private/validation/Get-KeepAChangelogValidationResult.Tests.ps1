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
}
