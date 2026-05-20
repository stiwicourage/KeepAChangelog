BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Add-ChangelogTagMessageBlankLine.ps1'
        'src/private/release/Get-ChangelogTagMessageLine.ps1'
        'src/private/release/Get-TrimmedChangelogTagMessageLineList.ps1'
        'src/public/Convert-ChangelogReleaseNotesToTagMessage.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Convert-ChangelogReleaseNotesToTagMessage' {
    It 'converts markdown release notes to plain text' {
        $releaseNotes = @'
### Fixed

- Fixed CLI parsing.
- Fixed release note formatting.
'@

        $result = Convert-ChangelogReleaseNotesToTagMessage -ReleaseNotes $releaseNotes

        $result | Should -Be "Fixed`n`nFixed CLI parsing.`nFixed release note formatting."
    }

    It 'preserves plain text and trims trailing blank lines' {
        $result = Convert-ChangelogReleaseNotesToTagMessage -ReleaseNotes "Plain text line`n`n"

        $result | Should -Be 'Plain text line'
    }
}
