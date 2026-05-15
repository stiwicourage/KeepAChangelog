---
document type: cmdlet
external help file: KeepAChangelog-Help.xml
HelpUri: ''
Locale: en-US
Module Name: KeepAChangelog
ms.date: 04/30/2026
PlatyPS schema version: 2024-05-01
title: Test-KeepAChangelogFile
---

# Test-KeepAChangelogFile

## SYNOPSIS

Validates a Keep a Changelog file.

## SYNTAX

### __AllParameterSets

```text
PS> Test-KeepAChangelogFile [-Path <string>] [-ThrowOnError] [<CommonParameters>]
```

## DESCRIPTION

`Test-KeepAChangelogFile` reads a changelog and validates:

- the presence of `## [Unreleased]`
- the `[Unreleased]` compare link when a reference-link footer is present, even if blank lines separate the footer links
- versioned release headings in `## [<version>] - <date>` format
- duplicate reference-link labels

It returns a result object with `IsValid`, `Errors`, and extracted compare-link values.

## EXAMPLES

### EXAMPLE 1

```text
PS> Test-KeepAChangelogFile -Path ./CHANGELOG.md
```

Returns the validation result for the current changelog file.

## PARAMETERS

### -Path

Target changelog path. Defaults to `CHANGELOG.md`.

### -ThrowOnError

Throw when validation fails instead of only returning the result object.

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable.
