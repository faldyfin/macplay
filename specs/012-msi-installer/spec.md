# Feature Specification: MSI Installers

**Feature Branch**: `012-msi-installer` (work lands on `main`)

**Created**: 2026-10-11

**Status**: Draft

**Input**: User description (translated from Indonesian): "Try to support MSI installers."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Install a Windows program from an .msi (Priority: P1)

Some Windows games and programs ship as a Windows Installer package (`.msi`) instead of a setup
`.exe`. The player picks the `.msi` in My Games or My Apps exactly as they would a setup `.exe`:
MacPlay builds the wrapper, the installer's own window guides them through, and the installed
program shows up ready to launch.

**Why this priority**: it is the request; today the picker only accepts `.exe`.

**Independent Test**: install 7-Zip from its official `.msi` into a new app and launch it.

**Acceptance Scenarios**:

1. **Given** My Games or My Apps, **When** the player installs a program, **Then** the file picker
   accepts both `.exe` and `.msi` files.
2. **Given** an `.msi`, **When** the install runs, **Then** Windows Installer's own window appears
   and MacPlay waits until it closes, as with a setup `.exe`.
3. **Given** the package installed a program, **Then** MacPlay finds it and the app is ready to
   launch, exactly as after a setup `.exe`.
4. **Given** the player cancelled or the package failed, **Then** MacPlay says no program was found
   and points to a detailed installer log.

### Edge Cases

- A package that installs only for the current user (into the user's AppData) is found like one
  that installs into Program Files.
- A package that installs no program (a library, a runtime) ends with "no installed program found";
  the player can pick a program with "Change…" or uninstall the app.
- Packages that need components Wine lacks fail as they would with a setup `.exe`; the detailed
  log tells why.
- Upper-case extensions (`.MSI`) count as `.msi`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The installer picker in My Games and My Apps MUST accept `.msi` files as well as `.exe`.
- **FR-002**: An `.msi` MUST be installed through Windows Installer inside the new wrapper, with its
  full interface, and MacPlay MUST wait until it finishes.
- **FR-003**: Installing from an `.msi` MUST write Windows Installer's detailed log next to MacPlay's
  install log, and failure messages MUST point to it.
- **FR-004**: Everything after the installer (finding the program, naming, categories, launching,
  uninstalling) MUST work the same as for a setup `.exe`.
- **FR-005**: All new or changed text MUST exist in English, French and Indonesian; the README MUST
  mention `.msi`.
- **FR-006**: When no installed program is named like the app, MacPlay MUST prefer a windowed
  program over a console tool (found in testing: 7-Zip's package installs `7z.exe`, a console
  tool, next to `7zFM.exe`, its window).
- **FR-007**: New program wrappers MUST stand Tahoma in for Segoe UI, the Windows interface font,
  which can't be redistributed (found with the player's first `.msi`, IAP Desktop, which quit at
  startup without it).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A program shipped as `.msi` is installed and launchable in the same number of steps as
  one shipped as a setup `.exe`.
- **SC-002**: A failed `.msi` install always leaves a log that names the failing step.

## Assumptions

- `.msp` patches and `.msu` updates are out of scope.
- The name MacPlay suggests comes from the file name, as for a setup `.exe`.
