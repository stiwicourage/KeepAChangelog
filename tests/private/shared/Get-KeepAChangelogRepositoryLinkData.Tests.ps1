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
        $result = Get-KeepAChangelogRepositoryLinkData -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = ''
                RepositoryProvider        = ''
                RepositoryTargetReference = ''
                UnreleasedCompareLinkPrefix = ''
                UnreleasedTargetReference = ''
            })

        $result | Should -BeNullOrEmpty
    }

    It 'builds provider-specific compare and tag prefixes from a repository URL' -ForEach @(
        @{
            ExpectedProvider           = 'GitHub'
            RepositoryProvider         = ''
            RepositoryTargetReference  = ''
            RepositoryUrl               = 'https://github.com/example/repo'
            UnreleasedCompareLinkPrefix = 'https://github.com/example/repo/compare/'
            ReleaseTagPrefix            = 'https://github.com/example/repo/releases/tag/'
            UnreleasedTargetReference   = 'HEAD'
        }
        @{
            ExpectedProvider           = 'GitLab'
            RepositoryProvider         = ''
            RepositoryTargetReference  = ''
            RepositoryUrl               = 'https://gitlab.com/example/repo'
            UnreleasedCompareLinkPrefix = 'https://gitlab.com/example/repo/-/compare/'
            ReleaseTagPrefix            = 'https://gitlab.com/example/repo/-/tags/'
            UnreleasedTargetReference   = 'HEAD'
        }
        @{
            ExpectedProvider            = 'AzureDevOps'
            RepositoryUrl               = 'https://ado.example.com/Org/Project/_git/Tools'
            RepositoryProvider          = 'AzureDevOps'
            RepositoryTargetReference   = 'GBdevelop'
            UnreleasedCompareLinkPrefix = 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion='
            ReleaseTagPrefix            = $null
            UnreleasedTargetReference   = 'GBdevelop'
        }
    ) {
        $result = Get-KeepAChangelogRepositoryLinkData -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = $RepositoryUrl
                RepositoryProvider        = $RepositoryProvider
                RepositoryTargetReference = $RepositoryTargetReference
                UnreleasedCompareLinkPrefix = ''
                UnreleasedTargetReference = ''
            })

        $result.RepositoryProvider | Should -Be $ExpectedProvider
        $result.RepositoryUrl | Should -Be $RepositoryUrl
        $result.UnreleasedCompareLinkPrefix | Should -Be $UnreleasedCompareLinkPrefix
        $result.ReleaseTagPrefix | Should -Be $ReleaseTagPrefix
        if (-not [string]::IsNullOrWhiteSpace($UnreleasedTargetReference)) {
            $result.UnreleasedTargetReference | Should -Be $UnreleasedTargetReference
        }
    }

    It 'derives the repository URL and tag prefix from an existing compare prefix' -ForEach @(
        @{
            ExpectedProvider           = 'GitHub'
            RepositoryUrl               = 'https://github.com/example/repo'
            UnreleasedCompareLinkPrefix = 'https://github.com/example/repo/compare/'
            ReleaseTagPrefix            = 'https://github.com/example/repo/releases/tag/'
            UnreleasedTargetReference   = 'HEAD'
        }
        @{
            ExpectedProvider           = 'GitLab'
            RepositoryUrl               = 'https://gitlab.com/example/repo'
            UnreleasedCompareLinkPrefix = 'https://gitlab.com/example/repo/-/compare/'
            ReleaseTagPrefix            = 'https://gitlab.com/example/repo/-/tags/'
            UnreleasedTargetReference   = 'HEAD'
        }
        @{
            ExpectedProvider            = 'AzureDevOps'
            RepositoryUrl               = 'https://ado.example.com/Org/Project/_git/Tools'
            UnreleasedCompareLinkPrefix = 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion='
            ReleaseTagPrefix            = $null
            UnreleasedTargetReference   = 'GBdevelop'
        }
    ) {
        $result = Get-KeepAChangelogRepositoryLinkData -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = ''
                RepositoryProvider        = ''
                RepositoryTargetReference = ''
                UnreleasedCompareLinkPrefix = $UnreleasedCompareLinkPrefix
                UnreleasedTargetReference = $UnreleasedTargetReference
            })

        $result.RepositoryProvider | Should -Be $ExpectedProvider
        $result.RepositoryUrl | Should -Be $RepositoryUrl
        $result.UnreleasedCompareLinkPrefix | Should -Be $UnreleasedCompareLinkPrefix
        $result.ReleaseTagPrefix | Should -Be $ReleaseTagPrefix
        $result.UnreleasedTargetReference | Should -Be $UnreleasedTargetReference
    }

    It 'treats blank repository URLs as non-GitLab URLs' {
        Test-KeepAChangelogGitLabRepositoryUrl -RepositoryUrl '   ' | Should -BeFalse
    }

    It 'detects Azure DevOps repository URLs from the _git path' {
        Test-KeepAChangelogAzureDevOpsRepositoryUrl -RepositoryUrl 'https://ado.example.com/Org/Project/_git/Tools' | Should -BeTrue
    }

    It 'does not detect Azure DevOps for non-_git repository URLs' {
        Test-KeepAChangelogAzureDevOpsRepositoryUrl -RepositoryUrl 'https://github.com/example/repo' | Should -BeFalse
    }

    It 'applies provider selection rules for self-hosted repository URLs' -ForEach @(
        @{
            Name                        = 'uses the explicit provider for self-hosted GitLab repository URLs'
            RepositoryProvider          = 'GitLab'
            UnreleasedCompareLinkPrefix = ''
            ExpectedProvider            = 'GitLab'
        }
        @{
            Name                        = 'preserves the existing compare-link provider over an explicit parameter'
            RepositoryProvider          = 'GitHub'
            UnreleasedCompareLinkPrefix = 'https://code.example.com/group/project/-/compare/'
            ExpectedProvider            = 'GitLab'
        }
    ) {
        $result = Get-KeepAChangelogRepositoryLinkData -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = 'https://code.example.com/group/project'
                RepositoryProvider        = $RepositoryProvider
                RepositoryTargetReference = ''
                UnreleasedCompareLinkPrefix = $UnreleasedCompareLinkPrefix
                UnreleasedTargetReference = ''
            })

        $result.RepositoryProvider | Should -Be $ExpectedProvider
        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://code.example.com/group/project/-/compare/'
        $result.ReleaseTagPrefix | Should -Be 'https://code.example.com/group/project/-/tags/'
    }

    It 'requires RepositoryTargetReference when Azure DevOps footer links must be generated' {
        {
            Get-KeepAChangelogRepositoryLinkData -RepositoryState ([pscustomobject]@{
                    RepositoryUrl             = 'https://ado.example.com/Org/Project/_git/Tools'
                    RepositoryProvider        = 'AzureDevOps'
                    RepositoryTargetReference = ''
                    UnreleasedCompareLinkPrefix = ''
                    UnreleasedTargetReference = ''
                })
        } | Should -Throw 'RepositoryTargetReference is required when AzureDevOps footer links must be generated.'
    }

    It 'infers Azure DevOps from the repository URL when the path uses _git' {
        $result = Get-KeepAChangelogRepositoryLinkData -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = 'https://ado.example.com/Org/Project/_git/Tools'
                RepositoryProvider        = ''
                RepositoryTargetReference = 'GBdevelop'
                UnreleasedCompareLinkPrefix = ''
                UnreleasedTargetReference = ''
            })

        $result.RepositoryProvider | Should -Be 'AzureDevOps'
        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion='
        $result.UnreleasedTargetReference | Should -Be 'GBdevelop'
    }
}
