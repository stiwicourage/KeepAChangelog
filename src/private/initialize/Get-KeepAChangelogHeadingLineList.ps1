function Get-KeepAChangelogHeadingLineList {
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
