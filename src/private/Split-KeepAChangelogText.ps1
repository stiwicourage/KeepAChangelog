function Split-KeepAChangelogText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $footerMatch = [regex]::Match($Text, '(?ms)(?<footer>(?:^\[[^\]]+\]:[^\r\n]*(?:\r?\n|$))+)\s*\z')

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
