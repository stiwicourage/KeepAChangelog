function Get-KeepAChangelogHeadingLineList {
    [CmdletBinding()]
    [OutputType([object[]])]
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
