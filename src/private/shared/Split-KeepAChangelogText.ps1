function Split-KeepAChangelogText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $footerPattern = '(?ms)(?<footer>(?:^\[[^\]]+\]:[^\r\n]*(?:\r?\n(?:[ \t]*\r?\n)*)?)+)\s*\z'
    $footerMatch = [regex]::Match($Text, $footerPattern)

    if ($footerMatch.Success) {
        return [pscustomobject]@{
            Body   = $Text.Substring(0, $footerMatch.Index).TrimEnd()
            Footer = $footerMatch.Groups['footer'].Value.TrimEnd()
        }
    }

    return [pscustomobject]@{
        Body   = $Text.TrimEnd()
        Footer = ''
    }
}
