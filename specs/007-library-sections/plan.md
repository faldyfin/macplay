# Implementation Plan: Library Sections

**Branch**: `007-library-sections` (work lands on `main`) | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-library-sections/spec.md`

## Summary

Fold the Steam games list ("My games") into the Steam section, give every program installed from a
setup file a category (Game or App) stored in its wrapper, and split the old "Windows apps" section
into **My Games** and **My Apps**, both built from the same view filtered by category. TapTap is
moved to My Games. See [research.md](research.md) for the decisions.

## Technical Context

**Language/Version**: Swift 6.4 toolchain, Swift 5 language mode (`swift-tools-version:5.9`)

**Primary Dependencies**: SwiftUI and AppKit only (constitution I)

**Storage**: each wrapper's `Contents/Info.plist` (new key `MacPlay Category`); no new files

**Testing**: no test target in the package; verification is a release build plus running the app
(constitution VI), following [quickstart.md](quickstart.md)

**Target Platform**: macOS 14.6+ on Apple Silicon

**Project Type**: desktop app (single SwiftUI executable, `app/`)

**Performance Goals**: the Steam section stays responsive with its 3 s status refresh; the games
list is read when the section opens and when Steam stops

**Constraints**: no change to how programs run; existing wrappers keep working without migration

**Scale/Scope**: 5 sidebar sections; a handful of programs and Steam games per user

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|---|---|---|
| I. Native and dependency-free | SwiftUI/AppKit only | Pass |
| II. User's folders only | writes only the wrapper's own plist in `~/Applications/Sikarugir` | Pass |
| III. Pinned downloads | no downloads added | Pass (n/a) |
| IV. Reversible, opt-in changes | category is a label; changing it back restores the old state | Pass |
| V. Honest compatibility info | no rating data changes | Pass (n/a) |
| VI. Verified behaviour | build + run the quickstart scenarios, check TapTap under My Games | Pass (planned) |
| VII. Bilingual UI, docs in sync | new strings via `L.t(en, fr)`; README and specs 001/003/005/006 updated to the new names; Indonesian follows in 008 | Pass |

Post-design re-check: unchanged, all pass.

## Project Structure

### Documentation (this feature)

```text
specs/007-library-sections/
├── plan.md              # this file
├── research.md          # Phase 0 decisions
├── data-model.md        # Phase 1: program category
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── navigation.md    # Phase 1: sidebar and screen contract
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
app/Sources/MacPlay/
├── MacPlayApp.swift     # sidebar: dashboard, steam, games, myGames, myApps
├── SteamView.swift      # + installed Steam games list, navigation to InstalledDetail
├── InstalledView.swift  # keeps InstalledDetail; the standalone list view is removed
├── AppsView.swift       # AppsView(category:), category picker in install panel and AppDetail
└── WindowsApps.swift    # WindowsApp.category, read/write `MacPlay Category`, install(category:)
README.md                # section names
specs/00{1,3,5,6}-*/     # section names in earlier specs
```

**Structure Decision**: single desktop app; all changes stay inside the existing five source files.

## Complexity Tracking

No constitution violations; nothing to justify.
