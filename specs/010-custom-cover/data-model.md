# Data Model: Choose a Game's Cover

## Chosen artwork

| Field | Notes |
|---|---|
| key | `steam:<appid>` or `app:<program name>` (the play-time key) |
| kind | `cover` (portrait card) or `banner` (wide hero) |
| file | `~/Library/Application Support/MacPlay/art/<percent-encoded key>-<kind>.jpg` |
| image | longest side ≤ 1920 px, JPEG quality 0.9 |

- Shown instead of Steam artwork wherever the key's artwork appears (Home, game pages, Steam list).
- Rename of a program: file and play-time entry move to the new key.
- Uninstall of a program: its files are deleted; its play time stays.
- Steam games removed inside Steam: files stay (MacPlay is not told).

## Picker target

| Field | Notes |
|---|---|
| key | as above |
| title | game or program name (search words, sheet title) |
| kind | cover or banner |
