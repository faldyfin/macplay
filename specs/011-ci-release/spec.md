# Feature Specification: CI and Manual DMG Releases

**Feature Branch**: `011-ci-release`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description (translated from Indonesian): "Use GitHub Actions to compile/release
the dmg file, but the release is manual, input 'release' manually, and make sure there is
versioning using semantic commits." Then: "Also add CI unit tests, Trivy, and Dependabot."

## Clarifications

### Session 2026-10-02

- Q: First version, given one breaking commit since v0.1.0-alpha? → A: v1.0.0 (strict SemVer).
- Q: How does the manual input work? → A: a text box; typing `release` publishes, anything else
  only builds the DMG as a test.
- Q: Alpha labelling? → A: normal releases (no pre-release mark, no suffix).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publish a release by hand (Priority: P1)

The maintainer opens the Release workflow, types `release` and runs it. A few minutes later a
GitHub release named after the next version exists, with the DMG, its checksum and notes listing
the features, fixes and breaking changes since the last release.

**Why this priority**: it is the request; today there is no downloadable build at all.

**Independent Test**: run the workflow with `release`; download the DMG from the release, check its
checksum, install MacPlay and see the version in About.

**Acceptance Scenarios**:

1. **Given** commits since the last tag, **When** the maintainer runs Release with `release`,
   **Then** a tag `vX.Y.Z` and a release with `MacPlay-X.Y.Z.dmg` and its `.sha256` are published.
2. **Given** the input is empty or anything but `release`, **When** the workflow runs, **Then** it
   builds the DMG and keeps it as a test download for 7 days, and publishes nothing.
3. **Given** only docs, CI or chore commits since the last tag, **When** Release runs, **Then** it
   stops with "nothing to release".
4. **Given** a branch other than main, **When** Release runs with `release`, **Then** it refuses.

---

### User Story 2 - The version follows the commits (Priority: P1)

The version is computed, never typed: a breaking change bumps the major version, a feature the
minor, a fix the patch, following Semantic Versioning and the Conventional Commits the project
already uses. The app shows the same version.

**Independent Test**: compute the version for this repository: v0.1.0-alpha plus one breaking
change gives 1.0.0.

**Acceptance Scenarios**:

1. **Given** v1.4.2 and only fixes since, **Then** the next version is 1.4.3; with a feature,
   1.5.0; with a breaking change, 2.0.0.
2. **Given** a released DMG, **When** MacPlay is installed, **Then** its version is the release's.

---

### User Story 3 - Every change is checked (Priority: P2)

Every push and pull request builds the app, runs the unit tests and scans the repository with
Trivy; findings appear in the repository's Security tab and high or critical ones fail the check.
Dependabot proposes updates for the pinned CI actions, a week after they are released.

**Independent Test**: push a commit; the CI checks run and pass; the Security tab lists the Trivy
analysis.

**Acceptance Scenarios**:

1. **Given** a push or pull request, **Then** CI runs a release build, the Swift and Python unit
   tests and the Trivy scan.
2. **Given** a new version of a pinned action, **Then** Dependabot opens a pull request no sooner
   than 7 days after its release, with a `ci(deps): …` message.

### Edge Cases

- No tag at all: versions start from 0.0.0.
- Commit subjects outside the convention (three old ones): ignored for versioning.
- Running Release twice on the same commit: the second run fails, as the tag exists.
- Trivy's own supply chain was compromised in March 2026 (CVE-2026-33634): Trivy is pinned to a
  post-incident release and checked against its published SHA-256.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Releases MUST only be published by a manual run where the maintainer typed `release`.
- **FR-002**: The version MUST be computed from the Conventional Commits since the last `v*` tag:
  breaking → major, `feat` → minor, `fix`/`perf`/`revert` → patch; other types release nothing.
- **FR-003**: A release MUST contain the DMG (app plus an Applications link) and its SHA-256, and
  notes grouped into breaking changes, features and fixes.
- **FR-004**: The built app MUST carry the release version; local builds carry the last tag's.
- **FR-005**: A run without `release` MUST still build the DMG and keep it as a downloadable test
  artifact.
- **FR-006**: CI MUST run on every push to main and every pull request: release build, Swift and
  Python unit tests, Trivy (vulnerabilities, secrets, misconfigurations) with SARIF results in the
  Security tab; high or critical findings fail it.
- **FR-007**: Dependabot MUST update the pinned GitHub Actions with a 7-day cooldown.
- **FR-008**: Every third-party action MUST be pinned to a commit SHA; Trivy MUST be pinned to a
  release at least 7 days old and verified against its SHA-256.

### Key Entities

- **Release**: tag `vX.Y.Z`, title "MacPlay X.Y.Z", DMG, checksum, notes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A release takes one manual run and one typed word.
- **SC-002**: No version number is typed by hand anywhere.
- **SC-003**: Every push gets a pass/fail result for build, tests and scan.

## Assumptions

- Builds stay unsigned by Apple (ad-hoc signature, not notarized); the README's Gatekeeper step
  still applies.
- GitHub-hosted runners: `macos-26` (Apple Silicon) with Xcode 26.6 for the app, `ubuntu-24.04`
  for the tools and Trivy.
