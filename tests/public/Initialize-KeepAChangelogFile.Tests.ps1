BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/initialize/*.ps1'
        'src/private/shared/Get-KeepAChangelogRepositoryLinkData.ps1'
        'src/private/shared/Get-KeepAChangelogRepositoryProviderParameterDictionary.ps1'
        'src/public/Initialize-KeepAChangelogFile.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Initialize-KeepAChangelogFile' {
    It 'exposes RepositoryProvider with the supported provider values' {
        $command = Get-Command -Name Initialize-KeepAChangelogFile
        $validateSet = $command.Parameters['RepositoryProvider'].Attributes |
            Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

        $command.Parameters.ContainsKey('RepositoryProvider') | Should -BeTrue
        $validateSet.ValidValues | Should -Be @('GitHub', 'GitLab')
    }

    It 'creates a changelog template with standard headings and an Unreleased compare link when PreviousReleaseReference is provided' -ForEach @(
        @{
            Name                  = 'GitHub repository URLs'
            FileName              = 'CHANGELOG-github.md'
            RepositoryUrl         = 'https://github.com/example/repo'
            RepositoryProvider    = 'GitHub'
            ExpectedFooterPattern = '\[Unreleased\]: https://github\.com/example/repo/compare/1\.0\.0\.\.\.HEAD'
        }
        @{
            Name                  = 'GitLab repository URLs'
            FileName              = 'CHANGELOG-gitlab.md'
            RepositoryUrl         = 'https://gitlab.com/example/repo'
            RepositoryProvider    = ''
            ExpectedFooterPattern = '\[Unreleased\]: https://gitlab\.com/example/repo/-/compare/1\.0\.0\.\.\.HEAD'
        }
        @{
            Name                  = 'self-hosted GitLab repository URLs with an explicit provider'
            FileName              = 'CHANGELOG-self-hosted-gitlab.md'
            RepositoryUrl         = 'https://code.example.com/group/project'
            RepositoryProvider    = 'GitLab'
            ExpectedFooterPattern = '\[Unreleased\]: https://code\.example\.com/group/project/-/compare/1\.0\.0\.\.\.HEAD'
        }
    ) {
        $path = Join-Path $TestDrive $FileName

        $parameters = @{
            Path                     = $path
            RepositoryUrl            = $RepositoryUrl
            PreviousReleaseReference = '1.0.0'
        }

        if (-not [string]::IsNullOrWhiteSpace($RepositoryProvider)) {
            $parameters.RepositoryProvider = $RepositoryProvider
        }

        $result = Initialize-KeepAChangelogFile @parameters
        $text = Get-Content -LiteralPath $path -Raw

        $result.Path | Should -Be $path
        $text | Should -Match '## \[Unreleased\]'
        $text | Should -Match '### Added'
        $text | Should -Match '### Security'
        $text | Should -Match $ExpectedFooterPattern
    }

    It 'creates a changelog template without footer links when PreviousReleaseReference is omitted' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        $result = Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -Force
        $text = Get-Content -LiteralPath $path -Raw

        $result.PreviousReleaseReference | Should -BeNullOrEmpty
        $text | Should -Match '## \[Unreleased\]'
        $text | Should -Not -Match '(?m)^\[Unreleased\]:'
    }

    It 'accepts develop as PreviousReleaseReference for projects without tags yet' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        $result = Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -PreviousReleaseReference 'develop' `
            -Force
        $text = Get-Content -LiteralPath $path -Raw

        $result.PreviousReleaseReference | Should -Be 'develop'
        $text | Should -Match '\[Unreleased\]: https://github\.com/example/repo/compare/develop\.\.\.HEAD'
    }

    It 'does not export the old New-KeepAChangelogFile command name' {
        { Get-Command -Name New-KeepAChangelogFile -ErrorAction Stop } | Should -Throw
    }

    It 'throws when RepositoryUrl is blank' {
        {
            Initialize-KeepAChangelogFile -Path (Join-Path $TestDrive 'CHANGELOG.md') -RepositoryUrl '   '
        } | Should -Throw 'RepositoryUrl is required.'
    }

    It 'throws when the target file already exists and Force is not used' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'
        '# Changelog' | Set-Content -LiteralPath $path -Encoding utf8

        {
            Initialize-KeepAChangelogFile -Path $path -RepositoryUrl 'https://github.com/example/repo'
        } | Should -Throw "File already exists at '$path'. Use -Force to overwrite it."
    }
}
