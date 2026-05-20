---
document type: cmdlet
external help file: KeepAChangelog-Help.xml
HelpUri: ''
Locale: en-US
Module Name: KeepAChangelog
ms.date: 05/02/2026
PlatyPS schema version: 2024-05-01
title: Initialize-KeepAChangelogFile
---

# Initialize-KeepAChangelogFile

## SYNOPSIS

Initializes a Keep a Changelog template.

## SYNTAX

### __AllParameterSets

```text
PS> Initialize-KeepAChangelogFile [-Path <string>] -RepositoryUrl <string> [-RepositoryProvider <string>] [-RepositoryTargetReference <string>] [-PreviousReleaseReference <string>] [-SectionHeading <string[]>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Initialize-KeepAChangelogFile` writes a markdown changelog template with:

- the standard introduction text
- a `## [Unreleased]` section
- default subsection headings
- a footer `[Unreleased]` compare link when `-PreviousReleaseReference` is provided

Use `-Force` when you want to overwrite an existing file.

When new footer links must be generated:

- GitHub uses `/compare/<previous>...HEAD`
- GitLab uses `/-/compare/<previous>...HEAD`
- Azure DevOps uses `/branchCompare?baseVersion=<previous>&targetVersion=<target>&_a=commits`

Use `-RepositoryProvider` when the repository host alone is not enough to identify the provider, and use `-RepositoryTargetReference` for Azure DevOps target refs such as `GBmain` or `GBdevelop`.

## EXAMPLES

### EXAMPLE 1

```text
PS> Initialize-KeepAChangelogFile -Path ./CHANGELOG.md -RepositoryUrl https://github.com/couragedk/KeepAChangelog -PreviousReleaseReference develop
```

Creates `CHANGELOG.md` with an `[Unreleased]` compare link that starts from `develop`.

### EXAMPLE 2

```text
PS> Initialize-KeepAChangelogFile -Path ./CHANGELOG.md -RepositoryUrl https://code.example.com/group/project -RepositoryProvider GitLab -PreviousReleaseReference 1.5.2
```

Creates a changelog for a self-hosted GitLab repository by using the explicit provider hint.

### EXAMPLE 3

```text
PS> Initialize-KeepAChangelogFile -Path ./CHANGELOG.md -RepositoryUrl https://ado.example.com/Org/Project/_git/Tools -RepositoryProvider AzureDevOps -RepositoryTargetReference GBdevelop -PreviousReleaseReference GTv1.5.2
```

Creates a changelog for Azure DevOps by using the supplied release reference as `baseVersion` and the target ref as `targetVersion`.

## PARAMETERS

### -Path

Target changelog path. Defaults to `CHANGELOG.md`.

### -RepositoryUrl

Repository base URL used to build compare links.

GitHub repository URLs generate `/compare/` links. GitLab repository URLs like
`https://gitlab.com/group/project` generate `/-/compare/` links.

### -RepositoryProvider

Optional provider hint used when `-RepositoryUrl` alone is not enough to infer the compare-link format.

Supported values are `GitHub`, `GitLab`, and `AzureDevOps`.

Use `GitLab` for self-hosted GitLab URLs that do not contain `gitlab` in the hostname. Use `AzureDevOps` for Azure DevOps repository URLs when you want the cmdlet to generate `branchCompare` links explicitly.

### -RepositoryTargetReference

Optional target ref used when Azure DevOps footer links must be generated.

Examples include `GBmain` and `GBdevelop`.

### -PreviousReleaseReference

Optional release reference used as the starting point for `[Unreleased]`.

Valid values include release tags, commit SHAs, and branch refs such as `main` or `develop`.

For Azure DevOps, this value is used literally as the compare-link `baseVersion`, so pass the exact ref token that your repository expects, for example `GTv1.5.2`.

### -SectionHeading

The subsection headings created below `## [Unreleased]`.

### -Force

Overwrite the target file if it already exists.

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm.
