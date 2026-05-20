BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/validation/Test-KeepAChangelogHasUnreleasedSection.ps1')
}

Describe 'Test-KeepAChangelogHasUnreleasedSection' {
    It 'returns true for the exact Keep a Changelog Unreleased heading' {
        $result = Test-KeepAChangelogHasUnreleasedSection -Body @'
## [Unreleased]

### Added
'@

        $result | Should -BeTrue
    }

    It 'returns false for obvious near matches that must stay invalid' {
        $caseList = @(
            '## Unreleased'
            '## [unreleased]'
            '### [Unreleased]'
        )

        foreach ($headingLine in $caseList) {
            $result = Test-KeepAChangelogHasUnreleasedSection -Body @"
$headingLine

### Added
"@

            $result | Should -BeFalse
        }
    }
}
