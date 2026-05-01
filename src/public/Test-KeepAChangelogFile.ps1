function Test-KeepAChangelogFile {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = 'CHANGELOG.md',

        [switch]$ThrowOnError
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Could not find CHANGELOG file at '$Path'."
    }

    $text = Get-Content -LiteralPath $Path -Raw
    $result = Get-KeepAChangelogValidationResult -Text $text
    $result | Add-Member -NotePropertyName Path -NotePropertyValue $Path -Force

    if ($ThrowOnError -and -not $result.IsValid) {
        throw ($result.Errors -join ' ')
    }

    return $result
}
