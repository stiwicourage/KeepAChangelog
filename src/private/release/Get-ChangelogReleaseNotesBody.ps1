function Get-ChangelogReleaseNotesBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Body
    )

    $trimmedBody = $Body.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmedBody)) {
        return ''
    }

    if ($trimmedBody -notmatch '(?m)^[ \t]*###\s+') {
        return $trimmedBody
    }

    $sectionPattern = '(?ms)^(?<heading>[ \t]*###\s+[^\r\n]+)\r?\n(?<content>.*?)(?=^[ \t]*###\s+|\z)'
    $sectionMatchList = [regex]::Matches($trimmedBody, $sectionPattern)
    $sectionTextList = [System.Collections.Generic.List[string]]::new()

    foreach ($sectionMatch in $sectionMatchList) {
        $heading = $sectionMatch.Groups['heading'].Value.TrimEnd()
        $content = $sectionMatch.Groups['content'].Value.Trim()

        if ([string]::IsNullOrWhiteSpace($content)) {
            continue
        }

        $sectionTextList.Add("$heading`n`n$content")
    }

    return ($sectionTextList -join "`n`n").Trim()
}
