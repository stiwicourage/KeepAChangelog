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
        'src/private/shared/Get-KeepAChangelogRepositoryLinkData.ps1'
        'src/private/shared/Get-KeepAChangelogRepositoryProviderParameterDictionary.ps1'
        'src/private/shared/Split-KeepAChangelogText.ps1'
        'src/private/validation/*.ps1'
        'src/public/Initialize-KeepAChangelogFile.ps1'
        'src/public/Test-KeepAChangelogFile.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Test-KeepAChangelogFile' {
    It 'returns a valid result for initialized changelog variants' {
        $caseList = @(
            @{
                FileName                  = 'CHANGELOG-existing.md'
                PreviousReleaseReference = '1.0.0'
                ExpectedReference        = '1.0.0'
            }
            @{
                FileName                  = 'CHANGELOG-new.md'
                PreviousReleaseReference = $null
                ExpectedReference        = $null
            }
        )

        foreach ($case in $caseList) {
            $path = Join-Path $TestDrive $case.FileName
            Initialize-TestChangelog -Path $path -PreviousReleaseReference $case.PreviousReleaseReference

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

    It 'reports a near-match Unreleased heading with an actionable error' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## Unreleased

### Added

- Draft entry.
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Test-KeepAChangelogFile -Path $path

        $result.IsValid | Should -BeFalse
        $result.Errors | Should -Contain 'Found an Unreleased heading, but it is formatted as `## Unreleased`. Expected `## [Unreleased]`.'
    }

    It 'keeps the missing-section error for headings that only mention Unreleased' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

### Unreleased migration notes

## [1.0.0] - 2026-04-30

### Added

- Initial release.
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

    It 'accepts GitLab compare links in the reference footer' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        @'
# Changelog

## [Unreleased]

### Added

## [1.0.0] - 2026-04-30

### Added

- Initial release.

[Unreleased]: https://gitlab.com/example/repo/-/compare/1.0.0...HEAD
[1.0.0]: https://gitlab.com/example/repo/-/tags/1.0.0
'@ | Set-Content -LiteralPath $path -Encoding utf8

        $result = Test-KeepAChangelogFile -Path $path

        $result.IsValid | Should -BeTrue
        @($result.Errors).Count | Should -Be 0
        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://gitlab.com/example/repo/-/compare/'
        $result.PreviousReleaseReference | Should -Be '1.0.0'
    }

    It 'accepts yanked release headings that follow the Keep a Changelog format' {
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
            $path = Join-Path $TestDrive "CHANGELOG-YANKED-$($case.Name).md"
            $footer = Get-ReferenceFooterText `
                -LineList @(
                    '[Unreleased]: https://github.com/example/repo/compare/2.2.0...HEAD'
                    '[2.2.0]: https://github.com/example/repo/releases/tag/2.2.0'
                ) `
                -SeparateWithBlankLines:$case.SeparateWithBlankLines

            @"
# Changelog

## [Unreleased]

### Added

## [2.2.0] - 2026-05-06 [YANKED]

### Fixed

- Yanked because of a release regression.

$footer
"@ | Set-Content -LiteralPath $path -Encoding utf8

            $result = Test-KeepAChangelogFile -Path $path

            $result.IsValid | Should -BeTrue
            $result.Errors.Count | Should -Be 0
            @($result.ReleaseVersions) | Should -Be @('2.2.0')
            $result.PreviousReleaseReference | Should -Be '2.2.0'
        }
    }

    It 'throws validation errors when ThrowOnError is used' {
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

    It 'throws when the target file is missing' {
        $path = Join-Path $TestDrive 'missing.md'

        {
            Test-KeepAChangelogFile -Path $path
        } | Should -Throw "Could not find CHANGELOG file at '$path'."
    }
}
