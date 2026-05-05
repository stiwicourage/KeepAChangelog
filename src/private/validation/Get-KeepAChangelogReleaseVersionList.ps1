function Get-KeepAChangelogReleaseVersionList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ErrorList
    )

    $releaseVersionList = [System.Collections.Generic.List[string]]::new()

    foreach ($releaseHeadingLine in [regex]::Matches($Body, '(?m)^##\s+\[(?<label>[^\]]+)\].*$')) {
        $label = $releaseHeadingLine.Groups['label'].Value
        if ($label -eq 'Unreleased') {
            continue
        }

        $line = $releaseHeadingLine.Value.TrimEnd()
        if ($line -notmatch '^## \[[^\]]+\] - \d{4}-\d{2}-\d{2}$') {
            $ErrorList.Add("Release section '$line' must use '## [<version>] - <date>' format.")
            continue
        }

        if ($releaseVersionList.Contains($label)) {
            $ErrorList.Add("Release section [$label] is duplicated.")
            continue
        }

        $releaseVersionList.Add($label)
    }

    return ,$releaseVersionList
}
