BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Get-KeepAChangelogProjectRoot.ps1')
    . (Join-Path $PSScriptRoot '..' '..' 'TestHelpers' 'Import-KeepAChangelogSourceFile.ps1')

    $projectRoot = Get-KeepAChangelogProjectRoot -StartPath $PSScriptRoot
    Import-KeepAChangelogSourceFile -ProjectRoot $projectRoot -RelativePath @(
        'src/private/shared/Get-KeepAChangelogRepositoryProviderParameterDictionary.ps1'
    ) | ForEach-Object { . $_.FullName }
}

Describe 'Get-KeepAChangelogRepositoryProviderParameterDictionary' {
    It 'creates a RepositoryProvider dynamic parameter with the supported provider values' {
        $result = Get-KeepAChangelogRepositoryProviderParameterDictionary
        $parameter = $result['RepositoryProvider']
        $validateSet = $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }

        $parameter.Name | Should -Be 'RepositoryProvider'
        $parameter.ParameterType | Should -Be ([string])
        $validateSet.ValidValues | Should -Be @('GitHub', 'GitLab', 'AzureDevOps')
    }

    It 'adds the optional Azure DevOps reference parameters when requested' {
        $result = Get-KeepAChangelogRepositoryProviderParameterDictionary `
            -IncludeRepositoryTargetReference `
            -IncludeReleaseReference

        $result.ContainsKey('RepositoryTargetReference') | Should -BeTrue
        $result.ContainsKey('ReleaseReference') | Should -BeTrue
        $result['RepositoryTargetReference'].ParameterType | Should -Be ([string])
        $result['ReleaseReference'].ParameterType | Should -Be ([string])
    }
}
