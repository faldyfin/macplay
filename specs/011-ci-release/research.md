# Research: CI and Manual DMG Releases

## Versioning

- **Decision**: own script, `tools/next_version.py` (standard library): last `v*` tag, commits since
  (`git log --no-merges`), breaking → major, `feat` → minor, `fix`/`perf`/`revert` → patch; a
  pre-release suffix on the base tag is dropped. Notes grouped by kind with short SHAs.
- **Rationale**: constitution I (no packages); semantic-release would need Node and plugins.
- **Check** (2026-10-02): on this repository it gives 1.0.0 (one `feat!` since v0.1.0-alpha), with
  1 breaking change, 15 features and 5 fixes in the notes.

## Runners and toolchain

- **Decision**: `macos-26` (arm64) with `DEVELOPER_DIR=/Applications/Xcode_26.6.app`.
- **Rationale**: the runner-images README lists Xcode 26.6 as the default on `macos-26` (image
  20260907); `xcode-27` (Xcode 27.0, as used locally) is labelled preview. GitHub CLI 2.100 and
  Python 3.12 are on the images.

## Trivy

- **Decision**: download the v0.74.0 Linux tarball (released 2026-08-14) and check SHA-256
  `2ae6fe3e…371a` (matches `trivy_0.74.0_checksums.txt`, checked 2026-10-02); no `trivy-action`.
- **Rationale**: in March 2026 the Trivy supply chain was compromised (GHSA-69fq-xp46-6x23 /
  CVE-2026-33634): malicious v0.69.4–v0.69.6, 76 of 77 `trivy-action` tags force-pushed, all
  `setup-trivy` tags replaced. v0.75.0 (2026-10-01) is under the 7-day rule.
- **Scan today**: no dependency manifests or config files Trivy reads, so the useful part is the
  secret scan (clean locally); it starts covering dependencies when any appear.

## Pins

| Action | Version | Commit |
|---|---|---|
| actions/checkout | v7.0.1 | 3d3c42e5aac5ba805825da76410c181273ba90b1 |
| actions/upload-artifact | v7.0.1 | 043fb46d1a93c77aae656e7c1c64a875d1fc6a0a |
| github/codeql-action/upload-sarif | v4.38.2 (2026-09-24) | 2892aa5e19bbd11bc0cff5427e3b750a04d9e3c2 |

## Dependabot

- **Decision**: `github-actions`, weekly, `cooldown: default-days: 7`, `commit-message: prefix: ci,
  include: scope` → `ci(deps): …`, which releases nothing.
- **Rationale**: GitHub's options reference lists GitHub Actions among the ecosystems supporting
  `default-days` (docs source, read 2026-10-02). The Swift package and the tools have no
  dependencies; the Trivy version is bumped by hand.

## Tests

- **Decision**: an XCTest target importing the executable (`@testable import MacPlay`), checked to
  work with SwiftPM on 2026-10-02. Pure logic only: image intake, the artwork store in a temporary
  folder, play-time rename and formatting, the featured game, the bundled lists.
