function Get-KeepAChangelogHeadingLines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SectionHeading
    )

    return @(
        foreach ($heading in $SectionHeading) {
            "### $heading"
            ''
        }
    )
}
