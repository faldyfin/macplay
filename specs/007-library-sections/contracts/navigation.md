# UI Contract: Navigation

## Sidebar (top to bottom)

| Item | English | French |
|---|---|---|
| dashboard | My Mac | Ma machine |
| steam | Steam | Steam |
| games | Compatible Games | Jeux compatibles |
| myGames | My Games | Mes jeux |
| myApps | My Apps | Mes apps |

Removed: "My games" (Steam games, now inside Steam) and "Windows apps" (now My Games + My Apps).

## Steam section

1. Header: title, Launch / Starting… / Stop (unchanged).
2. Steam box (unchanged).
3. **Installed games** box (only when Steam is installed): one row per game with name, size and
   community rating; empty state when none. A row opens the game page.
4. Game page: the existing page (Play, session status, engine, rating), with a back button to the
   Steam section.

## My Games / My Apps

- Same layout as the old Windows apps section: list, "Install a Windows program…", install form,
  program page.
- Install form: a **Category** picker (Game / App), preset to the section's category.
- Program page: a **Category** picker; changing it moves the program to the other section and returns
  the current section to its list.
- Empty states: My Games mentions game launchers and games; My Apps mentions other software.
