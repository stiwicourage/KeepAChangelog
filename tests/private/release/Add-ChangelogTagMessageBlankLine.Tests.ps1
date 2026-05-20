BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/release/Add-ChangelogTagMessageBlankLine.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Add-ChangelogTagMessageBlankLine' {
    It 'does not add a blank line when blank lines are not allowed' {
        $lineList = [System.Collections.Generic.List[string]]::new()

        $result = Add-ChangelogTagMessageBlankLine -LineList $lineList -AllowBlankLine $false

        $result | Should -BeFalse
        $lineList.Count | Should -Be 0
    }

    It 'adds a blank line when blank lines are allowed and content exists' {
        $lineList = [System.Collections.Generic.List[string]]::new()
        $null = $lineList.Add('Fixed')

        $result = Add-ChangelogTagMessageBlankLine -LineList $lineList -AllowBlankLine $true

        $result | Should -BeFalse
        $lineList | Should -Be @('Fixed', '')
    }
}
