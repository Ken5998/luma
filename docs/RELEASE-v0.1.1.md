# Luma v0.1.1 — ZIP recommended, experimental MSI

**Pre-release. Use the ZIP for installation; the MSI is available for testing.**

## Downloads

- **Luma-0.1.1-windows-x64.zip — recommended.** Extract all files, close Luma and Windows Screen Saver Settings, and run `Install.cmd`. No administrator rights are needed.
- **Luma-0.1.1-Setup-x64.msi — experimental.** Native graphical per-user installer, with the rollback limitation below.
- **SHA256SUMS.txt** — SHA-256 checksums for these exact two files.

The Inno Setup EXE is withdrawn from public downloads following antivirus detections.
Historical reports are retained in the [installer investigation](https://github.com/Ken5998/luma/blob/main/docs/INSTALLER-TRUST.md). No confirmed false-positive correction is claimed.

## Changes

- Introduces a native per-user MSI, without an administrator prompt or PowerShell setup helper. The application's settings dialog still uses Windows PowerShell.
- Managed default-directory ZIP/Inno migration preserves appearance preferences and the previous screensaver selection.
- MSI repair, upgrades, downgrade prevention and removal through Windows Installed Apps.
- Keeps the script-based ZIP installation available and recommended.
- Aligns the README and website with the published packages and their limitations.

## Known MSI rollback limitation

If an uninstall fails and rolls back, the next uninstall can return success while leaving its files. File restoration works, but MSI registration is not fully recovered. This reproduces without administrator privileges on two Windows 11 PCs and Windows Server 2022/2025, including a minimal package with no Luma DLL.

Normal installation/removal tests pass. The defect concerns the installer transaction. The MSI remains experimental until a correction is verified. [Evidence](https://github.com/Ken5998/luma/blob/main/docs/MSI-RELEASE.md) · [Upstream report](https://github.com/wixtoolset/issues/issues/8574#issuecomment-6101186682).

The tested recovery is to run the same MSI again to reinstall/repair, then retry removal. Keep the MSI if you test it. Do not manually delete Windows Installer registry entries.

## Upgrading and switching packages

- Existing ZIP install: close Luma and the Windows preview, then run `Install.cmd` from the new ZIP.
- Existing v0.1.0 Inno install → ZIP: uninstall the old copy through Windows Installed Apps first, then install the ZIP.
- MSI installations use the MSI for updates/removal. ZIP scripts do not manage MSI-owned files.

Appearance preferences in `%LOCALAPPDATA%\Luma\settings.json` are kept. Open Windows Screen Saver Settings after installation to check selection, wait time and sign-in preference. Package installation changes selection, not activation, wait time or password requirements.

Packages are unsigned. Antivirus results will be added for the exact final artifacts; no result is claimed for unscanned or different builds. Luma remains an independent MIT-licensed fork of Flux by Sander Melnikov.
