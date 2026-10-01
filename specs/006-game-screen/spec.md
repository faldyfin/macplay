# Feature Specification: Screen for Games

**Feature Branch**: `006-game-screen` (built directly on `main`)

**Created**: 2026-10-01

**Status**: Implemented

**Input**: User description: "If an external display is detected, can there be an option to play on the
built-in display or the external display?"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Play on the screen I choose (Priority: P1)

A player with an external monitor wants a game on the MacBook's own screen (or the other way
round). They pick the screen in My Mac once; games launched from MacPlay open there.

**Why this priority**: Windows games always opened on the macOS main display, with no way to choose.

**Independent Test**: With two screens, choose the built-in display, launch a Windows app from
MacPlay and start a game in it.

**Acceptance Scenarios**:

1. **Given** two screens and "Built-in display" chosen, **When** the player launches Steam, a Steam
   game or a Windows app from MacPlay, **Then** the built-in screen becomes the main display (the
   menu bar and Dock move there) and the game opens on it in fullscreen.
2. **Given** the default "The main display", **When** the player launches anything, **Then** nothing
   about the screens changes.

---

### User Story 2 - Get my screen setup back automatically (Priority: P2)

**Why this priority**: Moving the menu bar and Dock is only acceptable if it is temporary.

**Independent Test**: After playing, close the game and its launcher and wait; quit MacPlay while a
game runs.

**Acceptance Scenarios**:

1. **Given** MacPlay rearranged the screens, **When** every game and launcher has closed, **Then**
   the original arrangement returns within about 40 seconds.
2. **Given** the screens are rearranged, **When** the player clicks Restore now, **Then** the
   original arrangement returns at once.
3. **Given** the screens are rearranged, **When** MacPlay quits or crashes, **Then** macOS restores
   the original arrangement by itself.

### Edge Cases

- Only one screen connected: the option is hidden and launches change nothing.
- The chosen screen is unplugged: launches use the current main display.
- A launcher is already running when the choice changes: it stays on the screen it started on until
  it is stopped and launched again.
- Mirrored displays count as one screen.
- The chosen screen is already the main display: nothing changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When more than one screen is connected, My Mac MUST offer a choice of screen for games:
  the main display (default), the built-in display and each external display by name.
- **FR-002**: Before a launch from MacPlay, the chosen screen MUST become the main display if it is
  connected and is not already main.
- **FR-003**: The app MUST explain that the menu bar and Dock move with the main display.
- **FR-004**: MacPlay MUST restore the original arrangement once no game or launcher it manages is
  running, and on request.
- **FR-005**: The change MUST be undone by macOS if MacPlay quits, so it can never persist.
- **FR-006**: The option and its state MUST update when screens are connected, disconnected or
  rearranged.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With the built-in display chosen, a game launched from MacPlay opens on it every time
  (confirmed by the player: "working flawlessly").
- **SC-002**: The original arrangement is back within 40 seconds of the last game and launcher
  closing, and immediately on Restore now.
- **SC-003**: No arrangement change survives quitting MacPlay.

## Assumptions

- Windows games under Wine open on the Windows primary monitor, which is the macOS main display;
  Wine can only change the resolution of that display. Confirmed in Wine 11.0's Mac driver source.
- Moving the menu bar and Dock while playing is acceptable to the player.
- Games launched from outside MacPlay (for example a wrapper opened from Finder) are not affected.
