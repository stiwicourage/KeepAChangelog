param(
    [string]$OutputDirectory = './artifacts',
    [string[]]$ExcludeTag = @()
)

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'CoverageLowReport.ps1')

function Get-CiTestPath {
    param([Parameter(Mandatory)][pscustomobject]$ProjectInfo)

    if ($ProjectInfo.BuildRecursiveFolders) {
        return $ProjectInfo.TestsDir
    }

    return [System.IO.Path]::Join($ProjectInfo.TestsDir, '*.Tests.ps1')
}

function Get-CiPesterConfiguration {
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$ArtifactsDirectory,
        [string[]]$ExcludedTags = @()
    )

    $sourceModulePath = Join-Path $ProjectInfo.ProjectRoot 'src' "$($ProjectInfo.ProjectName).psm1"
    if (-not (Test-Path -LiteralPath $sourceModulePath)) {
        throw "Could not find source module file for coverage at '$sourceModulePath'."
    }

    $configuration = New-PesterConfiguration
    $configuration.Run.Path = Get-CiTestPath -ProjectInfo $ProjectInfo
    $configuration.Run.PassThru = $true
    $configuration.Filter.ExcludeTag = @($ExcludedTags)
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = 'JUnitXml'
    $configuration.TestResult.OutputPath = (Join-Path $ArtifactsDirectory 'pester-junit.xml')
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = @($sourceModulePath)
    $configuration.CodeCoverage.OutputFormat = 'Cobertura'
    $configuration.CodeCoverage.OutputPath = (Join-Path $ArtifactsDirectory 'pester-coverage.cobertura.xml')

    return $configuration
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..' '..')).Path
Set-Location $repoRoot
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

Import-Module NovaModuleTools -ErrorAction Stop
Import-Module Pester -ErrorAction Stop

Invoke-NovaBuild

$projectInfo = Get-NovaProjectInfo

$configuration = Get-CiPesterConfiguration -ProjectInfo $projectInfo -ArtifactsDirectory $OutputDirectory -ExcludedTags $ExcludeTag
$result = Invoke-Pester -Configuration $configuration
Write-CoverageLowReport -CoveragePath (Join-Path $OutputDirectory 'pester-coverage.cobertura.xml') -OutputPath (Join-Path $OutputDirectory 'coverage-low.txt')

if ($result.FailedCount -gt 0) {
    exit 1
}
