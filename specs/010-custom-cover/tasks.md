# Tasks: Choose a Game's Cover

**Input**: Design documents from `/specs/010-custom-cover/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cover-picker.md, quickstart.md

**Tests**: none requested; validation is the release build, a dry run of the image intake, and the
[quickstart](quickstart.md).

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Confirm a clean baseline: `swift build -c release` in `app/` succeeds

## Phase 2: Foundational

- [X] T002 Create `app/Sources/MacPlay/ChosenArt.swift`: an observable store with a revision counter; files at "`~/Library/Application Support/MacPlay/art/<percent-encoded key>-<cover|banner>.jpg`"; `image(key, kind)` (memory-cached), `has`, `save` (atomic JPEG, quality 0.9), `remove`, `removeAll(key)`, `move(from:to:)`; publishes on the main thread
- [X] T003 Image intake in `app/Sources/MacPlay/ChosenArt.swift`: decode data with ImageIO and scale to "longest side ≤ 1920 px"; read item providers in the order file URL → image data → `https` link (downloaded once, 30 MB cap) → `data:` image link; refuse anything else with a message; the Google Images link "`https://www.google.com/search?udm=2&q=<title>+game+cover`" (banner: `+game+wallpaper`)
- [X] T004 Make `ArtImage` in `app/Sources/MacPlay/GameArt.swift` take an optional artwork key, prefer the chosen image, and reload when the store's revision changes
- [X] T005 Dry-run T003: a PNG file, a WebP file, a `data:` image link, an `https` image link and a text file go through the intake; the first four give an image ≤ 1920 px, the text file is refused

## Phase 3: User Story 1 - Give a game without artwork a cover (P1) 🎯 MVP

**Goal**: the picker, reachable from a program card without artwork.
**Independent test**: quickstart steps 2–5 and 7.

- [X] T006 [US1] Create `app/Sources/MacPlay/CoverPicker.swift`: sheet per contracts/cover-picker.md — title, "Search Google Images", hint, drop area with preview in the target shape (2:3 or ~3:1), ⌘V, "Paste", "Choose file…", one-line errors, "Cancel", "Apply"
- [X] T007 [US1] In `app/Sources/MacPlay/HomeView.swift`: pass each item's key to `ArtImage`; a "Choose a cover" button over program cards without a chosen cover (outside the card's link so it gets the click); present `CoverPicker` as a sheet

## Phase 4: User Story 2 - Replace or reset any game's artwork (P2)

**Goal**: menus on every "Your games" card and on the hero.
**Independent test**: quickstart step 6.

- [X] T008 [US2] Context menus in `app/Sources/MacPlay/HomeView.swift`: "Change cover…" on cards, "Change banner…" on the hero of an installed game or program, "Use default artwork" when a chosen image exists; "Choose a banner" on the hero of a program without one; "Use default artwork" in the picker's footer in `app/Sources/MacPlay/CoverPicker.swift`
- [X] T009 [P] [US2] Pass the artwork key (`steam:<appid>`) to `ArtImage` in `app/Sources/MacPlay/InstalledView.swift`, `app/Sources/MacPlay/SteamView.swift` and `app/Sources/MacPlay/GamesView.swift`

## Phase 5: User Story 3 - Chosen artwork follows the game (P3)

**Goal**: rename keeps artwork and play time; uninstall removes artwork.
**Independent test**: quickstart step 8.

- [X] T010 [US3] Add `rename(from:to:)` to `app/Sources/MacPlay/PlayTime.swift`
- [X] T011 [US3] In `app/Sources/MacPlay/WindowsApps.swift`: `rename` moves the chosen artwork and the play-time entry to the new key; `uninstall` deletes the program's chosen artwork once the wrapper is gone

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T012 [P] Amend `.specify/memory/constitution.md`: principle II lists `~/Library/Application Support/MacPlay` (artwork the player chooses); network access lists the image link the player drops into the picker; version 1.2.0 (MINOR)
- [X] T013 [P] README.md: choosing a cover (Google Images in the browser; drag, paste or file), where chosen artwork is kept, the dropped-link download
- [X] T014 [P] `specs/009-game-style-ui/data-model.md`: a rename now moves play time (see 010)
- [X] T015 Build with `./build.sh`, update `/Applications/MacPlay.app` in place, open from Finder, review a render of Home with a chosen cover and of the picker
- [X] T016 Quickstart walk-through with the player (cover applied and working; rename, uninstall and the FR/ID pass not reported)
- [X] T017 Set `**Status**` to Implemented in `specs/010-custom-cover/spec.md`

## Dependencies & Execution Order

- T001 → T002–T004 → T005 → US1 (T006–T007) → US2 (T008–T009) → US3 (T010–T011) → Polish.
- T009, T012, T013, T014 touch separate files and can run in parallel with their neighbours.

## Implementation Strategy

MVP is US1: a program without artwork gets a cover from Google Images. US2 reuses the same sheet;
US3 is two small model changes.
