BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/validation/Get-UnreleasedCompareLinkMatch.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-UnreleasedCompareLinkMatch' {
    It 'extracts the compare prefix and previous release reference' -ForEach @(
        @{
            Prefix = 'https://github.com/example/repo/compare/'
            From   = '1.5.0'
            Target = 'HEAD'
            LinkSuffix = '...HEAD'
        }
        @{
            Prefix = 'https://gitlab.com/example/repo/-/compare/'
            From   = '1.5.0'
            Target = 'HEAD'
            LinkSuffix = '...HEAD'
        }
        @{
            Prefix = 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion='
            From   = 'GTv13.0.3'
            Target = 'GBdevelop'
            LinkSuffix = '&targetVersion=GBdevelop&_a=commits'
        }
    ) {
        $match = Get-UnreleasedCompareLinkMatch -Text @"
# Changelog

## [Unreleased]

[Unreleased]: $Prefix$From$LinkSuffix
"@

        $match.Success | Should -BeTrue
        $match.Groups['prefix'].Value | Should -Be $Prefix
        $match.Groups['from'].Value | Should -Be $From
        $match.Groups['target'].Value | Should -Be $Target
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
