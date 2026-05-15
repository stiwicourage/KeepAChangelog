# 02. Changelog format rules

## Required structure

Every managed changelog must contain:

1. A top-level `## [Unreleased]` section.
2. A footer reference link for `[Unreleased]` once the changelog has a previous release reference or at least one released version.
3. Versioned release headings in the form `## [<version>] - <date>`.

## Required compare link

After the first release, the footer must include:

```markdown
[Unreleased]: https://github.com/<owner>/<repo>/compare/<previous>...HEAD
```

Footer reference links may be written as one compact block or with blank lines between the links. Both layouts are valid as long as the footer only contains reference-link lines.

When the compare link exists, the module extracts:

- The compare-link prefix up to `/compare/`
- The previous release reference between `/compare/` and `...HEAD`

Valid previous release references include:

- a release tag such as `1.0.0`
- a commit SHA
- a branch such as `main` or `develop`

## Release parameter contract

Release promotion requires:

```powershell
Move-UnreleasedChangelog -Version '1.6.0' -Date '2026-04-30'
```

- `Version` is required
- `Date` is optional
- `Tag` is derived from `Version`
- when `Date` is omitted, the current date is used
- when `Date` is provided, it must use `yyyy-MM-dd`

For a first release without an existing footer compare link, the release command needs a repository URL so it can add the initial footer links.

## Section handling rules

1. Unreleased content is moved, not copied.
2. Empty `###` subsections stay in `Unreleased`.
3. Empty `###` subsections are removed from the new release notes.
4. Simple changelog text without `###` subsections is preserved as-is.
