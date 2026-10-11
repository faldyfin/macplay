# Research: MSI Installers

## How Wine installs an .msi

- **Decision**: run `wine msiexec /i <package> /l*v <log>` instead of `wine <setup.exe>`.
- **Rationale**: Wine 11.0's `programs/msiexec/msiexec.c` (read 2026-10-11 from wine-mirror/wine at
  `wine-11.0`): `/i` takes the package path (lines 723–738); `/l` followed by `*` (all categories)
  and `v` (verbose) passes the next argument to `MsiEnableLogW` (lines 898–978); without `/q` the
  full interface shows. msiexec hands the path to `MsiInstallProductW` as given (lines 1103–1110).

## Package path

- **Decision**: pass absolute Windows paths: `Z:` plus the Mac path with `\` separators.
- **Rationale**: msiexec doesn't resolve the path itself (above); the template prefix maps `z:` to
  `/` (`prefix/dosdevices/z: -> /`, checked 2026-10-11).

## File picker

- **Decision**: `UTType(filenameExtension: "msi")` next to the `.exe` type.
- **Rationale**: macOS declares no type for `.msi`; the dynamic type `dyn.ah62d4rv4ge80465m` is the
  same one Spotlight gives a real `.msi` file (`mdls` on 7-Zip's package, 2026-10-11).

## Picking the program

- **Decision**: rank candidates by name match, then windowed before console (PE header Subsystem:
  2 windowed, 3 console, at offset 68 of the optional header in 32- and 64-bit files), then depth.
- **Rationale**: the first quiet install of 7-Zip's package picked `7z.exe` (console) over
  `7zFM.exe`; the headers read 3 for `7z.exe` and 2 for `7zFM.exe` and `7zG.exe` (all PE32+). With the
  new rank the same install picks `7zFM.exe`.

## Dry run (2026-10-11)

- Throwaway wrapper in the scratch folder, MacPlay's real `assembleWrapper`, `installerArguments`
  (plus `/qn`), `exeFiles`, `isConsoleProgram` and `pickMainProgram`; package in a folder with a
  space: msiexec exit 0 after 2 s, three `.exe` added under `Program Files\7-Zip`, `7zFM.exe` picked,
  the Windows Installer log written (25 KB, ends "INSTALL. Return value 1").

## IAP Desktop quit right after launch (2026-10-11)

- **Observed**: the player's install of `IapDesktopX64.msi` succeeded ("INSTALL. Return value 1";
  the later "Error 2726: Action not found: ExitDialog" is only the installer's last screen), but
  `IapDesktop.exe` (.NET Framework 4.7, run by Wine Mono 10.4.1) quit within 6 s. With
  `WINE_MONO_TRACE=E:all` (read by Wine 11.0's `dlls/mscoree/metahost.c`) the fatal exception was
  `ArgumentException: The requested FontFamily could not be found`, from `new FontFamily("Segoe UI")`
  in `Google.Solutions.Mvvm.Theme.WindowsSystemDialogRuleset`; IAP Desktop's own error report then
  crashed under Mono, so nothing was shown.
- **Decision**: `HKCU\Software\Wine\Fonts\Replacements`, `"Segoe UI"="Tahoma"` (Tahoma ships in
  the engine's `share/wine/fonts`) in every new program wrapper, right after the core fonts.
- **Check**: set in the player's IAP wrapper, IapDesktop.exe kept running (30 s, then stopped);
  `standInForSegoeUI` on a fresh scratch wrapper wrote the same value.
- **Not verified**: IAP Desktop's sessions (RDP, SSH) under Wine.

## Test package

- 7-Zip 26.03 `7z2603-x64.msi` from github.com/ip7z/7zip (released 2026-09-04, SHA-256
  `c0680064d698a62dd4a5a47f403db356a6531a5473e4c4b1d090ea2590513926`, matching the release's digest).
