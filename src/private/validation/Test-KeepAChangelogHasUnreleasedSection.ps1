function Test-KeepAChangelogHasUnreleasedSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )

    return [regex]::IsMatch($Body, '(?ms)^##\s+\[Unreleased\]\s*\r?\n')
}
