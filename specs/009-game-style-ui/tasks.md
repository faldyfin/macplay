# Tasks: Game-Style Interface

**Input**: Design documents from `/specs/009-game-style-ui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/home-and-theme.md, quickstart.md

**Tests**: none requested; validation is the release build, dry runs of the art and play-time code
against live data, and the [quickstart](quickstart.md).

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Confirm a clean baseline: `swift build -c release` in `app/` succeeds

## Phase 2: Foundational

- [X] T002 [P] Create `app/Sources/MacPlay/Theme.swift`: palette tokens (#2A0F14 background, #3A161D panel, #4C1F28 card, #FF6B5E accent, #F7ECE9 text, #C7A5A2 muted, #FFB547 star), rounded heavy title fonts, a `GroupBoxStyle` that draws theme cards (radius 16), a status chip (radius 10), an art placeholder
- [X] T003 [P] Create `app/Sources/MacPlay/GameArt.swift`: URLs on `cdn.akamai.steamstatic.com/steam/apps/<appid>/`, chains "cover: library_600x900 → library_hero (cropped) → header; banner: library_hero → header", disk cache "`~/Library/Caches/macplay/art/<appid>-<file>`; empty `.missing` marker = known absent", memory cache, and an `ArtImage` view that shows the placeholder until the image arrives
- [X] T004 [P] Create `app/Sources/MacPlay/PlayTime.swift`: a tracker that lists processes once every 30 s, adds the tick to `steam:<appid>` when a process path contains the game's `steamapps/common/<installdir>` and to `app:<name>` while the program's wrapper has a Wine session; store seconds and last-played per key in `UserDefaults` (`playTime`); expose totals, top titles and what is running now
- [X] T005 Dry-run T003 and T004 against live data: fetch art for Elden Ring (1245620) and Heartopia (4025700), confirm the chain and the cache files; run one tracker tick with TapTap running and stopped (stopped: verified, nothing counted; running: confirmed in T019)

## Phase 3: User Story 1 - A home screen that feels like a game launcher (P1) 🎯 MVP

**Goal**: Home with greeting, search, hero, card rows; cards open the existing pages.
**Independent test**: quickstart steps 2, 3 and 6.

- [X] T006 [US1] Create `app/Sources/MacPlay/HomeView.swift`: greeting from the user's first name and time of day, search field, hero banner for the featured game ("most-played installed; else most recently added; else best-rated hand-tuned compatible game with a Steam id"), "Your games" and "Runs great on your Mac" rows of cover cards
- [X] T007 [US1] Hero and card actions in `app/Sources/MacPlay/HomeView.swift`: Play for an installed Steam game, Launch for a program, open the page otherwise; a `NavigationStack` routes to `InstalledDetail`, `GameDetail` and `AppDetail`
- [X] T008 [US1] Search in `app/Sources/MacPlay/HomeView.swift`: results across installed games, programs and the compatibility list replace the rows while the field has text
- [X] T009 [US1] Replace the sidebar list with an icon rail (Home first, tooltips, coral selection, language menu at the foot) and make Home the start section in `app/Sources/MacPlay/MacPlayApp.swift`

## Phase 4: User Story 2 - The same look everywhere (P2)

**Goal**: every section in the theme.
**Independent test**: quickstart step 5.

- [X] T010 [US2] Apply the theme at the root in `app/Sources/MacPlay/MacPlayApp.swift`: dark scheme, coral tint, background, card group-box style, hidden title bar with the window movable by its background
- [X] T011 [P] [US2] Lists on the panel colour without the system background in `app/Sources/MacPlay/GamesView.swift` and `app/Sources/MacPlay/AppsView.swift`
- [X] T012 [P] [US2] Banner art at the top of game pages in `app/Sources/MacPlay/GamesView.swift` (`GameDetail`) and `app/Sources/MacPlay/InstalledView.swift` (`InstalledDetail`)
- [X] T013 [P] [US2] Cover thumbnails in the Steam section's Installed games list in `app/Sources/MacPlay/SteamView.swift`

## Phase 5: User Story 3 - Panels backed by real data (P3)

**Goal**: right column on Home.
**Independent test**: quickstart step 4.

- [X] T014 [US3] Right column in `app/Sources/MacPlay/HomeView.swift`: Running now, Your Mac (chip, memory, GPU), Play time (total, top 3, "counted while MacPlay is open"), Recently added (Steam manifest file dates, wrapper `Contents` folder dates)
- [X] T015 [US3] Start the play-time tracker when MacPlay launches in `app/Sources/MacPlay/MacPlayApp.swift`

## Phase 6: Polish & Cross-Cutting

- [X] T016 [P] Amend `.specify/memory/constitution.md`: principle I lists `ps`, principle II lists game artwork and play time, network access lists Steam's image server; version 1.1.1 (PATCH)
- [X] T017 [P] README.md: Home and the game style, artwork from `cdn.akamai.steamstatic.com` cached in `~/Library/Caches/macplay/art`, local play time
- [X] T018 Build with `./build.sh`, update `/Applications/MacPlay.app` in place, open from Finder, review a window capture of Home
- [X] T019 Quickstart walk-through with the player (Home in use with It Takes Two and Heartopia; play time counted "Played 2 min"; offline placeholders and the FR/ID pass not reported)
- [X] T020 Set `**Status**` to Implemented in `specs/009-game-style-ui/spec.md`

## Dependencies & Execution Order

- T001 → T002–T004 (parallel) → T005 → US1 (T006–T009) → US2 (T010–T013) → US3 (T014–T015) → Polish.
- T006–T008 and T014 share `HomeView.swift`: in order. T009, T010 and T015 share `MacPlayApp.swift`: in order.

## Parallel Example

```text
T002 Theme.swift   ||   T003 GameArt.swift   ||   T004 PlayTime.swift
T011 lists         ||   T012 banners         ||   T013 thumbnails
```

## Implementation Strategy

- MVP: Phase 2 + US1 (Home with art); then the theme everywhere; then the data panels.
