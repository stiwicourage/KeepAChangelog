function Get-KeepAChangelogProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StartPath
    )

    $currentPath = (Resolve-Path -LiteralPath $StartPath).Path
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $currentPath 'project.json')) {
            return $currentPath
        }

        $parentPath = Split-Path -Parent $currentPath
        if ($parentPath -eq $currentPath) {
            throw "Could not find project.json from '$StartPath'."
        }

        $currentPath = $parentPath
    }
}
