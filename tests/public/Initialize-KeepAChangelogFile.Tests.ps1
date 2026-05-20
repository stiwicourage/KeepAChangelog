BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/initialize/*.ps1'
        'src/public/Initialize-KeepAChangelogFile.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Initialize-KeepAChangelogFile' {
    It 'creates a changelog template with standard headings and an Unreleased compare link when PreviousReleaseReference is provided' {
        $path = Join-Path $TestDrive 'CHANGELOG.md'

        $result = Initialize-KeepAChangelogFile `
            -Path $path `
            -RepositoryUrl 'https://github.com/example/repo' `
            -PreviousReleaseReference '1.0.0'
        $text = Get-Content -LiteralPath $path -Raw

        $result.Path | Should -Be $path
        $text | Should -Match '## \[Unreleased\]'
        $text | Should -Match '### Added'
        $text | Should -Match '### Security'
        $text | Should -Match '\[Unreleased\]: https://github\.com/example/repo/compare/1\.0\.0\.\.\.HEAD'
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
