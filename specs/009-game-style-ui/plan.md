# Implementation Plan: Game-Style Interface

**Branch**: `009-game-style-ui` (work lands on `main`) | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/009-game-style-ui/spec.md`

## Summary

A dark maroon/coral theme for the whole app, an icon rail instead of the sidebar list, and a new
Home screen: greeting and search, a hero banner with real Steam artwork and a Play action, two rows
of cover cards, and a right column with what's running, the Mac's specs, play time and recently
added games. Artwork comes from Steam's image server by app id and is cached on disk; play time is
recorded locally while MacPlay is open. Existing screens are restyled through shared styles rather
than rewritten. Decisions in [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.4 toolchain, Swift 5 language mode

**Primary Dependencies**: SwiftUI, AppKit, Foundation only (constitution I)

**Storage**: artwork in `~/Library/Caches/macplay/art/`; play time in `UserDefaults`

**Testing**: no test target; release build, a dry run of the art and play-time code against live
data, and the [quickstart](quickstart.md) walk-through

**Target Platform**: macOS 14.6+ on Apple Silicon

**Project Type**: desktop app (`app/`)

**Performance Goals**: Home appears at once with placeholders; artwork fills in as it arrives; the
play-time tick costs one process listing every 30 seconds

**Constraints**: no invented data; works offline (placeholders); all text in EN/FR/ID

**Scale/Scope**: 6 sections, a few dozen installed titles, artwork for up to ~30 cards per screen

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I. Native and dependency-free | SwiftUI/AppKit only, own image cache; play time runs `ps`, which the principle must name (PATCH 1.1.1) | Pass after amendment |
| II. User's folders only | art in `~/Library/Caches/macplay`; play time in preferences, which the principle must name (PATCH 1.1.1) | Pass after amendment |
| III. Pinned, verified downloads | artwork is images, not code; only Steam's image host over HTTPS; failures fall back to placeholders | Pass |
| IV. Reversible, opt-in | the theme changes nothing outside MacPlay | Pass (n/a) |
| V. Honest compatibility info | Home shows existing ratings with their source; no new claims | Pass |
| VI. Verified behaviour | dry runs against live data + walk-through | Pass (planned) |
| VII. Multilingual, docs in sync | EN/FR/ID strings; README lists the image host and play time | Pass |
| Security: network access | Steam's image server is a new destination; the constitution and README must list it (PATCH 1.1.1) | Pass after amendment |

Post-design re-check: unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/009-game-style-ui/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/home-and-theme.md
└── tasks.md
```

### Source Code

```text
app/Sources/MacPlay/
├── Theme.swift        # NEW: palette, fonts, card group-box style, chips, placeholders
├── GameArt.swift      # NEW: Steam artwork URLs, fallback chain, disk + memory cache, ArtImage view
├── PlayTime.swift     # NEW: 30 s tracker, totals per title, UserDefaults store
├── HomeView.swift     # NEW: greeting, search, hero, rows, right column
├── MacPlayApp.swift   # icon rail + Home section, theme at the root, hidden title bar, start tracker
├── GamesView.swift    # banner art on game pages, themed list
├── InstalledView.swift# banner art on Steam game pages
├── AppsView.swift     # themed list
└── SteamView.swift    # cover thumbnails in Installed games
README.md, .specify/memory/constitution.md
```

**Structure Decision**: four new files for the new concerns; existing views only gain styling
hooks and artwork.

## Complexity Tracking

No violations.
