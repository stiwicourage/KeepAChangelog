function Assert-KeepAChangelogRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Release
    )

    $requiredKeyList = @('Version', 'Date', 'Tag')

    foreach ($requiredKey in $requiredKeyList) {
        if (-not $Release.ContainsKey($requiredKey)) {
            throw "Release.$requiredKey is required."
        }

        if ([string]::IsNullOrWhiteSpace([string]$Release[$requiredKey])) {
            throw "Release.$requiredKey is required."
        }
    }

    return [pscustomobject]@{
        Version = [string]$Release.Version
        Date    = [string]$Release.Date
        Tag     = [string]$Release.Tag
    }
}
