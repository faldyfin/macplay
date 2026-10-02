# Implementation Plan: CI and Manual DMG Releases

**Branch**: `011-ci-release` (work lands on `main`) | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/011-ci-release/spec.md`

## Summary

Three workflows and a script. `ci.yml` builds and tests the app on macOS, tests the tools on
Ubuntu and runs a pinned, checksum-verified Trivy. `release.yml` runs only by hand: it computes the
version with `tools/next_version.py`, tests, builds with `app/build.sh` (now stamping the version),
packages with `app/make_dmg.sh`, and publishes with `gh release create` when the input is
`release`, else uploads the DMG as a test artifact. `dependabot.yml` updates the action pins with a
7-day cooldown. The app gains its first test target. Decisions in [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.x toolchain (Swift 5 mode); Python 3.12 standard library; bash

**Primary Dependencies**: none new; CI uses `actions/checkout`, `actions/upload-artifact`,
`github/codeql-action/upload-sarif` (SHA-pinned) and the Trivy binary (pinned + SHA-256)

**Storage**: n/a

**Testing**: XCTest target `MacPlayTests` (`swift test`); `unittest` for `tools/`

**Target Platform**: GitHub-hosted `macos-26` and `ubuntu-24.04`

**Project Type**: desktop app + CI

**Constraints**: org supply-chain policy (SHA pins, 7-day release age, cooldown); constitution I
(standard library only for scripts) and III (pinned, verified downloads)

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I. Native and dependency-free | no packages; scripts stdlib/bash | Pass |
| II. User's folders only | CI only; the app is unchanged | Pass (n/a) |
| III. Pinned, verified downloads | actions SHA-pinned; Trivy pinned and checksum-checked | Pass |
| VI. Verified behaviour | script and DMG verified locally; CI verified by a test run | Pass (planned) |
| VII. Docs in sync | README: install from releases, tests, CI, releases | Pass |
| Development workflow | release and CI rules added (MINOR 1.3.0) | Pass after amendment |

## Project Structure

```text
.github/workflows/ci.yml, release.yml      # NEW
.github/dependabot.yml                     # NEW
tools/next_version.py, tools/tests/        # NEW
app/build.sh                               # version and build number in Info.plist
app/make_dmg.sh                            # NEW
app/Package.swift, app/Tests/MacPlayTests/ # NEW test target
README.md, .specify/memory/constitution.md
```

## Complexity Tracking

No violations.
