# Implementation Plan: Choose a Game's Cover

**Branch**: `010-custom-cover` (work lands on `main`) | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/010-custom-cover/spec.md`

## Summary

A cover picker on Home: "Change cover…" on the "Your games" cards and "Change banner…" on the hero,
plus a visible "Choose a cover" / "Choose a banner" button where a program has no artwork. The
picker opens Google Images in the browser on the game's name, takes the image the player drags in,
pastes or chooses from a file, previews it in the target shape and saves it on Apply. Chosen
artwork lives in `~/Library/Application Support/MacPlay/art`, wins over Steam artwork everywhere
artwork is shown, moves with a program's rename (with its play time) and is deleted on uninstall.
Decisions in [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.4 toolchain, Swift 5 language mode

**Primary Dependencies**: SwiftUI, AppKit, ImageIO, Foundation only (constitution I)

**Storage**: JPEG files in `~/Library/Application Support/MacPlay/art/`, one per game and shape

**Testing**: no test target; release build, a dry run of image intake (file, data URL, web link,
non-image) and the [quickstart](quickstart.md) walk-through

**Target Platform**: macOS 14.6+ on Apple Silicon

**Project Type**: desktop app (`app/`)

**Performance Goals**: an applied cover appears on Home at once; saved files stay under ~1 MB

**Constraints**: MacPlay never fetches Google's pages; only the one link the player drops is
downloaded; all text in EN/FR/ID

**Scale/Scope**: a few dozen installed titles, two shapes each

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I. Native and dependency-free | SwiftUI/AppKit/ImageIO; no new binaries | Pass |
| II. User's folders only | a new folder, `~/Library/Application Support/MacPlay`, which the principle must name (MINOR 1.2.0) | Pass after amendment |
| III. Pinned, verified downloads | a dropped link is an image, not code; it is decoded and re-encoded before it is kept, anything else is refused | Pass |
| IV. Reversible, opt-in | nothing outside MacPlay's files changes; "Use default artwork" undoes a choice | Pass |
| V. Honest compatibility info | artwork only, no ratings or claims | Pass (n/a) |
| VI. Verified behaviour | intake dry run + walk-through | Pass (planned) |
| VII. Multilingual, docs in sync | EN/FR/ID strings; README names the folder and the dropped-link download | Pass |
| Security: network access | the image link the player drops is fetched once, from wherever it points; the constitution and README must say so (MINOR 1.2.0) | Pass after amendment |

Post-design re-check: unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/010-custom-cover/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/cover-picker.md
└── tasks.md
```

### Source Code

```text
app/Sources/MacPlay/
├── ChosenArt.swift    # NEW: store (save, load, remove, move), image intake and downscale, Google link
├── CoverPicker.swift  # NEW: the picker sheet (search, drop, paste, file, preview, apply, reset)
├── GameArt.swift      # ArtImage prefers chosen artwork and redraws when it changes
├── HomeView.swift     # card and hero menus, "Choose a cover/banner" buttons, the sheet
├── InstalledView.swift, SteamView.swift, GamesView.swift  # pass the artwork key to ArtImage
├── PlayTime.swift     # move a program's time on rename
└── WindowsApps.swift  # rename moves chosen artwork and play time; uninstall deletes artwork
README.md, .specify/memory/constitution.md
```

**Structure Decision**: two new files for the new concern; existing views only pass a key.

## Complexity Tracking

No violations.
