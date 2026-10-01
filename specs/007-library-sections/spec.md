# Feature Specification: Library Sections

**Feature Branch**: `007-library-sections`

**Created**: 2026-10-01

**Status**: Implemented

**Input**: User description (translated from Indonesian): "In the UI, My games actually contains Steam
games — can it be merged into the Steam menu, with the installed games listed at the bottom? Windows
apps can contain software or games; can the user decide? For example TapTap is really games, I want
it in a Games category, maybe its own submenu. My Games → the games we installed manually. Windows
apps → rename to My Apps."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Steam games live with Steam (Priority: P1)

The player opens the Steam section and sees Steam's controls and, below them, the games installed
in Steam. Opening one shows its page with Play, graphics engine and rating, as before.

**Why this priority**: "My games" only ever held Steam games, so it duplicated the Steam section and
its name hid that.

**Independent Test**: With a Steam game installed, open the Steam section, open the game and press Play.

**Acceptance Scenarios**:

1. **Given** Steam has installed games, **When** the player opens the Steam section, **Then** the
   games are listed under the Steam controls with their size and community rating.
2. **Given** that list, **When** the player opens a game, **Then** its page shows Play, the engine
   choice and the rating form, and a way back to the Steam section.
3. **Given** Steam has no games, **When** the player opens the section, **Then** the list says no
   games are installed yet and how to install one.
4. **Given** Steam is not installed, **When** the player opens the section, **Then** no games list is
   shown, only the install controls.

---

### User Story 2 - Games and apps are kept apart (Priority: P1)

Programs installed from a setup file are either games (or game launchers) or other software. The
player decides which. Games are listed under **My Games**, other software under **My Apps**.

**Why this priority**: TapTap is a game launcher but was listed among apps, mixed with software.

**Independent Test**: Install a program from My Games and one from My Apps; move one between them.

**Acceptance Scenarios**:

1. **Given** the player starts an install from My Games, **When** the install form opens, **Then** the
   category is preset to Game; from My Apps it is preset to App; the player can change it before
   installing.
2. **Given** an installed program, **When** the player changes its category, **Then** it moves to the
   other section and keeps working (same program, engine, launch options, games).
3. **Given** a program installed before this feature, **When** MacPlay shows it, **Then** it appears
   under My Apps until the player moves it.
4. **Given** TapTap, **When** this feature ships, **Then** TapTap is listed under My Games.

---

### User Story 3 - The sidebar says what each section holds (Priority: P2)

**Why this priority**: Names should match content.

**Independent Test**: Read the sidebar.

**Acceptance Scenarios**:

1. **Given** the app, **When** the player reads the sidebar, **Then** it shows, in order: My Mac,
   Steam, Compatible Games, My Games, My Apps; there is no separate "My games" for Steam and no
   "Windows apps".

### Edge Cases

- A program is running when its category changes: the change applies at once; it keeps running.
- Renaming or uninstalling a program works the same in both sections.
- Both sections empty: each shows how to install a program from its setup file.
- The screen-for-games choice (feature 006) applies to launches from both sections and Steam.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Steam section MUST list installed Steam games below its controls, each opening the
  existing game page (Play, engine, rating) with a way back.
- **FR-002**: The separate "My games" section for Steam games MUST be removed.
- **FR-003**: Every program installed from a setup file MUST have a category, Game or App, stored
  with the program so it survives restarts and renames.
- **FR-004**: The install form MUST let the player choose the category, preset by the section the
  install started from.
- **FR-005**: A program's page MUST let the player change its category.
- **FR-006**: "My Games" MUST list programs in the Game category; "My Apps" MUST list the App
  category; both offer the full set of program controls (launch, stop, engine, launch options,
  program, rename, uninstall).
- **FR-007**: Programs without a stored category MUST be treated as App.
- **FR-008**: The sidebar MUST read: My Mac, Steam, Compatible Games, My Games, My Apps.
- **FR-009**: All new and changed text MUST be available in every UI language.

### Key Entities

- **Program**: something installed from a setup file; now has a category (Game or App).
- **Steam game**: a game installed in Steam; listed in the Steam section.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A Steam game can be started in two clicks from the Steam section (open the game, Play).
- **SC-002**: Moving a program between My Games and My Apps takes one action and needs no reinstall.
- **SC-003**: After the change, TapTap is under My Games and still launches.
- **SC-004**: The sidebar has five sections, each name matching its content.

## Assumptions

- The category is a label only; it does not change how a program runs.
- Games inside a launcher (Heartopia inside TapTap) are still managed by the launcher, not listed
  individually.
- The documentation and earlier specs that mention "My games" and "Windows apps" are updated to the
  new names.
