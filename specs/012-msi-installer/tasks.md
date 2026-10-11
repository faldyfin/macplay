# Tasks: MSI Installers

**Input**: Design documents from `/specs/012-msi-installer/`
**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: unit tests for the installer command; a real `.msi` installed in a throwaway wrapper.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Confirm a clean baseline: `swift build -c release` and `swift test` in `app/`

## Phase 2: User Story 1 - Install a Windows program from an .msi (P1) 🎯 MVP

- [X] T002 [US1] In `app/Sources/MacPlay/WindowsApps.swift`: `windowsPath(_:)` ("`Z:` plus the Mac path with `\` separators"), `installerArguments(for:msiLog:)` (`.exe` → its path; `.msi`, any case → `msiexec /i <package> /l*v <log>`), `msiLogPath(for:)` (`<name>-install-msi.log` in the cache); `runInstaller` uses them; the "no installed program" message names the MSI log for `.msi`
- [X] T003 [P] [US1] In `app/Sources/MacPlay/AppsView.swift`: the picker accepts `.exe` and `.msi`; the empty-state, hint and picker texts say ".exe or .msi" in all three languages
- [X] T004 [P] [US1] `app/Tests/MacPlayTests/InstallerTests.swift`: Windows path conversion, the command for `.exe`, `.msi` and `.MSI`, the suggested name for an `.msi`
- [X] T005 [US1] Dry run: quiet-install 7-Zip's `.msi` (research.md) into a throwaway wrapper outside `~/Applications/Sikarugir` with the real command plus `/qn`; check the program is found and the MSI log is written; delete the wrapper

- [X] T011 [US1] Found in T005: prefer a windowed program over a console tool in `pickMainProgram`, from the PE header (`isConsoleProgram(atPath:)`) in `app/Sources/MacPlay/WindowsApps.swift`, with tests in `app/Tests/MacPlayTests/InstallerTests.swift`

- [X] T012 [US1] Found with the player's IAP Desktop: `standInForSegoeUI(wrapper:env:)` in `app/Sources/MacPlay/WindowsApps.swift` maps Segoe UI to Tahoma in each new program wrapper; set by hand in the existing IAP wrapper

## Phase 3: Polish

- [X] T006 [P] README: `.msi` next to `.exe`; the MSI log
- [X] T007 [P] `specs/001-windows-apps/spec.md`: note that `.msi` packages are accepted since 012
- [X] T008 Build with `./build.sh`, update `/Applications/MacPlay.app` in place, open from Finder
- [ ] T009 Quickstart walk-through with the player
- [ ] T010 Set `**Status**` to Implemented in `specs/012-msi-installer/spec.md`

## Dependencies

T001 → T002 → T003/T004 → T005 → T006–T008 → T009 → T010.
