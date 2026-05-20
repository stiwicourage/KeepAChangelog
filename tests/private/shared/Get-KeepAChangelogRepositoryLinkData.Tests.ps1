BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/shared/Get-KeepAChangelogRepositoryLinkData.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-KeepAChangelogRepositoryLinkData' {
    It 'returns null link data when neither a repository URL nor compare prefix is available' {
        $result = Get-KeepAChangelogRepositoryLinkData

        $result.RepositoryProvider | Should -BeNullOrEmpty
        $result.RepositoryUrl | Should -BeNullOrEmpty
        $result.UnreleasedCompareLinkPrefix | Should -BeNullOrEmpty
        $result.ReleaseTagPrefix | Should -BeNullOrEmpty
    }

    It 'builds provider-specific compare and tag prefixes from a repository URL' -ForEach @(
        @{
            ExpectedProvider           = 'GitHub'
            RepositoryUrl               = 'https://github.com/example/repo'
            UnreleasedCompareLinkPrefix = 'https://github.com/example/repo/compare/'
            ReleaseTagPrefix            = 'https://github.com/example/repo/releases/tag/'
        }
        @{
            ExpectedProvider           = 'GitLab'
            RepositoryUrl               = 'https://gitlab.com/example/repo'
            UnreleasedCompareLinkPrefix = 'https://gitlab.com/example/repo/-/compare/'
            ReleaseTagPrefix            = 'https://gitlab.com/example/repo/-/tags/'
        }
    ) {
        $result = Get-KeepAChangelogRepositoryLinkData -RepositoryUrl $RepositoryUrl

        $result.RepositoryProvider | Should -Be $ExpectedProvider
        $result.RepositoryUrl | Should -Be $RepositoryUrl
        $result.UnreleasedCompareLinkPrefix | Should -Be $UnreleasedCompareLinkPrefix
        $result.ReleaseTagPrefix | Should -Be $ReleaseTagPrefix
    }

    It 'derives the repository URL and tag prefix from an existing compare prefix' -ForEach @(
        @{
            ExpectedProvider           = 'GitHub'
            RepositoryUrl               = 'https://github.com/example/repo'
            UnreleasedCompareLinkPrefix = 'https://github.com/example/repo/compare/'
            ReleaseTagPrefix            = 'https://github.com/example/repo/releases/tag/'
        }
        @{
            ExpectedProvider           = 'GitLab'
            RepositoryUrl               = 'https://gitlab.com/example/repo'
            UnreleasedCompareLinkPrefix = 'https://gitlab.com/example/repo/-/compare/'
            ReleaseTagPrefix            = 'https://gitlab.com/example/repo/-/tags/'
        }
    ) {
        $result = Get-KeepAChangelogRepositoryLinkData -UnreleasedCompareLinkPrefix $UnreleasedCompareLinkPrefix

        $result.RepositoryProvider | Should -Be $ExpectedProvider
        $result.RepositoryUrl | Should -Be $RepositoryUrl
        $result.UnreleasedCompareLinkPrefix | Should -Be $UnreleasedCompareLinkPrefix
        $result.ReleaseTagPrefix | Should -Be $ReleaseTagPrefix
    }

    It 'treats blank repository URLs as non-GitLab URLs' {
        Test-KeepAChangelogGitLabRepositoryUrl -RepositoryUrl '   ' | Should -BeFalse
    }

    It 'uses the explicit provider for self-hosted GitLab repository URLs' {
        $result = Get-KeepAChangelogRepositoryLinkData `
            -RepositoryUrl 'https://code.example.com/group/project' `
            -RepositoryProvider 'GitLab'

        $result.RepositoryProvider | Should -Be 'GitLab'
        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://code.example.com/group/project/-/compare/'
        $result.ReleaseTagPrefix | Should -Be 'https://code.example.com/group/project/-/tags/'
    }

    It 'preserves the existing compare-link provider over an explicit parameter' {
        $result = Get-KeepAChangelogRepositoryLinkData `
            -RepositoryUrl 'https://code.example.com/group/project' `
            -RepositoryProvider 'GitHub' `
            -UnreleasedCompareLinkPrefix 'https://code.example.com/group/project/-/compare/'

        $result.RepositoryProvider | Should -Be 'GitLab'
        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://code.example.com/group/project/-/compare/'
        $result.ReleaseTagPrefix | Should -Be 'https://code.example.com/group/project/-/tags/'
    }
}
