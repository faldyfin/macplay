# Feature Specification: Steam Section

**Feature Branch**: `003-steam-section` (built directly on `main`)

**Created**: 2026-09-30

**Status**: Implemented

**Input**: User description: "Separate Steam from My Mac so it has its own sidebar menu. Add Launch/Stop
Steam like Windows apps; now there is only Restart, Reinstall and Uninstall, no way to open Steam."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open and close Steam from its own section (Priority: P1)

The player opens the Steam section, clicks Launch, and Steam starts; while it runs, the same place
offers Stop.

**Why this priority**: Before, Steam could be restarted or removed but not simply opened.

**Independent Test**: With Steam closed, open the Steam section and click Launch; wait for Steam's
window; click Stop.

**Acceptance Scenarios**:

1. **Given** Steam is installed and closed, **When** the player clicks Launch, **Then** the button
   is replaced by "Starting Steam…" until Steam's window is up, then by Stop.
2. **Given** Steam is running and not downloading, **When** the player clicks Stop, **Then** Steam
   and every game it started close.
3. **Given** Steam is downloading, **When** the player clicks Stop, **Then** MacPlay first warns that
   stopping can make Steam discard the partial download, and stops only after confirmation.

---

### User Story 2 - See Steam's real state at a glance (Priority: P2)

**Why this priority**: The page used to say "Steam is not installed" for a moment on every visit,
offering Install for a Steam that was already there.

**Independent Test**: Open the section repeatedly, and open or quit Steam outside MacPlay while the
section is visible.

**Acceptance Scenarios**:

1. **Given** the first check has not finished, **When** the section opens, **Then** it shows
   "Checking Steam…", never "not installed".
2. **Given** the section was opened before, **When** it is reopened, **Then** the last known state
   shows immediately and refreshes in the background.
3. **Given** Steam is opened or quit outside MacPlay, **When** the section is visible, **Then** it
   shows the new state within a few seconds.
4. **Given** Steam is installed, **When** the section shows, **Then** it includes the engine version
   and the active graphics engine.

---

### User Story 3 - My Mac is only about the Mac (Priority: P3)

My Mac shows the hardware (chip, memory, GPU, macOS) and system health (Apple Silicon, Rosetta,
swap, disk), without Steam controls.

**Why this priority**: Mixing machine health with Steam management made both harder to find.

**Independent Test**: Open My Mac and check no Steam control appears there.

**Acceptance Scenarios**:

1. **Given** any state, **When** the player opens My Mac, **Then** only hardware and health show.
2. **Given** My Mac was opened before, **When** it is reopened, **Then** the last report shows at once.

### Edge Cases

- Steam is not installed: the section offers Install, with its download size and duration.
- A cold first start or a Steam self-update takes minutes: "Starting Steam…" stays for up to
  3 minutes, then the Launch button returns.
- Reinstall and Uninstall delete installed games: both ask for confirmation first.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Steam MUST have its own sidebar section, below My Mac.
- **FR-002**: The section MUST offer Launch when Steam is installed and closed, and Stop while it
  runs, in the page header.
- **FR-003**: Stop MUST ask for confirmation while a download is in progress.
- **FR-004**: The section MUST keep Restart cleanly, Reinstall and Uninstall (both with
  confirmation), and Install when Steam is missing.
- **FR-005**: The section MUST NOT claim Steam is missing before the first check completes.
- **FR-006**: The running state MUST be rechecked while the section is visible, often enough that
  changes made elsewhere appear within 5 seconds.
- **FR-007**: My Mac MUST show only hardware and system health, and the last report immediately
  when reopened.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Opening Steam takes one click from the Steam section.
- **SC-002**: The section never shows "not installed" for an installed Steam.
- **SC-003**: State changes made outside MacPlay show in the section within 5 seconds.

## Assumptions

- The tip in the README for a misbehaving Steam ("Restart Steam cleanly") now points to the Steam
  section.
- Launching a Steam game from Compatible Games or from the Steam section's installed games
  (feature 007) still restarts Steam with that game, as
  before.
