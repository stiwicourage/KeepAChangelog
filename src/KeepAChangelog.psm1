Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$privateFunctionFileList = @(Get-ChildItem -Path (Join-Path $moduleRoot 'private') -Filter '*.ps1' -File | Sort-Object Name)
$publicFunctionFileList = @(Get-ChildItem -Path (Join-Path $moduleRoot 'public') -Filter '*.ps1' -File | Sort-Object Name)

foreach ($privateFunctionFile in $privateFunctionFileList) {
    . $privateFunctionFile.FullName
}

foreach ($publicFunctionFile in $publicFunctionFileList) {
    . $publicFunctionFile.FullName
}

$functionToExport = @($publicFunctionFileList | Select-Object -ExpandProperty BaseName)
Export-ModuleMember -Function $functionToExport
