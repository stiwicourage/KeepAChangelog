---
document type: cmdlet
external help file: KeepAChangelog-Help.xml
HelpUri: ''
Locale: en-US
Module Name: KeepAChangelog
ms.date: 05/02/2026
PlatyPS schema version: 2024-05-01
title: Move-UnreleasedChangelog
---

# Move-UnreleasedChangelog

## SYNOPSIS

Moves `Unreleased` notes into a versioned release section.

## SYNTAX

### __AllParameterSets

```text
PS> Move-UnreleasedChangelog [-Path <string>] -Version <string> [-Date <string>] [-RepositoryUrl <string>] [-RepositoryProvider <string>] [-RepositoryTargetReference <string>] [-ReleaseReference <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Move-UnreleasedChangelog` treats `## [Unreleased]` as the source section for the next release.

The command:

1. reads the current unreleased content
2. removes empty `###` subsections from the new release notes
3. inserts `## [<version>] - <date>` below `## [Unreleased]`
4. clears `Unreleased` while keeping subsection headings
5. updates the `[Unreleased]` compare link when a reference-link footer exists or `-RepositoryUrl` is supplied
6. adds or updates the `[<version>]` release link from the previous release reference to the new release reference when footer links are being maintained

`-Version` is required. `-Date` is optional. When `-Date` is omitted, the current date is used. When `-Date` is provided, it must use `yyyy-MM-dd` format.

If the changelog has no footer and you want footer links to be created or maintained, pass `-RepositoryUrl`. If you omit it, the release move still runs and the changelog stays without footer links.

When new footer links must be generated:

- GitHub uses `/compare/<previous>...HEAD` and `/releases/tag/<release>`
- GitLab uses `/-/compare/<previous>...HEAD` and `/-/tags/<release>`
- Azure DevOps uses `/branchCompare?baseVersion=<previous>&targetVersion=<target>&_a=commits`

The returned object also includes `KeepAChangelogVersion` so CI logs and troubleshooting output
can show which module version produced the release data.

## EXAMPLES

### EXAMPLE 1

```text
PS> Move-UnreleasedChangelog -Path ./CHANGELOG.md -Version 1.6.0 -Date 2026-04-30
```

Promotes the current unreleased notes into release `1.6.0`.

### EXAMPLE 2

```text
PS> Move-UnreleasedChangelog -Path ./CHANGELOG.md -Version 1.0.0 -RepositoryUrl https://code.example.com/group/project -RepositoryProvider GitLab
```

Creates the first release and adds GitLab footer links for a self-hosted GitLab repository.

### EXAMPLE 3

```text
PS> Move-UnreleasedChangelog -Path ./CHANGELOG.md -Version 13.0.4 -RepositoryUrl https://ado.example.com/Org/Project/_git/Tools -RepositoryProvider AzureDevOps -RepositoryTargetReference GBdevelop -ReleaseReference GTv13.0.4
```

Creates Azure DevOps footer links by using `GTv13.0.4` as the release ref and `GBdevelop` as the ongoing unreleased target ref.

## PARAMETERS

### -Path

Target changelog path. Defaults to `CHANGELOG.md`.

### -Version

Release version. The same value is also used as the release tag.

### -Date

Optional release date in `yyyy-MM-dd` format.

### -RepositoryUrl

Optional repository base URL used to create or maintain footer links when the changelog has no `[Unreleased]` compare link yet.

GitHub repository URLs generate `/compare/` and `/releases/tag/` links. GitLab repository URLs generate `/-/compare/` and `/-/tags/` links. Azure DevOps repository URLs generate `branchCompare` links.

### -RepositoryProvider

Optional provider hint used when `-RepositoryUrl` must generate new footer links and the host name does not identify the provider clearly.

Supported values are `GitHub`, `GitLab`, and `AzureDevOps`.

Use `GitLab` for self-hosted GitLab repository URLs and `AzureDevOps` when you want the cmdlet to generate Azure DevOps `branchCompare` links explicitly.

### -RepositoryTargetReference

Optional target ref used when Azure DevOps `[Unreleased]` footer links must be generated.

Examples include `GBmain` and `GBdevelop`.

### -ReleaseReference

Optional release ref written into generated footer links when it differs from `-Version`.

Use this for providers such as Azure DevOps when the visible changelog version is `13.0.4` but the compare-link release ref must be something like `GTv13.0.4`.

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm.
