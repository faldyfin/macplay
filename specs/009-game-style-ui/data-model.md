# Data Model: Game-Style Interface

## Artwork (cache)

| Field | Notes |
|---|---|
| appid | Steam app id |
| kind | `cover` or `banner` |
| file | first file of the kind's chain that exists on Steam's image server |
| cache path | `~/Library/Caches/macplay/art/<appid>-<file>`; empty `<appid>-<file>.missing` = known absent |

## Play time (`UserDefaults` key `playTime`)

| Field | Type | Notes |
|---|---|---|
| key | text | `steam:<appid>` or `app:<program name>` |
| seconds | integer | grows by the tick length while the title runs |
| lastPlayed | date | set on every tick it runs |

- Renaming a program moves its time to the new key (since 010; before, a new key started).
- Never sent anywhere.

## Home item

| Field | Source |
|---|---|
| title | Steam manifest, program name, or compatibility list |
| art | Artwork (Steam ids only) |
| state | installed / running / compatibility rating |
| action | Play (installed Steam game), Launch (program), open page (compatible game) |
