function Get-KeepAChangelogRepositoryProviderParameterDictionary {
    [CmdletBinding()]
    param()

    $attribute = [System.Management.Automation.ParameterAttribute]::new()
    $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
    $attributeCollection.Add($attribute)
    $attributeCollection.Add([System.Management.Automation.ValidateSetAttribute]::new('GitHub', 'GitLab'))

    $parameter = [System.Management.Automation.RuntimeDefinedParameter]::new(
        'RepositoryProvider',
        [string],
        $attributeCollection
    )
    $parameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    $parameterDictionary.Add('RepositoryProvider', $parameter)
    return $parameterDictionary
}
