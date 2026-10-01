# Contract: Cover Picker

## Entry points (Home)

| Where | Menu (right-click) | Visible button |
|---|---|---|
| "Your games" card | "Change cover…"; "Use default artwork" when a chosen cover exists | "Choose a cover" on a program card without a chosen cover |
| Hero of an installed game or program | "Change banner…"; "Use default artwork" when a chosen banner exists | "Choose a banner" when the hero is a program without a chosen banner |

Compatible games that are not installed get no entry points.

## Sheet

1. Title: "Cover for <name>" / "Banner for <name>".
2. "Search Google Images" opens the browser (see research.md for the link).
3. Hint: open the image in full size, then drag it here or copy it and paste.
4. Drop area = preview in the target shape (2:3 cover, ~3:1 banner); accepts drop and ⌘V.
5. Buttons: "Paste", "Choose file…"; footer: "Use default artwork" (only with a chosen image),
   "Cancel", "Apply" (default, enabled once an image is in the preview).
6. Errors in one line under the preview: not an image; download failed.

## Effects

- Apply: saves the file, closes the sheet, every view showing that key's artwork redraws.
- Use default artwork: deletes the file, views fall back to Steam artwork or the placeholder.
