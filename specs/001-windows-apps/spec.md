# Feature Specification: Windows Apps

**Feature Branch**: `001-windows-apps` (built directly on `main`)

**Created**: 2026-09-30

**Status**: Implemented

**Input**: User description: "This app only supports Steam. I want to install normal .exe files too, for
example a custom launcher (TapTap) and play the games inside it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Install a launcher from its setup file and play its games (Priority: P1)

A player has the setup file of a Windows program, typically another game launcher such as TapTap.
They pick the file in MacPlay, give the program a name, and click through its installer. MacPlay
then lists the program, launches it, and the games the launcher downloads run inside it.

**Why this priority**: Without it MacPlay only works for Steam; this is the reason the feature exists.

**Independent Test**: Pick `TapTap_Global_PC_Setup….exe`, install it, launch TapTap from MacPlay,
download a game in TapTap and start it.

**Acceptance Scenarios**:

1. **Given** no Windows app is installed, **When** the player picks a setup file and confirms a
   name, **Then** MacPlay prepares a separate environment for it, runs the installer and, when the
   installer closes, shows the program in the Windows apps list with its main program filled in.
2. **Given** an installed app, **When** the player clicks Launch, **Then** the program opens with
   the chosen graphics engine, and games it starts use that engine too.
3. **Given** the installer started the program by itself, **When** installation finishes,
   **Then** MacPlay tells the player to stop it and launch it from MacPlay, so the engine applies.

---

### User Story 2 - Manage an installed app (Priority: P2)

The player can start and stop the app, choose its graphics engine, add launch options, and point
MacPlay at a different main program when the detected one is wrong.

**Why this priority**: Games differ; the player needs the same controls Steam games have.

**Independent Test**: Change the engine of an installed app, relaunch it, and check the new engine
is used; set the main program by hand and launch it.

**Acceptance Scenarios**:

1. **Given** an app is running, **When** the player clicks Stop, **Then** the app and every game it
   started close.
2. **Given** an app is stopped, **When** the player picks another graphics engine and applies it,
   **Then** the next launch uses it.
3. **Given** the detected main program is wrong, **When** the player chooses another program inside
   the app's drive, **Then** Launch starts that program; a file outside the app's drive is refused.

---

### User Story 3 - Rename or remove an app (Priority: P3)

**Why this priority**: Housekeeping; names are suggested from the setup file and may be wrong.

**Independent Test**: Rename an app (including a case-only change) and launch it; uninstall it and
check its files are gone.

**Acceptance Scenarios**:

1. **Given** an app is stopped, **When** the player renames it, **Then** it keeps working under the
   new name. Renaming is not offered while it runs.
2. **Given** an app, **When** the player confirms Uninstall, **Then** the app and everything installed
   inside it, games included, are deleted.

### Edge Cases

- The player cancels the installer: no program is found; the app stays listed so it can be fixed
  or uninstalled.
- The name is empty, uses unsupported characters, is "Steam", or already exists: Install is refused
  with the reason, before anything is created.
- The installer leaves uninstallers, updaters and helpers behind: they are not picked as the main
  program.
- MacPlay was started from a code editor's terminal that sets a variable making Electron apps run as
  plain Node: MacPlay clears it, so Electron launchers such as TapTap still start.
- A game draws blank text because the environment has no Windows fonts: the core fonts are installed
  before the program's installer runs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Players MUST be able to install a Windows program from its setup `.exe` and name it,
  with a name suggested from the file name.
- **FR-002**: Each program MUST get its own environment, independent of Steam's and of other
  programs, so uninstalling one never affects another.
- **FR-003**: The system MUST find the installed main program automatically and let the player
  choose another program inside that app's drive.
- **FR-004**: Players MUST be able to launch and stop an app; stopping MUST also close games it
  started.
- **FR-005**: Each app MUST have its own graphics engine choice and optional launch options, applied
  at the next launch.
- **FR-006**: Players MUST be able to rename a stopped app and uninstall an app after confirming.
- **FR-007**: The Windows core fonts MUST be installed in every new app before its installer runs.
- **FR-008**: The app MUST show whether the program is running and keep that status current.
- **FR-009**: Programs launched by MacPlay MUST NOT inherit editor variables that break Electron apps.

### Key Entities

- **Windows app**: a named program installed from a setup file; has a main program, launch options,
  a graphics engine and a running state.
- **App environment**: the self-contained Windows environment an app and its games live in, about
  1.4 GB before anything is installed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player installs a launcher from its setup file and launches it from MacPlay without
  using a terminal.
- **SC-002**: For a standard installer, the main program is detected correctly on the first try
  (TapTap: `TapTapGlobal.exe` chosen over the uninstaller, updater and helper programs).
- **SC-003**: Games started from an installed launcher run with the app's engine (Heartopia started
  from TapTap reached its login screen on D3DMetal).
- **SC-004**: Unity games show their interface text on first launch, without manual font installs.

## Assumptions

- Installers are ordinary Windows setup programs (NSIS was tested) that exit when done; bootstrapper
  installers that hand off to a second process may finish before files land.
- `.msi` packages are out of scope.
- Games inside a launcher are installed, updated and started by the launcher itself; MacPlay does not
  list them individually.
- Community ratings are only collected for Steam games.
