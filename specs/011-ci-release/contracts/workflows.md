# Contract: Workflows

## Release (`.github/workflows/release.yml`)

| | |
|---|---|
| Trigger | `workflow_dispatch` only; input `confirm` (text) |
| `confirm` = `release` | on main: test, build, DMG, `gh release create vX.Y.Z` with DMG + `.sha256` and notes; elsewhere: fails |
| anything else | test, build, DMG uploaded as artifact `MacPlay-X.Y.Z-test` (7 days) |
| nothing to release | fails at "Work out the version" |
| Permissions | `contents: write` for the job |

## CI (`.github/workflows/ci.yml`)

| Job | Runner | Does |
|---|---|---|
| app | macos-26, Xcode 26.6 | `swift build -c release`, `swift test` |
| tools | ubuntu-24.04 | `python3 -m unittest discover -s tools/tests` |
| trivy | ubuntu-24.04 | Trivy fs (vuln, secret, misconfig) → SARIF to Security tab; fails on HIGH/CRITICAL |

Trigger: push to main, pull requests.

## Dependabot (`.github/dependabot.yml`)

`github-actions`, weekly, 7-day cooldown, `ci(deps): …` messages.
