# Luma v0.1.3 — Multi-monitor scaling fix

This maintenance release fixes the screensaver on setups where the displays use different Windows scaling. On a secondary display with a different scale factor than the primary one, Luma could appear as a smaller window in a corner of the screen instead of covering it.

## Downloads

- **Luma-0.1.3-Setup-x64.msi** — recommended graphical installer for the current user. No administrator rights are needed.
- **Luma-0.1.3-windows-x64.zip** — alternative package. Extract all files and run `Install.cmd`.
- **SHA256SUMS.txt** — SHA-256 checksums for these exact packages.

## Changes

- Each screensaver window now covers its display exactly, even when that display uses a different scale (for example a 4K primary at 150% next to a 1440p display at 100%).
- The window keeps the display's physical resolution if Windows reports a scale change while the screensaver runs.
- `Luma.log` records when a window had to be refitted to its display.
- Updates the application and package version to 0.1.3. Animation, palettes and clock behavior are unchanged.

## Updating

Close Luma, its preview, and Windows Screen Saver Settings before updating.

- **Existing MSI installation:** run the new MSI. Appearance preferences are preserved.
- **Existing ZIP installation:** extract the new ZIP and run `Install.cmd`. ZIP scripts do not manage MSI-owned files or create an Installed Apps entry.
- **Old v0.1.0 Inno EXE installation → ZIP:** uninstall the old copy through Windows Installed Apps first, then install the ZIP. Appearance preferences are kept.

Open Windows Screen Saver Settings afterward to check your selection, preview, wait time and sign-in preference.

## Known MSI uninstall rollback limitation

The known limitation from v0.1.1 remains: if an MSI uninstall fails and rolls back, a later uninstall can report success while leaving files. Normal installation and removal tests pass; this release does not fix the rollback defect.

The tested recovery is to run the same MSI again to reinstall/repair, then retry removal. Keep the MSI if you need recovery. Do not manually delete Windows Installer registry entries. [Investigation and evidence](https://github.com/Ken5998/luma/blob/main/docs/MSI-RELEASE.md) · [Upstream report](https://github.com/wixtoolset/issues/issues/8574#issuecomment-6101186682).

Luma remains an independent MIT-licensed fork of Flux by Sander Melnikov. Appearance preferences in `%LOCALAPPDATA%\Luma\settings.json` are preserved.
