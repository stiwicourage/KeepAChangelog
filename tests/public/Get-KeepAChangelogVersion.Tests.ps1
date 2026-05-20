BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/shared/Get-KeepAChangelogModuleVersion.ps1'
        'src/public/Get-KeepAChangelogVersion.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-KeepAChangelogVersion' {
    It 'returns the project version when loaded from source' {
        $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
        $expectedVersion = (Get-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Raw | ConvertFrom-Json).Version

        $result = Get-KeepAChangelogVersion

        $result | Should -Be $expectedVersion
    }
}
