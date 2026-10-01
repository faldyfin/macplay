# Research: Game-Style Interface

## Artwork source and fallbacks

- **Decision**: `https://cdn.akamai.steamstatic.com/steam/apps/<appid>/<file>`. Cover cards try
  `library_600x900.jpg`, then `library_hero.jpg` cropped to fill, then `header.jpg`; banners try
  `library_hero.jpg`, then `header.jpg`. Anything else gets a styled placeholder.
- **Evidence**: 2026-10-01 checks: Elden Ring (1245620), The Witcher 3 (292030), Elden Ring
  Nightreign (2622380) and Dota 2 (570) return all three files; Heartopia (4025700) returns only
  `library_hero.jpg` (404 for the other two), hence the chain. `shared.akamai.steamstatic.com`
  answered identically.
- **Cache**: `~/Library/Caches/macplay/art/<appid>-<file>`; a missing image is remembered with an
  empty marker file so it is not requested again on every view; an in-memory cache avoids decoding
  twice.
- **Alternatives**: SteamGridDB (needs an API key); no artwork (rejected in clarification).

## Play time

- **Decision**: one `ps -axo command` every 30 s while MacPlay runs. A Steam game counts when a
  process path contains its `steamapps/common/<installdir>`; a program counts while its wrapper's
  Wine session is up. Seconds accumulate per key (`steam:<appid>`, `app:<name>`) in `UserDefaults`,
  with the last-played date.
- **Rationale**: no hooks into Steam or Wine needed; one process listing is cheap; the constitution
  allows preferences (named explicitly after a PATCH amendment).
- **Limits**: time while MacPlay is closed is not counted; games inside a launcher count for the
  launcher (spec edge cases).

## Featured game

- **Decision**: the most-played installed title; else the most recently added (Steam manifest file
  date, or the creation date of the wrapper's `Contents` folder for programs; the `.app` folder
  keeps the Sikarugir template's date); else the best-rated compatible game with a Steam id
  that MacPlay hand-tuned.

## Navigation

- **Decision**: a custom icon rail (SF Symbols, tooltip with the name) replacing the sidebar list;
  the language menu at its foot. Home gets a `NavigationStack` so cards open the existing game and
  program pages.
- **Window**: `.windowStyle(.hiddenTitleBar)` (macOS 11+) with the window movable by its background,
  so the dark theme reaches the top edge like a launcher.

## Theming existing screens

- **Decision**: at the root: dark colour scheme, coral tint, theme background, and a custom
  `GroupBoxStyle` that draws every existing GroupBox as a theme card; lists hide their system
  background (`scrollContentBackground`, macOS 13+) and sit on the panel colour.
- **Rationale**: every screen already uses GroupBox and List; one style changes them all without
  rewriting them.

## Type

- **Decision**: SF Pro Rounded, heavy, for screen titles, the greeting and game names on art; SF Pro
  for everything else. No all-caps labels.
