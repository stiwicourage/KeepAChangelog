function Read-KeepAChangelogProjectVersion {
    [CmdletBinding()]
    param()

    $projectJsonPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..' '..' '..' 'project.json'))
    $project = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json
    return [string]$project.Version
}

function Get-KeepAChangelogModuleVersion {
    [CmdletBinding()]
    param()

    $module = $ExecutionContext.SessionState.Module
    if ($null -ne $module -and $module.Name -eq 'KeepAChangelog' -and $null -ne $module.Version) {
        return $module.Version.ToString()
    }

    return Read-KeepAChangelogProjectVersion
}
