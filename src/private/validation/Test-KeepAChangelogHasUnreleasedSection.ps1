function Test-KeepAChangelogHasUnreleasedSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )

    return $Body -match '(?ms)^##\s+\[Unreleased\]\s*\r?\n'
}
