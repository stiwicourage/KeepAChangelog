BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Get-ChangelogTagMessageLine.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-ChangelogTagMessageLine' {
    It 'normalizes heading, bullet, and plain text lines' {
        (Get-ChangelogTagMessageLine -TrimmedLine '### Fixed') | Should -Be 'Fixed'
        (Get-ChangelogTagMessageLine -TrimmedLine '- Fixed CLI parsing.') | Should -Be 'Fixed CLI parsing.'
        (Get-ChangelogTagMessageLine -TrimmedLine 'Plain text line') | Should -Be 'Plain text line'
    }
}
