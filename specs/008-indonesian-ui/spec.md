# Feature Specification: Indonesian UI

**Feature Branch**: `008-indonesian-ui`

**Created**: 2026-10-01

**Status**: Implemented

**Input**: User description (translated from Indonesian): "Add an Indonesian UI language option."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Use MacPlay in Indonesian (Priority: P1)

An Indonesian-speaking player picks Bahasa Indonesia in the language picker at the bottom of the
sidebar; every screen, button, message, confirmation and log line switches to Indonesian at once.

**Why this priority**: It is the whole request; MacPlay's audience includes Indonesian players.

**Independent Test**: Pick Bahasa Indonesia and walk through every section: My Mac, Steam, Compatible
Games, My Games, My Apps, an install, a confirmation dialog.

**Acceptance Scenarios**:

1. **Given** the app in English, **When** the player picks Bahasa Indonesia, **Then** all interface
   text is Indonesian without restarting the app.
2. **Given** Bahasa Indonesia is picked, **When** the app is quit and reopened, **Then** it stays in
   Indonesian.
3. **Given** "System" is picked and macOS prefers Indonesian, **When** the app opens, **Then** it is in
   Indonesian.

---

### User Story 2 - Other languages keep working (Priority: P2)

**Why this priority**: Adding a language must not break English or French.

**Independent Test**: Switch between all four picker options.

**Acceptance Scenarios**:

1. **Given** any language, **When** the player picks English or Français, **Then** the interface is
   entirely in that language, as before.

### Edge Cases

- Game notes and fixes in the compatibility data have no Indonesian text: they show in English.
- Names of products and engines (Steam, D3DMetal, TapTap) stay untranslated.
- Text built from values (sizes, counts, dates, game names) reads naturally in Indonesian.
- macOS prefers a language MacPlay does not have: "System" falls back to English.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The language picker MUST offer System, Français, English and Bahasa Indonesia.
- **FR-002**: Every interface string MUST have an Indonesian version; none may fall back to English.
- **FR-003**: Changing the language MUST apply immediately and persist across restarts.
- **FR-004**: "System" MUST pick Indonesian when macOS's preferred language is Indonesian.
- **FR-005**: Content from data files without Indonesian text MUST fall back to English.
- **FR-006**: The rule that every interface string exists in every UI language MUST be recorded in
  the project constitution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of interface strings have Indonesian text (230 at the time of writing).
- **SC-002**: Switching language takes one selection and no restart.
- **SC-003**: No English text remains on any screen in Indonesian mode, apart from product names and
  data-file notes.

## Assumptions

- Informal, friendly Indonesian ("kamu") matches the tone of the English and French text, which use
  "you" and "tu".
- The README and specs stay in English; only the app interface is translated.
- The player, a native speaker, reviews the wording after release; corrections are cheap.
