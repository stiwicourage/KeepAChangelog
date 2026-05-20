BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Get-ChangelogReleaseNotesBody.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-ChangelogReleaseNotesBody' {
    It 'returns an empty string for whitespace-only release notes' {
        (Get-ChangelogReleaseNotesBody -Body " `n`t ") | Should -Be ''
    }

    It 'keeps only populated section bodies when headings are present' {
        $result = Get-ChangelogReleaseNotesBody -Body @'
### Added

### Fixed

- Fixed CLI parsing.
'@

        $result | Should -Be "### Fixed`n`n- Fixed CLI parsing."
    }
}
