# Feature Specification: App Icon

**Feature Branch**: `004-app-icon` (built directly on `main`)

**Created**: 2026-09-30

**Status**: Implemented

**Input**: User description: "Can you generate an icon for MacPlay? It is still plain." Later: "Can the icon
be changed to this?" (with artwork, first as a JPEG with logos, then as a PNG without them).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Recognise MacPlay in the Dock and Finder (Priority: P1)

The player sees a MacPlay icon (a game controller with a play button in front of a monitor) in
Finder, Launchpad, the Dock and the app switcher, instead of the generic blank icon.

**Why this priority**: The generic icon made the app look unfinished and hard to find.

**Independent Test**: Install the app and look at it in Finder and the Dock.

**Acceptance Scenarios**:

1. **Given** the app is installed, **When** the player views it in Finder, **Then** the MacPlay icon
   shows in the standard macOS tile shape with a soft shadow and no stray background.
2. **Given** the app is running, **When** the player looks at the Dock, **Then** the same icon shows.

---

### User Story 2 - Change the artwork later (Priority: P2)

A maintainer replaces the source artwork and regenerates every icon size with one command.

**Why this priority**: The artwork changed twice in one day; regenerating by hand is error-prone.

**Independent Test**: Swap the source image, run the generator, rebuild, and check the new icon.

**Acceptance Scenarios**:

1. **Given** a new square artwork with the tile on a light background, **When** the generator runs,
   **Then** it finds the tile, trims it to the macOS shape and writes all icon sizes.
2. **Given** artwork whose "transparent" background is a painted checkerboard, **When** the generator
   runs, **Then** none of the checkerboard remains in the icon.

### Edge Cases

- Artwork containing third-party logos (an early version showed the Windows and Apple logos): not
  used, because both companies' guidelines require a trademark license for that.
- The Dock keeps showing a cached generic icon after the app was deleted and copied in again:
  updating the app in place, or restarting the Dock, shows the new icon.
- At 16 and 32 pixels a detailed illustration blurs; the outline must still read as a controller.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST ship an icon covering every size macOS uses, from 16 to 1024 pixels.
- **FR-002**: The icon MUST follow the macOS tile proportions and include the standard drop shadow.
- **FR-003**: The icon MUST NOT contain third-party logos or Apple's SF Symbols.
- **FR-004**: The icon MUST be regenerated from the committed source artwork with a single command,
  documented in the README.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: macOS shows the MacPlay icon (not the generic one) for the installed app.
- **SC-002**: Regenerating the icon after changing the artwork takes one command and no manual editing.
- **SC-003**: The icon contains no third-party marks.

## Assumptions

- The source artwork is a square image with the tile on a light background.
- Smaller sizes are scaled from the same artwork; a simplified small-size variant is out of scope.
