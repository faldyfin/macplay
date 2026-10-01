# Tasks: Indonesian UI

**Input**: Design documents from `/specs/008-indonesian-ui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/language-picker.md, quickstart.md

**Tests**: none requested; the release build is the completeness check (a two-argument `L.t` no
longer compiles) and the [quickstart](quickstart.md) is the walk-through.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Confirm a clean baseline: `swift build -c release` in `app/` succeeds

## Phase 2: Foundational

- [X] T002 In `app/Sources/MacPlay/Localization.swift`: add `case id` to `AppLanguage` labelled "Bahasa Indonesia"; replace `L.fr` with a current-language value resolved from `lang` = "`system` | `fr` | `en` | `id`" ("under `system` the first preferred macOS language decides: `fr…` → French, `id…` → Indonesian, else English"); keep `L.fr` for the data fallbacks; change `t` to `t(_ en:, _ fr:, _ id:)`

## Phase 3: User Story 1 - Use MacPlay in Indonesian (P1) 🎯 MVP

**Goal**: every interface string in Indonesian.

**Independent test**: quickstart steps 2–4.

- [X] T003 [US1] Write the translation table (English literal → Indonesian literal) for all 211 unique strings (208 when planned; 007 follow-ups added three), informal "kamu", product and engine names untranslated, in the session scratchpad (one-off input, not committed)
- [X] T004 [US1] Run the insertion script over `app/Sources/MacPlay/*.swift`: append the Indonesian literal to every `L.t` call; refuse any entry whose "`\( )` expressions … and the same `%` format specifiers" differ from the English
- [X] T005 [US1] Build with `swift build -c release` in `app/`; fix any call the script could not convert

## Phase 4: User Story 2 - Other languages keep working (P2)

**Goal**: English and French unchanged.

**Independent test**: quickstart step 5.

- [X] T006 [US2] Verify with the parser that every call's English and French literals are byte-identical to before the change (only a third argument added) across `app/Sources/MacPlay/*.swift`

## Phase 5: Polish & Cross-Cutting

- [X] T007 [P] Amend principle VII in `.specify/memory/constitution.md` to English, French and Indonesian via `L.t(en, fr, id)`; version 1.1.0 (MINOR), Last Amended 2026-10-01
- [X] T008 [P] Update the language line in `README.md` ("English & French" → English, French and Indonesian)
- [X] T009 Build with `./build.sh` in `app/`, update `/Applications/MacPlay.app` in place, open from Finder
- [X] T010 Run the quickstart walk-through (player reviews the Indonesian wording)
- [X] T011 Set `**Status**` to Implemented in `specs/008-indonesian-ui/spec.md`

## Dependencies & Execution Order

- T001 → T002 → T003 → T004 → T005 → T006 → T009 → T010 → T011; T007 and T008 any time after T002.

## Parallel Example

```text
T007 constitution.md   ||   T008 README.md
```

## Implementation Strategy

- MVP is US1 (T002–T005); US2 is a verification of the same change.
