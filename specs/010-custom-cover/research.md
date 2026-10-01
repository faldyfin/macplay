# Research: Choose a Game's Cover

## Image source

- **Decision**: Google Images in the player's browser; the player brings the image back by dragging,
  pasting or choosing a file. Chosen by the player on 2026-10-01.
- **Rationale**: Google's Custom Search JSON API "is closed to new customers" and existing customers
  have until 2027-01-01 ([Google](https://developers.google.com/custom-search/v1/overview), read
  2026-10-01). Reading result pages from the app is against Google's terms, which forbid "using
  automated means to access content … in violation of … robots.txt"
  ([terms](https://policies.google.com/terms), effective 2026-07-30); google.com/robots.txt has
  `Disallow: /search` for every user agent (fetched 2026-10-01).
- **Alternatives considered**: SteamGridDB's API (in-app grid of portrait covers; needs a free
  personal API key; has a Heartopia entry, id 5505031) — declined by the player for now; scraping
  Google — against its terms.

## Search link

- **Decision**: `https://www.google.com/search?udm=2&q=<title>+game+cover` (banner:
  `+game+wallpaper`), opened with the default browser.
- **Rationale**: `udm=2` returns the image results page (HTTP 200); `tbm=isch` now answers 302
  (checked 2026-10-01). `udm` is undocumented by Google; if it stops working the link still lands on
  a Google search for the same words.

## Formats and size

- **Decision**: decode with ImageIO, scale so the longest side is at most 1920 px, save as JPEG
  (quality 0.9).
- **Rationale**: ImageIO on this Mac decodes JPEG, PNG, WebP, HEIC, AVIF and GIF and encodes JPEG
  (`CGImageSourceCopyTypeIdentifiers` / `CGImageDestinationCopyTypeIdentifiers`, checked
  2026-10-01). Re-encoding also drops anything that is not pixels.

## Intake

- **Decision**: from a drop or paste, try in order: a file URL, image data, a web link (`https`
  only, downloaded once, 30 MB cap), a `data:` image link (decoded in place, as Google's thumbnails
  are). The picker suggests opening the image in full size first, since thumbnails are small.
- **Rationale**: browsers put different types on the drag and the pasteboard; trying each covers
  "Copy Image", dragging the image and dragging its link.

## Storage

- **Decision**: `~/Library/Application Support/MacPlay/art/<key>-<cover|banner>.jpg`, `<key>` the
  play-time key (`steam:<appid>`, `app:<name>`) percent-encoded to stay a valid, unique file name.
- **Rationale**: the player's choice is not re-creatable, so it belongs in Application Support
  rather than Caches; using the play-time key lets rename and uninstall treat both alike.

## Rename and uninstall

- **Decision**: `WindowsApps.rename` moves the chosen artwork and the play-time entry to the new key;
  `WindowsApps.uninstall` deletes the program's chosen artwork once the wrapper is gone. Play time of
  an uninstalled program stays, as history.
- **Rationale**: before this, a rename silently started a new play-time key (009 data model).
