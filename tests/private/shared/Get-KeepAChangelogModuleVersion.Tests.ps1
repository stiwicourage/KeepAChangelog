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

    It 'returns the loaded module version when running inside the KeepAChangelog module' {
        $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
        $moduleRoot = Join-Path $TestDrive 'KeepAChangelog'
        $moduleManifestPath = Join-Path $moduleRoot 'KeepAChangelog.psd1'
        $modulePath = Join-Path $moduleRoot 'KeepAChangelog.psm1'

        New-Item -ItemType Directory -Path $moduleRoot | Out-Null
        New-ModuleManifest -Path $moduleManifestPath -RootModule 'KeepAChangelog.psm1' -ModuleVersion '9.8.7' | Out-Null
        @"
. '$projectRoot/src/private/shared/Get-KeepAChangelogModuleVersion.ps1'
function Get-LoadedKeepAChangelogModuleVersion {
    Get-KeepAChangelogModuleVersion
}
Export-ModuleMember -Function Get-LoadedKeepAChangelogModuleVersion
"@ | Set-Content -LiteralPath $modulePath -Encoding utf8

        Import-Module -Name $moduleManifestPath -Force
        try {
            Get-LoadedKeepAChangelogModuleVersion | Should -Be '9.8.7'
        }
        finally {
            Remove-Module -Name KeepAChangelog -Force -ErrorAction SilentlyContinue
        }
    }
}
