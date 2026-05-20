BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/validation/Test-KeepAChangelogHasUnreleasedSection.ps1')
    . (Join-Path $projectRoot 'src/private/validation/Get-KeepAChangelogUnreleasedSectionError.ps1')
}

Describe 'Get-KeepAChangelogUnreleasedSectionError' {
    It 'returns no error when the Unreleased heading is valid' {
        $result = Get-KeepAChangelogUnreleasedSectionError -Body @'
## [Unreleased]

### Added
'@

        $result | Should -BeNullOrEmpty
    }

    It 'returns an actionable error for obvious Unreleased near matches' {
        $caseList = @(
            '## Unreleased'
            '## [unreleased]'
            '### [Unreleased]'
            '## {Unreleased}'
        )

        foreach ($headingLine in $caseList) {
            $result = Get-KeepAChangelogUnreleasedSectionError -Body @"
$headingLine

### Added
"@

            $result | Should -Be "Found an Unreleased heading, but it is formatted as ``$headingLine``. Expected ``## [Unreleased]``."
        }
    }

    It 'returns the generic error when the changelog has no Unreleased heading' {
        $result = Get-KeepAChangelogUnreleasedSectionError -Body @'
## [1.0.0] - 2026-05-20

### Added
'@

        $result | Should -Be 'Could not find ## [Unreleased] section in CHANGELOG.md.'
    }

    It 'ignores headings that mention Unreleased without being a malformed section heading' {
        $result = Get-KeepAChangelogUnreleasedSectionError -Body @'
### Unreleased migration notes

## [1.0.0] - 2026-05-20

### Added
'@

        $result | Should -Be 'Could not find ## [Unreleased] section in CHANGELOG.md.'
    }
}
