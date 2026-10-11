# Implementation Plan: MSI Installers

**Branch**: `012-msi-installer` (work lands on `main`) | **Date**: 2026-10-11 | **Spec**: [spec.md](spec.md)

## Summary

The install flow stays the same; only the installer command changes for `.msi`: `wine msiexec /i
Z:\…\package.msi /l*v Z:\…\<name>-install-msi.log`. The picker accepts `.msi`, the texts say ".exe
or .msi", and failure messages point to the Windows Installer log. Decisions in
[research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.x toolchain, Swift 5 mode

**Primary Dependencies**: none new; `msiexec` ships inside the wrapper's Wine

**Storage**: the Windows Installer log in `~/Library/Caches/macplay` next to the install log

**Testing**: unit tests for the installer command and path conversion; a quiet install of 7-Zip's
`.msi` into a throwaway wrapper; the [quickstart](quickstart.md) with the player

**Constraints**: all text in EN/FR/ID

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I. Native and dependency-free | no new binaries; msiexec is Wine's | Pass |
| II. User's folders only | the log goes to `~/Library/Caches/macplay` | Pass |
| III. Pinned, verified downloads | nothing new is downloaded | Pass (n/a) |
| VI. Verified behaviour | real `.msi` installed in a throwaway wrapper | Pass (planned) |
| VII. Multilingual, docs in sync | texts in three languages; README | Pass |

## Project Structure

```text
app/Sources/MacPlay/WindowsApps.swift   # installer command, Windows paths, MSI log, program picking
app/Sources/MacPlay/AppsView.swift      # picker types and texts
app/Tests/MacPlayTests/InstallerTests.swift
README.md, specs/001-windows-apps/spec.md
```

## Complexity Tracking

No violations.
