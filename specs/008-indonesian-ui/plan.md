# Implementation Plan: Indonesian UI

**Branch**: `008-indonesian-ui` (work lands on `main`) | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-indonesian-ui/spec.md`

## Summary

Add Bahasa Indonesia as a third UI language: `AppLanguage` gains `id`, `L.t` gains a third
argument, and every call site gets an Indonesian literal, inserted by a one-off script from a
translation table that is checked for matching interpolations and format specifiers. Data-file
notes fall back to English. See [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.4 toolchain, Swift 5 language mode

**Primary Dependencies**: SwiftUI, Foundation (constitution I)

**Storage**: the existing `lang` preference (`UserDefaults`); new value `id`

**Testing**: no test target; release build (the compiler rejects any call site left with two
arguments) plus the [quickstart](quickstart.md) walk-through

**Target Platform**: macOS 14.6+ on Apple Silicon

**Project Type**: desktop app (`app/`)

**Performance Goals**: none beyond today's (string choice is a switch)

**Constraints**: every call site keeps literal arguments; interpolations and `%` specifiers in the
Indonesian text must match the English exactly

**Scale/Scope**: 229 call sites, 208 unique English strings, 12 source files

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I. Native and dependency-free | no localization framework or package added | Pass |
| II. User's folders only | only the existing preference | Pass |
| III–V | not affected | Pass (n/a) |
| VI. Verified behaviour | build proves completeness; walk-through in Indonesian | Pass (planned) |
| VII. Bilingual UI, docs in sync | amended to three languages (constitution 1.1.0); README language line | Pass after amendment |

Post-design re-check: unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/008-indonesian-ui/
├── plan.md, research.md, data-model.md, quickstart.md
├── contracts/language-picker.md
└── tasks.md
```

### Source Code

```text
app/Sources/MacPlay/Localization.swift   # AppLanguage.id, L.lang, t(en, fr, id)
app/Sources/MacPlay/*.swift              # third argument at every L.t call site
.specify/memory/constitution.md          # principle VII → three languages, v1.1.0
README.md                                # language line
```

**Structure Decision**: keep the existing inline pattern (`L.t` per string) rather than moving to
string catalogs, so every string stays next to the code that shows it.

## Complexity Tracking

No violations.
