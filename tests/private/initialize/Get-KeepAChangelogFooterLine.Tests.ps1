BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/shared/Get-KeepAChangelogRepositoryLinkData.ps1'
        'src/private/initialize/Get-KeepAChangelogFooterLine.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-KeepAChangelogFooterLine' {
    It 'uses the explicit provider when building the Unreleased footer link' -ForEach @(
        @{
            RepositoryUrl = 'https://github.com/example/repo'
            RepositoryProvider = 'GitHub'
            RepositoryTargetReference = ''
            PreviousReleaseReference = '1.0.0'
            ExpectedFooterLine = '[Unreleased]: https://github.com/example/repo/compare/1.0.0...HEAD'
        }
        @{
            RepositoryUrl = 'https://code.example.com/group/project'
            RepositoryProvider = 'GitLab'
            RepositoryTargetReference = ''
            PreviousReleaseReference = '1.0.0'
            ExpectedFooterLine = '[Unreleased]: https://code.example.com/group/project/-/compare/1.0.0...HEAD'
        }
        @{
            RepositoryUrl = 'https://ado.example.com/Org/Project/_git/Tools'
            RepositoryProvider = 'AzureDevOps'
            RepositoryTargetReference = 'GBdevelop'
            PreviousReleaseReference = 'GTv1.0.0'
            ExpectedFooterLine = '[Unreleased]: https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion=GTv1.0.0&targetVersion=GBdevelop&_a=commits'
        }
    ) {
        $repositoryState = [pscustomobject]@{
            RepositoryUrl             = $RepositoryUrl
            RepositoryProvider        = $RepositoryProvider
            RepositoryTargetReference = $RepositoryTargetReference
            UnreleasedCompareLinkPrefix = ''
            UnreleasedTargetReference = ''
        }
        $result = Get-KeepAChangelogFooterLine `
            -RepositoryState $repositoryState `
            -PreviousReleaseReference $PreviousReleaseReference

        $result | Should -Be $ExpectedFooterLine
    }

    It 'returns null when PreviousReleaseReference is omitted' {
        Get-KeepAChangelogFooterLine -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = 'https://github.com/example/repo'
                RepositoryProvider        = 'GitHub'
                RepositoryTargetReference = ''
                UnreleasedCompareLinkPrefix = ''
                UnreleasedTargetReference = ''
            }) | Should -BeNullOrEmpty
    }
}
