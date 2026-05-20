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
            }
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
        } -RepositoryUrl 'https://gitlab.com/example/repo'

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
        } -RepositoryUrl 'https://code.example.com/group/project' -RepositoryProvider 'GitLab'

        $result.UnreleasedCompareLinkPrefix | Should -Be 'https://code.example.com/group/project/-/compare/'
        $result.UpdatedUnreleasedLink | Should -Be 'https://code.example.com/group/project/-/compare/1.0.0...HEAD'
        $result.NewReleaseLink | Should -Be 'https://code.example.com/group/project/-/tags/1.0.0'
    }
}
