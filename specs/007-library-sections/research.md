# Research: Library Sections

No open questions came out of the Technical Context. These are the design decisions.

## Where the category is stored

- **Decision**: a `MacPlay Category` key (`game` or `app`) in the wrapper's `Contents/Info.plist`.
- **Rationale**: the wrapper already holds the program's other settings (program path, launch
  options, engine). The key travels with the wrapper, survives renames (renaming moves the folder
  and rewrites only the name keys) and needs no new file. The launcher ignores unknown keys.
- **Alternatives**: app preferences keyed by wrapper name (lost on rename, not visible in the
  wrapper); a separate index file in the cache (a second source of truth).

## Missing category

- **Decision**: no key means `app`.
- **Rationale**: spec FR-007; programs installed before this feature stay where they were (the old
  "Windows apps", now My Apps) until the player moves them.

## Showing Steam games in the Steam section

- **Decision**: a list of installed games under the Steam controls; selecting one pushes the
  existing game page (`InstalledDetail`) in a `NavigationStack` with a back button.
- **Rationale**: keeps one page per game (Play, engine, rating) unchanged; `NavigationStack` and
  `navigationDestination(for:)` exist from macOS 13.0 (Apple documentation), below the 14.6 minimum.
- **Alternatives**: a split list/detail like the old tab (crowds the controls); a sheet (the game
  page is long and has a live session status, which suits a full page better).

## My Games and My Apps

- **Decision**: one view, `AppsView(category:)`, used for both sections; the install form gets a
  category picker preset from the section; the program page gets a category picker.
- **Rationale**: both sections need exactly the same controls (spec FR-006); one view avoids
  duplicated code.
- **Alternatives**: two copies of the view; a single section with a filter (the user asked for
  separate sections).

## Refreshing the Steam games list

- **Decision**: read the list when the Steam section opens and whenever Steam stops running.
- **Rationale**: games finish installing while Steam runs; reading on stop and on open catches them
  without reading the library every 3 seconds.
