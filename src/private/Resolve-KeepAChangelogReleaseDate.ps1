function Resolve-KeepAChangelogReleaseDate {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Date
    )

    if ([string]::IsNullOrWhiteSpace($Date)) {
        return (Get-Date).ToString('yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    $parsedDate = [datetime]::MinValue
    $isValidDate = [datetime]::TryParseExact(
        $Date,
        'yyyy-MM-dd',
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$parsedDate
    )

    if (-not $isValidDate) {
        throw "Date must use yyyy-MM-dd format. Received: '$Date'."
    }

    return $parsedDate.ToString('yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
}
