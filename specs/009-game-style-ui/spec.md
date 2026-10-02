# Feature Specification: Game-Style Interface

**Feature Branch**: `009-game-style-ui`

**Created**: 2026-10-01

**Status**: Implemented

**Input**: User description (translated from Indonesian): "Can the UI be made like, or close to, the
screenshot, so it looks very much like games?" The screenshot shows a dark game-launcher dashboard:
an icon rail on the left, a greeting and search on top, a large hero banner with game art and a
play action, horizontal cards with cover art, a recent-downloads strip, a friends column and a
play-time statistics card, a warm maroon/coral palette and large rounded cards.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A home screen that feels like a game launcher (Priority: P1)

The player opens MacPlay and lands on a Home screen: a large banner for a featured game with its
artwork and a Play or Install action, then rows of game cards with cover art (their installed games
first, then highly rated compatible games), with a search field on top.

**Why this priority**: It is the look the player asked for, and the first thing every user sees.

**Independent Test**: Open MacPlay with a few games installed; the Home screen shows their artwork,
and Play starts one.

**Acceptance Scenarios**:

1. **Given** installed games, **When** the player opens MacPlay, **Then** Home shows a featured game
   banner and a row of the installed games as cards with artwork; clicking a card opens its page.
2. **Given** no installed games, **When** the player opens Home, **Then** the banner and rows show
   compatible games that run well on their Mac, with Install actions.
3. **Given** the search field, **When** the player types a title, **Then** matching games from all
   sections appear.

---

### User Story 2 - The same look everywhere (Priority: P2)

Every section (My Mac, Steam, Compatible Games, My Games, My Apps) uses the same dark game style:
the theme colours, large rounded cards, and cover art where a game is shown.

**Why this priority**: A styled Home next to plain system screens would feel unfinished.

**Independent Test**: Visit every section and compare with Home.

**Acceptance Scenarios**:

1. **Given** any section, **When** it opens, **Then** it uses the theme's background, cards and accent
   colour, and stays readable.
2. **Given** a game with no artwork available, **When** it is shown, **Then** a styled placeholder
   with its title appears instead of an empty box.

---

### User Story 3 - Panels backed by real data (Priority: P3)

The side panels of the launcher layout show information MacPlay really has.

**Why this priority**: The constitution forbids invented data; the screenshot's friends list and
play-time totals have no source in MacPlay.

**Independent Test**: Compare every number on Home with its source.

**Acceptance Scenarios**:

1. **Given** the right-hand column, **When** Home shows, **Then** it shows what is running now, the
   Mac's chip, memory and GPU, the most recently installed games, and the play time MacPlay has
   recorded.
2. **Given** a fresh install of this version, **When** the player opens Home, **Then** play time reads
   0 h and grows as they play.

### Edge Cases

- No network: artwork is not available; cards fall back to placeholders and everything still works.
- A game in the list has no Steam id (imported from AppleGamingWiki without one): placeholder art.
- Small window: the side cards move under the card rows rather than squeezing the column.
- Light-mode users: the game style stays dark, as game launchers usually are.
- Play happens while MacPlay is closed: that time is not recorded; the card says play time counts
  while MacPlay is open.
- Games played inside a launcher (Heartopia in TapTap) count toward the launcher's time; MacPlay
  cannot tell them apart.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: MacPlay MUST open on a Home screen with a featured game banner, rows of game cards and
  a search field.
- **FR-002**: Game cards and banners MUST show the game's artwork when available and a styled
  placeholder otherwise.
- **FR-003**: Artwork MUST come from Steam's public image server, looked up by Steam id, and be kept in
  a local copy so each image is downloaded once; games without a Steam id or without artwork there
  get a styled placeholder. The README MUST list the new network destination.
- **FR-004**: The interface MUST use one dark theme across all sections, in the screenshot's palette:
  a deep maroon background with a coral accent.
- **FR-005**: The sidebar MUST become a compact icon rail with the section names available on hover.
- **FR-006**: Every number and status shown MUST come from MacPlay's real data.
- **FR-007**: All new text MUST exist in English, French and Indonesian.
- **FR-008**: MacPlay MUST record play time per Steam game and per program while it is open, keep it
  only on this Mac, and show the total and the most-played titles. It is never sent anywhere.

### Key Entities

- **Featured game**: the game the banner shows (the installed game played last, else the most
  recently installed, else a well-rated compatible game when nothing is installed). Until
  2026-10-02 it was the most-played game; the player found that it stuck to one title.
- **Play time**: seconds played per Steam game or program, recorded locally while MacPlay is open.
- **Game card**: title, artwork, status (installed / compatibility rating), primary action.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From launch, an installed game can be started from Home in two clicks.
- **SC-002**: Every installed Steam game and every game in the compatibility list with a Steam id
  shows real artwork when the network is available.
- **SC-003**: All sections share the same theme; no section keeps the plain system look.
- **SC-004**: No panel shows data MacPlay does not have.
- **SC-005**: Play time starts at 0 h and, after a 10-minute session, shows about 10 minutes for that
  game.

## Clarifications

### Session 2026-10-01

- Q: Colour palette? → A: the screenshot's maroon/coral (B).
- Q: Load artwork from Steam's image servers? → A: yes, with a local copy (A).
- Q: What replaces friends and total hours? → A: real data, plus play time recorded locally from now on (B).

## Assumptions

- Layout and feel follow the screenshot; exact pixels, the illustration style and third-party
  game art beyond official store artwork are out of scope.
- The friends and store features of the screenshot are not part of MacPlay.
