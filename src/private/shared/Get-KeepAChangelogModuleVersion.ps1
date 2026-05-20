function Read-KeepAChangelogProjectVersion {
    [CmdletBinding()]
    param()

    $projectJsonPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..' '..' '..' 'project.json'))
    $project = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json
    return [string]$project.Version
}

function Get-KeepAChangelogLoadedModuleVersion {
    [CmdletBinding()]
    param()

    $module = $ExecutionContext.SessionState.Module
    if ($null -eq $module) {
        return $null
    }

    if ($module.Name -ne 'KeepAChangelog') {
        return $null
    }

    if ($null -eq $module.Version) {
        return $null
    }

    return $module.Version.ToString()
}

function Get-KeepAChangelogModuleVersion {
    [CmdletBinding()]
    param()

    $loadedModuleVersion = Get-KeepAChangelogLoadedModuleVersion
    if (-not [string]::IsNullOrWhiteSpace($loadedModuleVersion)) {
        return $loadedModuleVersion
    }

    return Read-KeepAChangelogProjectVersion
}
