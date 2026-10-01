# Quickstart: Validating Library Sections

## Prerequisites

- Steam installed through MacPlay; TapTap installed as a Windows program.
- Build and install: `cd app && ./build.sh`, then update `/Applications/MacPlay.app` in place and open
  it from Finder.

## Scenarios

1. **Sidebar**: reads My Mac, Steam, Compatible Games, My Games, My Apps; no "Windows apps", no
   separate Steam "My games". (Spec US3)
2. **Steam games**: open Steam; the Installed games box lists Steam's games (or the empty state);
   open one, see Play / engine / rating, go back. (Spec US1)
3. **TapTap under My Games**: open My Games; TapTap is listed; Launch works. (Spec US2, SC-003)
4. **Move between sections**: on TapTap's page set Category to App; it now appears under My Apps;
   set it back to Game. (Spec US2, SC-002)
5. **Install preset**: in My Apps click "Install a Windows program…", pick a setup file; the form's
   Category shows App; cancel. Same from My Games shows Game. (Spec US2)
6. **Stored category**: `plutil -extract "MacPlay Category" raw ~/Applications/Sikarugir/TapTap.app/Contents/Info.plist`
   prints `game`. (Data model)
