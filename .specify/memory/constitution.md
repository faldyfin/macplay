# MacPlay Constitution

## Core Principles

### I. Native and Dependency-Free

- The app is a SwiftUI executable built with Swift Package Manager (`app/build.sh`). It MUST NOT
  add third-party Swift packages; Apple frameworks only.
- Scripts in the repository (`tools/`, `app/icon/`, `macplay.py`) MUST use only the standard
  library of their language, so they run on a stock Mac or CI runner with nothing to install.
- At run time MacPlay calls only system binaries (`curl`, `tar`, `xattr`, `open`, `sysctl`,
  `system_profiler`, `pgrep`, `ps`, and `sh` to run winetricks) and the launcher and Wine shipped
  inside a wrapper.

Rationale: nothing to install or update besides MacPlay itself, and a small surface to audit.

### II. The User's Folders Only, No Admin Rights

- MacPlay MUST write only to `~/Applications/Sikarugir/` (wrappers), `~/Library/Caches/macplay`
  (downloads, install logs, the downloaded compatibility list, game artwork),
  `~/.cache/winetricks`, and its own preferences (`UserDefaults`: language, screen for games,
  anonymous install id, play time per game).
- It MUST NOT ask for a password, run as root, install background services or launch agents,
  or read the user's files, keychain or other apps.
- A wrapper is deleted only on an explicit, confirmed uninstall of that wrapper.

Rationale: an alpha found online has to be safe to try; the README's security section
promises exactly this and must stay true.

### III. Pinned, Verified Downloads

- Every component MacPlay downloads (wrapper template, Wine engine, winetricks) MUST be pinned
  to an exact version or commit and checked against its SHA-256 before use, cache hits included.
  A mismatch MUST be refused.
- The only exception is Steam's installer, which Valve serves solely as "latest"; it stays
  documented as such.
- GitHub Actions MUST be pinned to a commit SHA. Data MacPlay downloads (the compatibility list)
  MUST be validated before it replaces the bundled copy, and a broken or emptied list is ignored.

Rationale: downloaded code runs with the user's rights; moving tags and branches are not
reproducible.

### IV. Reversible, Opt-In System Changes

- Anything that changes the user's system outside MacPlay's own files MUST be opt-in and
  automatically reversible. Example: choosing a screen for games makes it the main display
  with an app-scoped configuration that macOS undoes if MacPlay quits, and MacPlay undoes once
  no wrapper runs.
- Changes to MacPlay's own files that bypass a macOS protection (removing the quarantine flag
  from a downloaded wrapper) MUST be scoped to those files and documented in the README.
- Destructive actions (uninstall, reinstall, stopping Steam mid-download) MUST ask first.

Rationale: users must always be able to get their Mac back to how it was.

### V. Honest Compatibility Information

- Every rating shown MUST say where it comes from. Imported ratings show their source, the date
  of the latest report (or "undated") and a link; imported games say MacPlay has not tested them.
- MacPlay MUST NOT invent data: no engine recommendation, fps estimate or status without a
  source. Games without one say so.
- Hand-tuned entries (`data/games.json`) keep their status; community data is added next to them,
  not over them.

Rationale: a wrong "runs great" wastes an evening; a dated source lets the user judge.

### VI. Verified Behaviour Over Assumptions

- A change is done when it has been checked against the real system: it builds, it runs, and the
  behaviour was observed (process, file, log, live data), or the remaining unverified part is
  stated plainly.
- Facts about external tools and services (Wine, Sikarugir, macOS APIs, data sources) MUST come
  from their source code, documentation or live output, not memory.
- Claims in the README and specs MUST be reproducible from the code or a cited source.

Rationale: most bugs in this project's history were assumptions (environment variables, engine
layouts, cached icons) that one check would have caught.

### VII. Multilingual UI, Docs in Sync

- Every user-facing string MUST exist in English, French and Indonesian through
  `L.t(en, fr, id)`.
- Every user-visible, security-relevant or licensing change MUST update `README.md` in the same
  change. Specs under `specs/` describe what was built and are kept current with the code.

Rationale: the README is the contract with users; specs are the contract with contributors.

## Security and Licensing Constraints

- Minimum platform: Apple Silicon, macOS 14.6 (the Sikarugir Template-1.0.20 requirement).
- MacPlay is not notarized; the README documents the one-time Gatekeeper step.
- Network access: Sikarugir releases and winetricks (GitHub), Steam's CDN, Steam's image server
  (`cdn.akamai.steamstatic.com`, game artwork, cached), the ratings backend (only when the user
  sends a rating) and the compatibility list (`raw.githubusercontent.com`, at most once a day).
  Any new destination MUST be added to the README.
- Licenses: MacPlay's code and `data/games.json` are MIT. `data/compatibility.json` contains
  AppleGamingWiki content and is CC BY-NC-SA 3.0, with AreWeAntiCheatYet data (MIT). Imported
  data MUST keep its source attribution.
- Trademarks: icons and artwork MUST NOT use third-party logos (Apple, Windows, console brands)
  or SF Symbols in the app icon.

## Development Workflow

- Commits follow Conventional Commits, imperative and lower case, with one change type per
  commit; mixed changes are split. Breaking changes use `!` and a `BREAKING CHANGE:` footer.
- Commits, PRs and code MUST NOT carry AI attribution of any kind.
- Each commit MUST build on its own (`swift build -c release` in `app/`).
- New features go through Spec Kit: `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` →
  `/speckit-implement`, with the spec, plan and tasks committed under `specs/NNN-name/`.
- `data/compatibility.json` is generated by `tools/update_compat.py` (weekly workflow); it is
  never edited by hand.

## Governance

- This constitution overrides other practice in this repository. Specs and plans MUST pass a
  constitution check; any exception is written down in the plan's Complexity Tracking with the
  reason.
- Amendments are made by editing this file in a `docs` commit that explains the change, and by
  updating any spec or README text the amendment affects.
- Versioning: MAJOR for removing or redefining a principle, MINOR for a new principle or section
  or materially expanded guidance, PATCH for wording and clarifications.
- Runtime guidance for agents lives in `.claude/skills/` (Spec Kit) and `README.md`.

**Version**: 1.1.1 | **Ratified**: 2026-10-01 | **Last Amended**: 2026-10-01
