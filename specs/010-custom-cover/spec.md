# Feature Specification: Choose a Game's Cover

**Feature Branch**: `010-custom-cover`

**Created**: 2026-10-01

**Status**: Implemented

**Input**: User description (translated from Indonesian): "On Home, for games without a cover like
Heartopia, can there be an option to choose its cover? A 'browse cover' that searches images on
Google, and we can apply one when we pick it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Give a game without artwork a cover (Priority: P1)

Heartopia sits on Home as a plain placeholder card. The player clicks "Choose a cover" on it, clicks
"Search Google Images", and their browser opens Google Images on the game's name. They drag the
image they like into MacPlay's picker (or copy it and paste, or pick a downloaded file), see it in
the card's shape, and click Apply. The card shows the new cover right away and keeps it.

**Why this priority**: It is exactly what the player asked for; programs installed from an `.exe`
never have artwork otherwise.

**Independent Test**: With a program that has no artwork, choose a cover through Google Images and
check the card on Home, then quit and reopen MacPlay.

**Acceptance Scenarios**:

1. **Given** a card without artwork, **When** the player opens the picker, **Then** it shows the
   game's name, a "Search Google Images" button, a drop area that also accepts pasting, a "Choose
   file…" button and an empty preview.
2. **Given** the picker, **When** the player clicks "Search Google Images", **Then** the default
   browser opens a Google Images search for the game's name.
3. **Given** an image dragged, pasted or chosen, **When** it arrives, **Then** the preview shows it
   cropped to the card's shape, and Apply becomes available.
4. **Given** a preview, **When** the player clicks Apply, **Then** the card shows that image at
   once, and still shows it after MacPlay restarts.

---

### User Story 2 - Replace or reset any game's artwork (Priority: P2)

The player prefers a different look for a game that already has Steam artwork, or for the wide
banner at the top of Home. From the card's or banner's menu they choose "Change cover…" or "Change
banner…", and later "Use default artwork" to go back.

**Why this priority**: Same tool, small extra; Steam's own art is not always the one players like.

**Independent Test**: Change the cover of a Steam game, then reset it.

**Acceptance Scenarios**:

1. **Given** any card in "Your games", **When** the player opens its menu, **Then** it offers
   "Change cover…", and "Use default artwork" when a chosen cover exists.
2. **Given** the banner at the top of Home for an installed game, **When** the player opens its menu,
   **Then** it offers "Change banner…" with a preview in the banner's wide shape, and "Use default
   artwork" when a chosen banner exists.
3. **Given** a chosen cover, **When** the player picks "Use default artwork", **Then** the card goes
   back to the Steam artwork, or the placeholder if there is none.
4. **Given** the Details page of an installed Steam game or a program, **When** it opens, **Then** an
   Artwork box shows its cover and banner with "Change cover…" / "Change banner…", and "Use
   default artwork" for a chosen one (added 2026-10-02: once a cover was set, the player found no
   visible way to change it again).

---

### User Story 3 - Chosen artwork follows the game (Priority: P3)

Renaming a program keeps its chosen artwork (and its play time); uninstalling it removes them.

**Why this priority**: Without it, a rename silently loses the player's choice, and uninstalling
leaves files behind.

**Independent Test**: Choose a cover for a program, rename it, check the card; uninstall it, check
that its artwork files are gone.

**Acceptance Scenarios**:

1. **Given** a program with a chosen cover and recorded play time, **When** the player renames it,
   **Then** Home shows the same cover and the same play time under the new name.
2. **Given** a program with chosen artwork, **When** the player uninstalls it, **Then** its chosen
   artwork is deleted.

### Edge Cases

- The dropped item is not an image (a web page link, a text file): the picker says it is not an
  image and keeps the previous preview.
- A dropped link to an image: MacPlay downloads that one image; if it fails, the picker says so.
- Google's result grid shows small thumbnails: the picker suggests opening the image in full size
  before dragging, for a sharp cover.
- A very large image: it is scaled down before saving, so artwork stays small on disk.
- Images in formats browsers use today (JPEG, PNG, WebP, HEIC): all accepted.
- A Steam game uninstalled from inside Steam: MacPlay is not told, so its chosen artwork stays and
  comes back if the game is reinstalled.
- No network: searching Google needs it; dropping, pasting and choosing files still work.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every card in Home's "Your games" row MUST offer "Change cover…", and the Home banner of
  an installed game MUST offer "Change banner…".
- **FR-002**: A card or banner without artwork MUST show a visible "Choose a cover" / "Choose a
  banner" action, not only a menu entry.
- **FR-003**: The picker MUST open a Google Images search for the game's name in the default browser.
  MacPlay MUST NOT fetch or show Google's results itself.
- **FR-004**: The picker MUST accept an image dragged in, pasted, or chosen from a file, and a dragged
  link to an image, which it downloads once.
- **FR-005**: The picker MUST preview the image in the shape it will have (portrait card or wide
  banner) before it is applied, and apply it only on Apply.
- **FR-006**: Anything that is not a readable image MUST be refused with a message saying so.
- **FR-007**: Chosen artwork MUST be kept on this Mac, take precedence over Steam artwork, survive
  restarts, and be removable with "Use default artwork".
- **FR-008**: Renaming a program MUST keep its chosen artwork and its play time; uninstalling it MUST
  delete its chosen artwork.
- **FR-009**: All new text MUST exist in English, French and Indonesian.
- **FR-010**: The README MUST say where chosen artwork is kept and that a dropped image link is
  downloaded from the site it points to.
- **FR-011**: The Details page of every installed Steam game and program MUST offer changing and
  resetting its cover and banner.

### Key Entities

- **Chosen artwork**: an image the player picked for one game or program, in one of two shapes
  (cover, banner); belongs to that game or program and replaces its default artwork.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player gives a game without artwork a cover from Google Images in under a minute,
  in at most five actions after opening the picker.
- **SC-002**: A chosen cover appears on Home immediately, and again after quitting and reopening.
- **SC-003**: After renaming a program, its cover and play time are unchanged; after uninstalling it,
  none of its chosen artwork remains on disk.
- **SC-004**: Non-image drops never change the artwork.

## Assumptions

- The player decided on Google in the browser only (2026-10-01), after research showed Google's
  image search API is closed to new customers and ends on 2027-01-01, and that reading Google's
  result pages from an app is against Google's terms. In-app result grids (Google, SteamGridDB) are
  out of scope.
- Choosing artwork is offered on Home and on the Details pages of installed games and programs;
  other sections show the chosen artwork wherever they already show artwork.
- Which image to use, and its rights, is the player's choice; the artwork stays on their Mac.
