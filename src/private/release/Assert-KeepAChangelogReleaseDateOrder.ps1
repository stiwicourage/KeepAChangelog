function Get-KeepAChangelogLatestReleaseDate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )

    $latestReleaseDate = $null
    foreach ($match in [regex]::Matches($Body, '(?m)^## \[[^\]]+\] - (?<date>\d{4}-\d{2}-\d{2})$')) {
        $releaseDate = [datetime]::ParseExact(
            $match.Groups['date'].Value,
            'yyyy-MM-dd',
            [System.Globalization.CultureInfo]::InvariantCulture
        )

        if ($null -eq $latestReleaseDate -or $releaseDate -gt $latestReleaseDate) {
            $latestReleaseDate = $releaseDate
        }
    }

    if ($null -eq $latestReleaseDate) {
        return $null
    }

    return $latestReleaseDate.ToString('yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Assert-KeepAChangelogReleaseDateOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body,
        [Parameter(Mandatory)]
        [pscustomobject]$Release
    )

    $latestExistingReleaseDate = Get-KeepAChangelogLatestReleaseDate -Body $Body
    if ([string]::IsNullOrWhiteSpace($latestExistingReleaseDate)) {
        return
    }

    $releaseDate = [datetime]::ParseExact(
        $Release.Date,
        'yyyy-MM-dd',
        [System.Globalization.CultureInfo]::InvariantCulture
    )
    $latestReleaseDate = [datetime]::ParseExact(
        $latestExistingReleaseDate,
        'yyyy-MM-dd',
        [System.Globalization.CultureInfo]::InvariantCulture
    )

    if ($releaseDate -lt $latestReleaseDate) {
        throw "Release.Date '$($Release.Date)' cannot be earlier than latest existing release date '$latestExistingReleaseDate'."
    }
}
