function Get-KeepAChangelogRuntimeDefinedParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [type]$ParameterType,
        [string[]]$ValidateSetValue
    )

    $attribute = [System.Management.Automation.ParameterAttribute]::new()
    $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
    $attributeCollection.Add($attribute)

    if ($null -ne $ValidateSetValue -and $ValidateSetValue.Count -gt 0) {
        $attributeCollection.Add([System.Management.Automation.ValidateSetAttribute]::new($ValidateSetValue))
    }

    return [System.Management.Automation.RuntimeDefinedParameter]::new(
        $Name,
        $ParameterType,
        $attributeCollection
    )
}

function Get-KeepAChangelogRepositoryProviderParameterDictionary {
    [CmdletBinding()]
    param(
        [switch]$IncludeReleaseReference,
        [switch]$IncludeRepositoryTargetReference
    )

    $parameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    $parameterDictionary.Add(
        'RepositoryProvider',
        (Get-KeepAChangelogRuntimeDefinedParameter `
            -Name 'RepositoryProvider' `
            -ParameterType ([string]) `
            -ValidateSetValue @('GitHub', 'GitLab', 'AzureDevOps'))
    )

    if ($IncludeRepositoryTargetReference) {
        $parameterDictionary.Add(
            'RepositoryTargetReference',
            (Get-KeepAChangelogRuntimeDefinedParameter -Name 'RepositoryTargetReference' -ParameterType ([string]))
        )
    }

    if ($IncludeReleaseReference) {
        $parameterDictionary.Add(
            'ReleaseReference',
            (Get-KeepAChangelogRuntimeDefinedParameter -Name 'ReleaseReference' -ParameterType ([string]))
        )
    }

    return $parameterDictionary
}
