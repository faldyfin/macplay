# Data Model: Library Sections

## Program (`WindowsApp`)

| Field | Type | Source | Notes |
|---|---|---|---|
| name | text | wrapper folder name | unchanged |
| wrapperPath | path | `~/Applications/Sikarugir/<name>.app` | unchanged |
| category | `game` \| `app` | `MacPlay Category` in the wrapper's `Info.plist` | **new**; missing or unknown value = `app` |

- **Validation**: only `game` and `app` are written; anything else reads as `app`.
- **Transitions**: `app` ⇄ `game` at any time, from the program page; the program may be running.
- **Set at install**: written together with the program's name and id, before the installer runs,
  so a half-finished install already sits in the right section.
- **Rename**: keeps the category (the rename rewrites only `CFBundleName` and `CFBundleIdentifier`).

## Sections

| Section | Lists |
|---|---|
| Steam | Steam controls, then installed Steam games (from Steam's app manifests) |
| My Games | programs with category `game` |
| My Apps | programs with category `app` |

## Existing data

- TapTap (`~/Applications/Sikarugir/TapTap.app`) gets `MacPlay Category = game`, as the player asked.
- No other wrapper is changed.
