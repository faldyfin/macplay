# Tasks: Library Sections

**Input**: Design documents from `/specs/007-library-sections/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/navigation.md, quickstart.md

**Tests**: none requested; the package has no test target. Validation is the release build plus the
[quickstart](quickstart.md) scenarios (constitution VI).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on unfinished tasks)
- **[Story]**: US1 Steam games in Steam, US2 My Games / My Apps, US3 sidebar

## Phase 1: Setup

- [X] T001 Confirm a clean baseline: `swift build -c release` in `app/` succeeds and `git status` is clean

## Phase 2: Foundational (blocking for US2)

- [X] T002 Add `enum Category: String { case game, app }` and a `category` field to `WindowsApp` in `app/Sources/MacPlay/WindowsApps.swift`; `WindowsApps.list()` reads `MacPlay Category` from each wrapper's `Info.plist` — "missing or unknown value = `app`"
- [X] T003 Add `WindowsApps.setCategory(_:for:)` in `app/Sources/MacPlay/WindowsApps.swift`, writing only `game` or `app` to `MacPlay Category`
- [X] T004 Give `WindowsApps.install(installer:name:category:emit:done:)` a category and write it "together with the program's name and id, before the installer runs" in `app/Sources/MacPlay/WindowsApps.swift`

**Checkpoint**: programs carry a category; nothing in the UI uses it yet.

## Phase 3: User Story 1 - Steam games live with Steam (P1) 🎯 MVP

**Goal**: installed Steam games are listed in the Steam section and open their game page.

**Independent test**: quickstart scenario 2.

- [X] T005 [US1] Load installed Steam games, their community stats, the known compatibility entries and the hardware profile in `app/Sources/MacPlay/SteamView.swift` (moved from `InstalledView`)
- [X] T006 [US1] Add an "Installed games" box under the Steam box in `app/Sources/MacPlay/SteamView.swift`: one row per game with name, size and rating, an empty state, hidden when Steam is not installed
- [X] T007 [US1] Wrap the Steam section in a `NavigationStack` with `navigationDestination(for: InstalledGame.self)` showing `InstalledDetail` in `app/Sources/MacPlay/SteamView.swift`
- [X] T008 [US1] Re-read the games list whenever Steam goes from running to stopped in `app/Sources/MacPlay/SteamView.swift`
- [X] T009 [US1] Remove the standalone `InstalledView` list from `app/Sources/MacPlay/InstalledView.swift`, keeping `InstalledDetail`
- [X] T010 [US1] Remove the `.installed` ("My games") sidebar section in `app/Sources/MacPlay/MacPlayApp.swift`

**Checkpoint**: Steam games reachable from Steam; old tab gone.

## Phase 4: User Story 2 - Games and apps are kept apart (P1)

**Goal**: My Games and My Apps list programs by category; the category is chosen at install and
changeable later.

**Independent test**: quickstart scenarios 3–6.

- [X] T011 [US2] Make `AppsView` take a `category` and list only matching programs in `app/Sources/MacPlay/AppsView.swift`
- [X] T012 [US2] Add a Category picker (Game / App) to the install form, preset to the section's category, and pass it to `WindowsApps.install` in `app/Sources/MacPlay/AppsView.swift`
- [X] T013 [US2] Add a Category picker to `AppDetail` that calls `WindowsApps.setCategory` and reloads the section list (the program leaves the current section) in `app/Sources/MacPlay/AppsView.swift`
- [X] T014 [US2] Section-specific empty states and placeholder texts for My Games and My Apps in `app/Sources/MacPlay/AppsView.swift`
- [X] T015 [US2] Replace the `.apps` sidebar section with `.myGames` ("My Games" / "Mes jeux") and `.myApps` ("My Apps" / "Mes apps") in `app/Sources/MacPlay/MacPlayApp.swift`
- [X] T016 [US2] Set `MacPlay Category = game` in `~/Applications/Sikarugir/TapTap.app/Contents/Info.plist` (the player's request; data-model "Existing data")

**Checkpoint**: TapTap under My Games; moving programs between sections works.

## Phase 5: User Story 3 - The sidebar says what each section holds (P2)

**Goal**: sidebar order and names per contracts/navigation.md.

**Independent test**: quickstart scenario 1.

- [X] T017 [US3] Order `SidebarSection` as dashboard, steam, games, myGames, myApps with the names from contracts/navigation.md in `app/Sources/MacPlay/MacPlayApp.swift`

## Phase 6: Polish & Cross-Cutting

- [X] T018 Update section names in `README.md` ("My games", "Windows apps", "My games tab")
- [X] T019 [P] Update section names in `specs/001-windows-apps/spec.md`, `specs/003-steam-section/spec.md`, `specs/005-compatibility-list/spec.md`, `specs/006-game-screen/spec.md`
- [X] T020 Build with `./build.sh` in `app/`: no errors, no warnings in changed files
- [X] T021 Update `/Applications/MacPlay.app` in place and open it from Finder
- [X] T022 Run quickstart scenarios 1–6 and record the results — scenarios 3 (data) and 6 pass: the app's own listing code puts TapTap in My Games and the plist holds `game`; on-screen checks reviewed by the player, who approved the commit (2026-10-01)
- [X] T023 Set `**Status**` to Implemented in `specs/007-library-sections/spec.md`
- [X] T024 [US2] Player feedback: in My Games the install button, file prompt and form title say "Install a Windows game" instead of "…program", in `app/Sources/MacPlay/AppsView.swift`
- [X] T025 [US1] Stale text: after a Steam install the log said the game "appears in My games"; it now points to Installed games in the Steam section, in `app/Sources/MacPlay/Engine.swift`

## Dependencies & Execution Order

- Phase 1 → Phase 2 → US1 and US2 (US1 does not need Phase 2) → US3 → Polish.
- US1 and US2 both edit `MacPlayApp.swift` (T010, T015, T017): do those three in order.
- T019 can run alongside T018.

## Parallel Example

```text
T018 README.md   ||   T019 specs/00{1,3,5,6}-*/spec.md
```

## Implementation Strategy

- **MVP**: Phase 3 (US1) alone already removes the duplicate "My games" tab.
- **Then**: Phase 2 + US2 for the categories, US3 for the final sidebar, Polish last.
- Commit per story where it builds on its own (constitution: one change type per commit).
