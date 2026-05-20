BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/shared/Get-KeepAChangelogModuleVersion.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-KeepAChangelogModuleVersion' {
    It 'returns the project version when the function is dot-sourced outside a module' {
        $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
        $expectedVersion = (Get-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Raw | ConvertFrom-Json).Version

        $result = Get-KeepAChangelogModuleVersion

        $result | Should -Be $expectedVersion
    }
}
