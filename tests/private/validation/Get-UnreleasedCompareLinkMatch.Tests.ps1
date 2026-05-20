BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/validation/Get-UnreleasedCompareLinkMatch.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-UnreleasedCompareLinkMatch' {
    It 'extracts the compare prefix and previous release reference' {
        $match = Get-UnreleasedCompareLinkMatch -Text @'
# Changelog

## [Unreleased]

[Unreleased]: https://github.com/example/repo/compare/1.5.0...HEAD
'@

        $match.Success | Should -BeTrue
        $match.Groups['prefix'].Value | Should -Be 'https://github.com/example/repo/compare/'
        $match.Groups['from'].Value | Should -Be '1.5.0'
    }

    It 'throws when the Unreleased compare link is missing' {
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
