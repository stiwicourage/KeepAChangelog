BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/shared/*.ps1'
        'src/private/validation/*.ps1'
        'src/private/release/*.ps1'
        'src/public/Convert-ChangelogReleaseNotesToTagMessage.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Resolve-KeepAChangelogReleaseData' {
    It 'throws when release resolution starts from an invalid changelog' {
        $errorMessage = $null

        try {
            Resolve-KeepAChangelogReleaseData -Text '# Changelog' -Release @{
                Version = '1.0.0'
                Date    = '2026-05-03'
                Tag     = '1.0.0'
            } -RepositoryState ([pscustomobject]@{
                    RepositoryUrl             = ''
                    RepositoryProvider        = ''
                    RepositoryTargetReference = ''
                })
        }
        catch {
            $errorMessage = $_.Exception.Message
        }

        $errorMessage | Should -Be 'CHANGELOG.md is not valid. Could not find ## [Unreleased] section in CHANGELOG.md.'
    }

    It 'builds GitLab compare and tag links from a GitLab repository URL' {
        $result = Resolve-KeepAChangelogReleaseData -Text @'
# Changelog

## [Unreleased]

### Added

- Initial release notes.
'@ -Release @{
            Version = '1.0.0'
            Date    = '2026-05-03'
            Tag     = '1.0.0'
        } -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = 'https://gitlab.com/example/repo'
                RepositoryProvider        = ''
                RepositoryTargetReference = ''
            })

        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://gitlab.com/example/repo/-/compare/'
        $result.UpdatedUnreleasedLink | Should -Be 'https://gitlab.com/example/repo/-/compare/1.0.0...HEAD'
        $result.NewReleaseLink | Should -Be 'https://gitlab.com/example/repo/-/tags/1.0.0'
    }

    It 'uses the explicit provider for self-hosted GitLab repository URLs' {
        $result = Resolve-KeepAChangelogReleaseData -Text @'
# Changelog

## [Unreleased]

### Added

- Initial release notes.
'@ -Release @{
            Version = '1.0.0'
            Date    = '2026-05-03'
            Tag     = '1.0.0'
        } -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = 'https://code.example.com/group/project'
                RepositoryProvider        = 'GitLab'
                RepositoryTargetReference = ''
            })

        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://code.example.com/group/project/-/compare/'
        $result.UpdatedUnreleasedLink | Should -Be 'https://code.example.com/group/project/-/compare/1.0.0...HEAD'
        $result.NewReleaseLink | Should -Be 'https://code.example.com/group/project/-/tags/1.0.0'
    }

    It 'builds Azure DevOps compare links when the provider-specific refs are supplied' {
        $result = Resolve-KeepAChangelogReleaseData -Text @'
# Changelog

## [Unreleased]

### Added

- Initial release notes.
'@ -Release @{
            Version   = '13.0.4'
            Date      = '2026-05-03'
            Tag       = '13.0.4'
            Reference = 'GTv13.0.4'
        } -RepositoryState ([pscustomobject]@{
                RepositoryUrl             = 'https://ado.example.com/Org/Project/_git/Tools'
                RepositoryProvider        = 'AzureDevOps'
                RepositoryTargetReference = 'GBdevelop'
            })

        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion='
        $result.UpdatedUnreleasedLink | Should -Be 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion=GTv13.0.4&targetVersion=GBdevelop&_a=commits'
        $result.NewReleaseLink | Should -Be 'https://ado.example.com/Org/Project/_git/Tools/branchCompare?baseVersion=GTv13.0.4&targetVersion=GTv13.0.4&_a=commits'
    }
}
