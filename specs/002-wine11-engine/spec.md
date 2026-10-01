# Feature Specification: Wine 11 Engine and Verified Downloads

**Feature Branch**: `002-wine11-engine` (built directly on `main`)

**Created**: 2026-09-30

**Status**: Implemented

**Input**: User description: "Mouse and keyboard stop responding in the game; only the first click works.
Use the new engine, don't wait for the 7-day rule — this isn't a work project."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Games keep responding after switching windows (Priority: P1)

A player starts a game (Heartopia from TapTap), clicks the game's Dock icon or switches away and
back. Mouse and keyboard keep working.

**Why this priority**: With the previous engine the game window looked focused but ignored all input
after being re-activated, so the game was unplayable.

**Independent Test**: In a wrapper built by MacPlay, start a game, Cmd+Tab away and back, then click
and type in the game.

**Acceptance Scenarios**:

1. **Given** a game started from a launcher, **When** the player activates its window from the Dock,
   **Then** clicks and key presses reach the game.
2. **Given** a game running, **When** the player switches away and back, **Then** input still works.

---

### User Story 2 - Only verified components are installed (Priority: P2)

Everything MacPlay downloads to build a wrapper is the exact version it was tested with; a changed
or corrupted file is refused instead of run.

**Why this priority**: Downloaded components run with the player's rights.

**Independent Test**: Corrupt a cached component and run a setup: the file is fetched again; serve a
wrong file and the setup stops with a checksum error.

**Acceptance Scenarios**:

1. **Given** a cached component whose contents changed, **When** a setup starts, **Then** the cached
   copy is discarded and downloaded again.
2. **Given** a download that does not match its expected checksum, **When** it finishes, **Then** it is
   refused and the setup stops with a clear message.

---

### User Story 3 - Engine choices match the wrapper (Priority: P3)

The graphics engine picker offers only engines the wrapper supports, and the active engine is shown
correctly.

**Why this priority**: The new wrapper format dropped one engine and changed how another is chosen.

**Independent Test**: Open the engine picker for a new and an older wrapper and compare the choices.

**Acceptance Scenarios**:

1. **Given** a wrapper built now, **When** the player opens the engine picker, **Then** it offers
   D3DMetal, DXMT and DXVK.
2. **Given** a wrapper built by an earlier MacPlay version, **When** the player opens the picker,
   **Then** it still offers all four engines, WineD3D included.

### Edge Cases

- Installers and font installs run outside the wrapper's own launcher; they must work on the new
  engine too (they first failed with missing libraries and could not start Windows programs).
- A game whose saved recommendation is WineD3D, applied to a new wrapper, runs on DXMT; the result
  is reported as DXMT.
- Steam's installer cannot be pinned: Valve only serves the latest one.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: New wrappers MUST use an engine that keeps game input working after window
  re-activation.
- **FR-002**: Every component download except Steam's installer MUST be pinned to an exact version
  and checked against its published checksum, for fresh downloads and cache hits.
- **FR-003**: A checksum mismatch MUST stop the setup with a message naming the file.
- **FR-004**: Installers and Windows font installs started by MacPlay MUST work on the new engine.
- **FR-005**: The engine picker MUST list only the engines the wrapper's format supports and show
  the engine actually active.
- **FR-006**: Wrappers built by earlier versions MUST keep working unchanged.
- **FR-007**: The minimum supported macOS MUST be stated in the README and enforced by the app:
  macOS 14.6, the requirement of the new wrapper format.

### Key Entities

- **Component**: a pinned download (wrapper template, Wine engine, winetricks) with name, version,
  source and checksum.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Heartopia stays fully playable with mouse and keyboard after window switches (was
  unplayable).
- **SC-002**: 100% of wrapper components, except Steam's installer, are verified before use.
- **SC-003**: Steam can be installed from scratch on the new engine and launches (verified by a
  reinstall).

## Assumptions

- The input fix comes from the engine; the Sikarugir maintainer stated issue #237 is resolved in the
  Wine 11 engines. The player chose to adopt the engine before it was 7 days old.
- The new engine series has its own open mouse reports for some games (Sikarugir #272, #273); not
  seen in Heartopia.
- Existing wrappers are not migrated automatically; a wrapper can be rebuilt by reinstalling.
