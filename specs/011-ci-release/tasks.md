# Tasks: CI and Manual DMG Releases

**Input**: Design documents from `/specs/011-ci-release/`
**Prerequisites**: plan.md, spec.md, research.md, contracts/workflows.md, quickstart.md

**Tests**: requested ("CI unit test"): Swift tests for the app's pure logic, Python tests for the
version script.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Resolve pins (research.md): commit SHAs of checkout v7.0.1, upload-artifact v7.0.1, codeql-action v4.38.2; Trivy v0.74.0 tarball SHA-256 against its checksums file

## Phase 2: User Story 2 - The version follows the commits (P1)

- [X] T002 [P] [US2] `tools/next_version.py`: last `v*` tag, commits since, "breaking → major, `feat` → minor, `fix`/`perf`/`revert` → patch; other types release nothing", notes grouped by kind, exit 1 when nothing to release
- [X] T003 [P] [US2] `tools/tests/test_next_version.py`: classification, bump rules, pre-release base, notes, a throwaway git repository
- [X] T004 [US2] `app/build.sh`: `MACPLAY_VERSION` (else the last tag) into `CFBundleShortVersionString`, the commit count into `CFBundleVersion`

## Phase 3: User Story 1 - Publish a release by hand (P1) 🎯 MVP

- [X] T005 [US1] `app/make_dmg.sh <version>`: app + Applications link, UDZO, `.sha256`
- [X] T006 [US1] `.github/workflows/release.yml` per contracts/workflows.md

## Phase 4: User Story 3 - Every change is checked (P2)

- [X] T007 [P] [US3] Test target `MacPlayTests` in `app/Package.swift` and `app/Tests/MacPlayTests/`
- [X] T008 [P] [US3] `.github/workflows/ci.yml` per contracts/workflows.md
- [X] T009 [P] [US3] `.github/dependabot.yml`: github-actions, weekly, `cooldown: default-days: 7`, `ci(deps)` messages

## Phase 5: Polish

- [X] T010 [P] README: install from releases with the checksum, tests, CI, releases
- [X] T011 [P] Constitution 1.3.0: release and CI rules, Dependabot cooldown, pinned Trivy
- [X] T012 Local validation: quickstart steps 1–2
- [X] T013 CI validation after push: quickstart steps 3–4 (2026-10-02: CI green on Swift 6.3.3 / Xcode 26.6, Trivy analysis with 0 results in code scanning; test Release run built MacPlay-1.0.0.dmg, build 43, checksum and signature verified, nothing published)
- [ ] T014 First release by the maintainer: quickstart steps 5–6; then set `**Status**` to Implemented in `specs/011-ci-release/spec.md`

## Dependencies

T001 → T002–T004 → T005–T006; T007–T009 independent; T013 needs a push; T014 needs T013.
