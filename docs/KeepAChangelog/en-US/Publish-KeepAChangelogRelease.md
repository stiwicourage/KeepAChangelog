---
document type: cmdlet
external help file: KeepAChangelog-Help.xml
HelpUri: ''
Locale: en-US
Module Name: KeepAChangelog
ms.date: 04/30/2026
PlatyPS schema version: 2024-05-01
title: Publish-KeepAChangelogRelease
---

# Publish-KeepAChangelogRelease

## SYNOPSIS

Promotes `Unreleased` notes into a versioned release section.

## SYNTAX

### __AllParameterSets

```text
PS> Publish-KeepAChangelogRelease [-Path <string>] -Release <hashtable> [-RepositoryUrl <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Publish-KeepAChangelogRelease` treats `## [Unreleased]` as the source section for the next release.

The command:

1. reads the current unreleased content
2. removes empty `###` subsections from the new release notes
3. inserts `## [<version>] - <date>` below `## [Unreleased]`
4. clears `Unreleased` while keeping subsection headings
5. updates the `[Unreleased]` compare link to `<tag>...HEAD`
6. adds or updates the `[<version>]` release link from the previous release reference to the new tag

If the changelog has no footer yet because it started as a brand-new project, pass `-RepositoryUrl` on the first release so the footer links can be created.

The `Release` hashtable must contain `Version`, `Date`, and `Tag`.

## EXAMPLES

### EXAMPLE 1

```text
PS> Publish-KeepAChangelogRelease -Path ./CHANGELOG.md -Release @{ Version = '1.6.0'; Date = '2026-04-30'; Tag = '1.6.0' }
```

Promotes the current unreleased notes into release `1.6.0`.

### EXAMPLE 2

```text
PS> Publish-KeepAChangelogRelease -Path ./CHANGELOG.md -Release @{ Version = '1.0.0'; Date = '2026-05-01'; Tag = '1.0.0' } -RepositoryUrl https://github.com/couragedk/KeepAChangelog
```

Creates the first release and adds the initial footer links for a changelog that did not have a previous release reference.

## PARAMETERS

### -Path

Target changelog path. Defaults to `CHANGELOG.md`.

### -Release

Hashtable with `Version`, `Date`, and `Tag`.

### -RepositoryUrl

Optional repository base URL used to create footer links on the first release when the changelog has no `[Unreleased]` compare link yet.

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm.
