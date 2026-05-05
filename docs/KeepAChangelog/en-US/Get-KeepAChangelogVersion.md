---
document type: cmdlet
external help file: KeepAChangelog-Help.xml
HelpUri: ''
Locale: en-US
Module Name: KeepAChangelog
ms.date: 05/05/2026
PlatyPS schema version: 2024-05-01
title: Get-KeepAChangelogVersion
---

# Get-KeepAChangelogVersion

## SYNOPSIS

Returns the loaded KeepAChangelog module version.

## SYNTAX

### __AllParameterSets

```text
PS> Get-KeepAChangelogVersion [<CommonParameters>]
```

## DESCRIPTION

`Get-KeepAChangelogVersion` returns the version of the currently loaded `KeepAChangelog`
module.

Use it in CI logs or local troubleshooting when you need to confirm which module version
produced a release or validation result.

## EXAMPLES

### EXAMPLE 1

```text
PS> Get-KeepAChangelogVersion
```

Returns the version string for the loaded `KeepAChangelog` module.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, -WarningVariable.
