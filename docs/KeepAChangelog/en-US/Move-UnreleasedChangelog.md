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
PS> Move-UnreleasedChangelog [-Path <string>] -Version <string> [-Date <string>] [-RepositoryUrl <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Move-UnreleasedChangelog` treats `## [Unreleased]` as the source section for the next release.

The command:

1. reads the current unreleased content
2. removes empty `###` subsections from the new release notes
3. inserts `## [<version>] - <date>` below `## [Unreleased]`
4. clears `Unreleased` while keeping subsection headings
5. updates the `[Unreleased]` compare link to `<tag>...HEAD`
6. adds or updates the `[<version>]` release link from the previous release reference to the new tag

`-Version` is required. `-Date` is optional. When `-Date` is omitted, the current date is used. When `-Date` is provided, it must use `yyyy-MM-dd` format.

If the changelog has no footer yet because it started as a brand-new project, pass `-RepositoryUrl` on the first release so the footer links can be created.

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
PS> Move-UnreleasedChangelog -Path ./CHANGELOG.md -Version 1.0.0 -RepositoryUrl https://github.com/couragedk/KeepAChangelog
```

Creates the first release and adds the initial footer links for a changelog that did not have a previous release reference.

## PARAMETERS

### -Path

Target changelog path. Defaults to `CHANGELOG.md`.

### -Version

Release version. The same value is also used as the release tag.

### -Date

Optional release date in `yyyy-MM-dd` format.

### -RepositoryUrl

Optional repository base URL used to create footer links on the first release when the changelog has no `[Unreleased]` compare link yet.

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm.
