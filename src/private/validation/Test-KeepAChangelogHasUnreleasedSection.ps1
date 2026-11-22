function Test-KeepAChangelogHasUnreleasedSection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )

    return [regex]::IsMatch($Body, '(?ms)^##\s+\[Unreleased\]\s*\r?\n')
}
