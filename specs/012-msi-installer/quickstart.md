# Quickstart: Validating MSI Installers

1. `cd app && swift test`: the installer tests pass.
2. Build (`./build.sh`), update `/Applications/MacPlay.app` in place, open it from Finder.
3. My Apps → Install: the picker lets you choose an `.msi` (e.g. 7-Zip's `7z2603-x64.msi`).
4. The Windows Installer window appears; finish it. MacPlay reports the program it found.
5. Launch the new app: the program opens.
6. Install again and cancel the installer: MacPlay says no program was found and names the log
   `~/Library/Caches/macplay/<name>-install-msi.log`.
7. Uninstall the test apps.
