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
PS> Initialize-KeepAChangelogFile [-Path <string>] -RepositoryUrl <string> [-RepositoryProvider <string>] [-PreviousReleaseReference <string>] [-SectionHeading <string[]>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Initialize-KeepAChangelogFile` writes a markdown changelog template with:

- the standard introduction text
- a `## [Unreleased]` section
- default subsection headings
- a footer `[Unreleased]` compare link when `-PreviousReleaseReference` is provided

Use `-Force` when you want to overwrite an existing file.

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

## PARAMETERS

### -Path

Target changelog path. Defaults to `CHANGELOG.md`.

### -RepositoryUrl

Repository base URL used to build compare links.

GitHub repository URLs generate `/compare/` links. GitLab repository URLs like
`https://gitlab.com/group/project` generate `/-/compare/` links.

### -RepositoryProvider

Optional provider hint used when `-RepositoryUrl` alone is not enough to infer the compare-link format.

Use `GitLab` for self-hosted GitLab URLs that do not contain `gitlab` in the hostname.

### -PreviousReleaseReference

Optional release reference used as the starting point for `[Unreleased]`.

Valid values include release tags, commit SHAs, and branch refs such as `main` or `develop`.

### -SectionHeading

The subsection headings created below `## [Unreleased]`.

### -Force

Overwrite the target file if it already exists.

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable, -WhatIf, and -Confirm.
