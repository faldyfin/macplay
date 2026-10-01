# MacPlay

**Play Windows games on your Mac — without touching a terminal.**

MacPlay is a small native macOS app (SwiftUI, Apple Silicon) that makes Windows gaming
on Mac accessible to everyone: one-click Steam setup, per-game graphics engine
selection, settings tuned to your exact chip, and community compatibility ratings.

> ⚠️ **Alpha.** This is an early build, shared to get feedback. Expect rough edges.
> Please [open an issue](../../issues) for anything broken, confusing, or missing.

![MacPlay — Compatible Games tab](docs/app-games.png)

## Standing on the shoulders of giants

MacPlay is a friendly front-end. **All the hard parts come from other projects:**

- **[Sikarugir](https://github.com/Sikarugir-App/Sikarugir)** — the Wine wrapper stack
  MacPlay installs and drives (a continuation of the Wineskin/Kegworks lineage by
  [@Gcenx](https://github.com/Gcenx)). MacPlay downloads the official Sikarugir wrapper,
  engines and winetricks at setup time; none of their binaries are redistributed here.
- **[Wine](https://www.winehq.org/)** — the Windows compatibility layer itself.
- **D3DMetal** (Apple's Game Porting Toolkit), **[DXVK](https://github.com/doitsujin/dxvk)**
  and **[DXMT](https://github.com/3Shain/dxmt)** — the DirectX → Metal/Vulkan translation
  that makes games actually run.

MacPlay is not affiliated with any of these projects, with Valve, or with Apple.
If you find MacPlay useful, those projects deserve your stars first.

## What it does

- **A launcher-style Home** — your most-played game up front with Play, your games and
  well-rated ones as cover cards with their official Steam artwork, search, and cards for
  what's running, your Mac, play time and recently added. Play time is counted while MacPlay
  is open and stays on this Mac.
- **One-click Steam setup** — downloads and assembles the whole Wine + Steam stack
  (engine, prefix, fonts, known workarounds). Launch, stop, reinstall or uninstall it just as easily;
  your installed Steam games are listed right in the Steam section.
- **Per-chip advice, not generic advice** — reads your exact Mac (M-series generation,
  GPU cores, RAM) and recommends a preset, upscaling and an honest fps estimate per game.
- **The right graphics engine per game** — D3DMetal / DXMT / DXVK / WineD3D, applied in
  one click. ~80 hand-tuned games (from Elden Ring to The Witcher 3) come with engine,
  presets and fixes.
- **A compatibility list that keeps itself current** — the hand-tuned games plus ~1,600
  more rated by [AppleGamingWiki](https://www.applegamingwiki.com) reports (CrossOver/Wine,
  with the report date) and anti-cheat blocks from
  [AreWeAntiCheatYet](https://areweanticheatyet.com). Rebuilt weekly; MacPlay picks up the
  new list at most once a day.
- **Launch from the app** — MacPlay boots Steam with your game and watches the session:
  if the game crashes right away, it suggests trying another engine.
- **Any Windows program, not just Steam** — pick a setup `.exe` in *My Games* (games and game
  launchers) or *My Apps* (other software); you can move it between them later. MacPlay gives
  it its own wrapper (~1.4 GB) with the Windows core
  fonts (without them, some games draw blank text), runs the installer, finds the installed
  program and launches it with the engine you pick; stop, rename or uninstall it any time.
  Games a launcher installs live in its wrapper and use that engine.
- **Community ratings with context** — rate a game 1–5★; the report is sent anonymously
  *with your hardware profile and the engine used*, so "runs great" actually means
  something.
- **Honest about limits** — games with kernel anticheat (Fortnite, Valorant, Destiny 2…)
  are flagged as blocked instead of wasting your evening.
- **Pick the screen games open on** — with an external display connected, choose it or the
  built-in one in *My Mac*. Wine opens games on the macOS main display, so MacPlay makes the
  chosen screen the main display while games run, then puts your arrangement back.
- **English, French & Indonesian** UI, follows your system language.

![MacPlay — My Mac tab](docs/app-dashboard.png)

## Install

**Requirements:** Apple Silicon (M1 or later), macOS 14.6+ (what the Sikarugir wrapper
template requires).

1. Download **[MacPlay.dmg](../../releases/latest)**.
2. Open the dmg, drag MacPlay to Applications.
3. First launch: macOS will refuse to open it (this build isn't notarized — that
   requires a paid Apple Developer account). Click **Done** (not "Move to Trash"),
   then go to **System Settings → Privacy & Security → Open Anyway**. One time only.

## What it touches (security)

Fair question for any app, doubly so for an alpha you found on Reddit. Short version:
**no admin password, no root, no sandbox escape into your data.** Everything is in the
open — read [`app/Sources/MacPlay/Engine.swift`](app/Sources/MacPlay/Engine.swift) and
[`app/Sources/MacPlay/WindowsApps.swift`](app/Sources/MacPlay/WindowsApps.swift), they're
the whole story.

What MacPlay **does**:

- **Writes only to folders you already own** — `~/Applications/Sikarugir/` (the Steam
  wrapper, plus one wrapper per Windows program you install) and `~/Library/Caches/macplay`
  + `~/.cache/winetricks` (downloads, installer logs, game artwork). It never writes to `/System`,
  `/Library`, or anywhere privileged.
- **Runs the Windows installers you pick** inside that program's own wrapper. What the
  installer then does is up to the installer, as on Windows.
- **Downloads and runs third-party components at setup** — the Sikarugir wrapper, Wine
  engines, winetricks and Steam's installer, from GitHub, `raw.githubusercontent.com` and
  Steam's CDN; winetricks then fetches Microsoft's core fonts from GitHub. This is the same
  thing every Wine wrapper (Sikarugir, Whisky, CrossOver) does; it's how Windows games run
  on a Mac at all. The wrapper, engine and winetricks are pinned to exact versions and
  checked against their SHA-256 before use (winetricks checks the fonts the same way).
  Steam's installer is the exception: Valve only serves the latest one.
- **Runs standard system binaries**: `curl`, `tar`, `xattr`, `open`, `sysctl`,
  `system_profiler`, `pgrep`, `ps` (play time), and `sh` to run winetricks, plus the bundled `wine`.
- **Removes the quarantine flag** (`xattr -dr com.apple.quarantine`) from the wrappers it
  builds, so Wine can launch — this is a deliberate, scoped Gatekeeper bypass on
  MacPlay's own files only.
- **Rearranges your displays, only if you pick a screen for games** — the chosen screen
  becomes the main display (menu bar and Dock included) when you launch from MacPlay. The
  change is app-scoped: it is undone when every game and launcher has closed, and macOS undoes
  it by itself if MacPlay quits.
- **Downloads the compatibility list** — at most once a day, from this repository on
  `raw.githubusercontent.com`, into `~/Library/Caches/macplay`. It is plain data (ratings,
  notes, links); a broken or emptied list is ignored and the built-in one is used.
- **Downloads game artwork** — cover and banner images by Steam app id from Steam's image
  server, `cdn.akamai.steamstatic.com`, cached in `~/Library/Caches/macplay/art`. The request
  tells Steam's server which games' images are shown; nothing else is sent. An image Steam
  doesn't have is asked for again after 7 days.
- **Counts play time locally** — every 30 seconds while MacPlay is open it lists running
  processes to see which game or program is up, and keeps the totals in its own preferences.
  Never sent anywhere.
- **Sends anonymous ratings** — when you rate a game, the score plus your hardware profile
  (chip, RAM, macOS, engine used) is POSTed to the ratings backend. No account, no personal
  data, and only when you click "Send".

What it **never** does: ask for your password, request root, read your files/keychain/other
apps, or install a background service or launch agent.

Because it's open source, none of this is "trust me" — it's `grep`-able.

## Build from source

```bash
cd app
./build.sh          # → dist/MacPlay.app (SwiftUI via SPM, no Xcode project needed)
```

The app icon comes from `icon/AppIcon-source.png`: `swift icon/make-icon.swift` (from `app/`)
cuts the tile out of it and regenerates `icon/AppIcon.icns`.

The repo also contains the original Python prototype of the engine
(`macplay.py`, dev tool only) and the hand-maintained games list (`data/games.json`).

`data/compatibility.json` is generated: `tools/update_compat.py` merges `data/games.json`
with AppleGamingWiki and AreWeAntiCheatYet, and the *Update compatibility list* workflow
runs it every Monday and commits the result. Don't edit it by hand. To refresh it locally:
`python3 tools/update_compat.py` (standard library only).

Specs for new work use [GitHub Spec Kit](https://github.com/github/spec-kit): project
scaffolding lives in `.specify/`, and the `/speckit-*` Claude Code skills in `.claude/skills/`.

## Contributing / feedback

This alpha exists to collect feedback:

- 🐛 **Something broke?** Open an issue with your chip (e.g. M2 Pro), macOS version,
  the game, and what happened.
- 🎮 **A game is missing or misrated?** Issues and PRs against `data/games.json`
  are very welcome — that hand-tuned list is the heart of the project. Community ratings
  come from AppleGamingWiki: adding your report there improves MacPlay too.
- 💡 **Ideas** on making this simpler for non-technical users are the most valuable
  thing you can send.

## Known limitations (alpha)

- **Steam is the only launcher MacPlay knows inside out** (game database, install and
  launch by game, crash watch, ratings). Other launchers install fine from their `.exe`
  under *My Games*, but MacPlay doesn't see the games inside them: launch those from
  the launcher itself. Whether a given launcher runs under Wine at all is up to Wine.
- Steam's self-updates can be capricious under Wine — if Steam hangs or misbehaves
  after an update, use **"Restart Steam cleanly"** in MacPlay's Steam tab; that
  resolves most of it.
- Not notarized → the one-time Gatekeeper dance described above.
- Launching a game restarts Steam if it was already open (Wine can't forward commands
  to a running Steam instance).
- One engine per wrapper: all Steam games share Steam's engine choice, and each Windows
  app's games share that app's.
- New wrappers run Sikarugir's Wine 11 engine, which fixes mouse and keyboard going dead
  after switching back to a game (Cmd+Tab or the Dock). Its template offers D3DMetal, DXMT
  and DXVK; WineD3D is gone. Wrappers built by earlier MacPlay versions keep their Wine 10
  engine and all four choices.
- Kernel-anticheat multiplayer games will never work through translation.
- Play time only counts while MacPlay is open, and a game started inside a launcher
  (Heartopia in TapTap) counts for the launcher.
- Imported ratings are only as good as the reports behind them. Many AppleGamingWiki
  reports are from 2021-2022, before D3DMetal existed, so check the date shown next to each.
  Imported games have no engine recommendation, and anti-cheat blocks are based on
  Linux/Proton data.
- GitHub turns off scheduled workflows in public repositories after 60 days without
  activity; if the list stops updating, re-enable the workflow in the Actions tab.

## License

[MIT](LICENSE) — for MacPlay's own code and hand-maintained data (`data/games.json`).

`data/compatibility.json` contains content from [AppleGamingWiki](https://www.applegamingwiki.com),
so it is licensed [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/):
credit AppleGamingWiki, no commercial use, share alike. It also includes data from
[AreWeAntiCheatYet](https://github.com/AreWeAntiCheatYet/AreWeAntiCheatYet) (MIT).

The components MacPlay downloads at setup time (Sikarugir wrapper, Wine engines,
winetricks, D3DMetal) belong to their respective projects under their own licenses.
