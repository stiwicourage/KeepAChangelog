function Import-KeepAChangelogSourceFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,
        [Parameter(Mandatory)]
        [string[]]$RelativePath
    )

    foreach ($pathPattern in $RelativePath) {
        $resolvedPattern = Join-Path $ProjectRoot $pathPattern
        $sourceFileList = if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($pathPattern)) {
            @(Get-ChildItem -Path $resolvedPattern -File | Sort-Object -Property FullName)
        }
        else {
            @(Get-Item -LiteralPath $resolvedPattern)
        }

        foreach ($sourceFile in $sourceFileList) {
            $sourceFile
        }
    }
}
