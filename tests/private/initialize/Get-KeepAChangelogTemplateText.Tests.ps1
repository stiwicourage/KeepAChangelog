BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/shared/Get-KeepAChangelogRepositoryLinkData.ps1'
        'src/private/initialize/*.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-KeepAChangelogTemplateText' {
    It 'includes a GitLab compare footer when the explicit provider is GitLab' {
        $repositoryState = [pscustomobject]@{
            RepositoryUrl             = 'https://code.example.com/group/project'
            RepositoryProvider        = 'GitLab'
            RepositoryTargetReference = ''
            UnreleasedCompareLinkPrefix = ''
            UnreleasedTargetReference = ''
        }
        $result = Get-KeepAChangelogTemplateText `
            -RepositoryState $repositoryState `
            -PreviousReleaseReference '1.0.0' `
            -SectionHeading @('Added', 'Fixed')

        $result | Should -Match '\[Unreleased\]: https://code\.example\.com/group/project/-/compare/1\.0\.0\.\.\.HEAD'
    }

    It 'includes an Azure DevOps compare footer when the explicit target reference is supplied' {
        $repositoryState = [pscustomobject]@{
            RepositoryUrl             = 'https://ado.example.com/Org/Project/_git/Tools'
            RepositoryProvider        = 'AzureDevOps'
            RepositoryTargetReference = 'GBdevelop'
            UnreleasedCompareLinkPrefix = ''
            UnreleasedTargetReference = ''
        }
        $result = Get-KeepAChangelogTemplateText `
            -RepositoryState $repositoryState `
            -PreviousReleaseReference 'GTv1.0.0' `
            -SectionHeading @('Added', 'Fixed')

        $result | Should -Match '\[Unreleased\]: https://ado\.example\.com/Org/Project/_git/Tools/branchCompare\?baseVersion=GTv1\.0\.0&targetVersion=GBdevelop&_a=commits'
    }
}
