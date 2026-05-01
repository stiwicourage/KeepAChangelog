function Get-ClearedUnreleasedBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Body
    )

    $headingList = @(
        [regex]::Matches($Body, '(?m)^[ \t]*###\s+[^\r\n]+') |
            ForEach-Object { $_.Value.TrimEnd() }
    )

    if (-not $headingList) {
        return ''
    }

    return ($headingList -join "`n`n").TrimEnd()
}
