# Feature Specification: Self-Updating Compatibility List

**Feature Branch**: `005-compatibility-list` (built directly on `main`)

**Created**: 2026-09-30

**Status**: Implemented

**Input**: User description: "Where does this compatible list come from? Is it up to date? If it's only a
list of compatible games, rename the menu to Compatible Games. Can you find out where it gets the
list from? An auto-updater for it would be good."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Look up whether a game runs (Priority: P1)

The player opens Compatible Games, searches a title and sees whether it runs (great, playable,
rough, not working, native Mac version, blocked by anti-cheat), with the reports behind it.

**Why this priority**: The previous list had 80 hand-written entries with no sources and never
changed, so most games were missing and nothing could be checked.

**Independent Test**: Search for a game outside the 80 hand-tuned ones (e.g. Among Us, Hades) and open
its page.

**Acceptance Scenarios**:

1. **Given** the list, **When** the player opens a game imported from AppleGamingWiki, **Then** the
   page shows the rating, the method (CrossOver or Wine), the date of the latest report (or
   "undated") and a link to the source, and says MacPlay has not tested the game.
2. **Given** a hand-tuned game, **When** the player opens it, **Then** MacPlay's engine, presets and
   fixes show as before, with the community reports next to them.
3. **Given** a game whose anti-cheat does not run under Wine, **When** the player opens it,
   **Then** the page names the anti-cheat and its status, with a link.

---

### User Story 2 - The list stays current without a MacPlay update (Priority: P2)

**Why this priority**: Ratings change as Wine improves; the list must follow without releases.

**Independent Test**: Run the weekly job by hand, then press Check now in the app.

**Acceptance Scenarios**:

1. **Given** the weekly job runs and nothing changed upstream, **When** it finishes, **Then** nothing
   is committed.
2. **Given** a newer list was published, **When** the player opens Compatible Games (at most once a
   day) or presses Check now, **Then** the newer list is used and "Updated <date>" changes.
3. **Given** the download fails, returns an error page or an emptied list, **When** the app checks,
   **Then** it keeps the list it has.

---

### User Story 3 - The tab says what it is (Priority: P3)

The sidebar item is called "Compatible Games", so it is not mistaken for the installed games.

**Independent Test**: Read the sidebar.

**Acceptance Scenarios**:

1. **Given** the app, **When** the player reads the sidebar, **Then** the tab reads "Compatible
   Games" ("Jeux compatibles" in French), distinct from the installed games (listed in the Steam
   section since feature 007).

### Edge Cases

- A game exists both in the hand-tuned list and in a source: it appears once, with the hand-tuned
  status.
- A wiki page has no Steam id: the game is still listed and rated, but cannot be installed through
  Steam from MacPlay.
- Most wiki reports are from 2021–2022, before the current translation layers: the date is always
  shown so the player can judge.
- An imported game has no engine recommendation: the page says so and offers no engine to apply,
  and no fps estimate is shown.
- The downloaded list contains a duplicate Steam id: the app must not fail.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The list MUST combine MacPlay's hand-tuned entries with AppleGamingWiki's macOS
  compatibility reports and AreWeAntiCheatYet's anti-cheat status.
- **FR-002**: Every imported rating MUST carry its source, method, latest report date (or "undated")
  and a link.
- **FR-003**: Hand-tuned entries MUST keep their status; community data is shown next to it.
- **FR-004**: The list MUST be rebuilt weekly and published only when its content changed.
- **FR-005**: The app MUST ship a copy of the list and use the newest valid copy available,
  checking for a new one at most once a day and on request.
- **FR-006**: An invalid, failed or emptied download MUST NOT replace the list in use.
- **FR-007**: Imported games MUST be marked as not tested by MacPlay and MUST NOT get an engine
  recommendation or a performance estimate.
- **FR-008**: The tab MUST be named "Compatible Games" and show when the list was last updated.
- **FR-009**: The generated list MUST credit its sources and be licensed CC BY-NC-SA 3.0, as
  AppleGamingWiki's content requires.

### Key Entities

- **Game entry**: title, Steam id (optional), status, source, notes; hand-tuned entries add engine,
  presets and fixes.
- **Community report**: source, rating, method, latest report date, link.
- **Anti-cheat status**: status under Wine/Proton on Linux, anti-cheat names, link.
- **Published list**: the entries plus the date it was generated, sources and license.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The list covers about 1,700 games instead of 80 (1,687 at first generation: 80
  hand-tuned, 1,306 from AppleGamingWiki, 301 blocked by anti-cheat).
- **SC-002**: 100% of imported ratings show a source link, and a date where the source has one.
- **SC-003**: A list published upstream reaches the app within one day of the player opening
  Compatible Games, or immediately with Check now.
- **SC-004**: A weekly run with no upstream change produces no commit.

## Assumptions

- AppleGamingWiki's CrossOver and Wine ratings approximate MacPlay's own setup; the wiki does not
  define its "Wine" column and does not say which translation layer was used.
- Anti-cheat status comes from Linux/Proton data and is a hint for Wine on a Mac, not a Mac test.
- GitHub turns off scheduled jobs in public repositories after 60 days without activity; the
  README says how to re-enable it.
- The repository is public so the app can download the list without credentials.
