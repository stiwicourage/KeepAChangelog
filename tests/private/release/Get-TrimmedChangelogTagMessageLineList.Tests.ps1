BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Get-TrimmedChangelogTagMessageLineList.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-TrimmedChangelogTagMessageLineList' {
    It 'removes trailing blank lines and preserves content lines' {
        $lineList = [System.Collections.Generic.List[string]]::new()
        $null = $lineList.Add('Fixed')
        $null = $lineList.Add('')
        $null = $lineList.Add(' ')

        $result = Get-TrimmedChangelogTagMessageLineList -LineList $lineList

        $result | Should -Be @('Fixed')
    }
}
