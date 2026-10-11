# Luma v0.1.1 — Native MSI installer

**Stable release with a native per-user MSI installer and an alternative ZIP package. The known uninstall rollback limitation and recovery are documented below.**

## Downloads

- **Luma-0.1.1-windows-x64.zip — alternative package.** Extract all files, close Luma and Windows Screen Saver Settings, and run `Install.cmd`. No administrator rights are needed.
- **Luma-0.1.1-Setup-x64.msi — recommended installer.** Native graphical per-user installer, with the rollback limitation below.
- **SHA256SUMS.txt** — SHA-256 checksums for these exact two files.

The Inno Setup EXE is withdrawn from public downloads following antivirus detections.
Historical reports are retained in the [installer investigation](https://github.com/Ken5998/luma/blob/main/docs/INSTALLER-TRUST.md). No confirmed false-positive correction is claimed.

## Changes

- Introduces a native per-user MSI, without an administrator prompt or PowerShell setup helper. The application's settings dialog still uses Windows PowerShell.
- Managed default-directory ZIP/Inno migration preserves appearance preferences and the previous screensaver selection.
- MSI repair, upgrades, downgrade prevention and removal through Windows Installed Apps.
- Keeps the script-based ZIP installation available as an alternative.
- Aligns the README and website with the published packages and their limitations.

## Known MSI rollback limitation

If an uninstall fails and rolls back, the next uninstall can return success while leaving its files. File restoration works, but MSI registration is not fully recovered. This reproduces without administrator privileges on two Windows 11 PCs and Windows Server 2022/2025, including a minimal package with no Luma DLL.

Normal installation/removal tests pass. The defect concerns the installer transaction. The maintainer accepted stable publication with this known limitation on 2026-10-12; the defect remains unresolved. [Evidence](https://github.com/Ken5998/luma/blob/main/docs/MSI-RELEASE.md) · [Upstream report](https://github.com/wixtoolset/issues/issues/8574#issuecomment-6101186682).

The tested recovery is to run the same MSI again to reinstall/repair, then retry removal. Keep the MSI if you test it. Do not manually delete Windows Installer registry entries.

## Upgrading and switching packages

- Existing ZIP install: close Luma and the Windows preview, then run `Install.cmd` from the new ZIP.
- Existing v0.1.0 Inno install → ZIP: uninstall the old copy through Windows Installed Apps first, then install the ZIP.
- MSI installations use the MSI for updates/removal. ZIP scripts do not manage MSI-owned files.

Appearance preferences in `%LOCALAPPDATA%\Luma\settings.json` are kept. Open Windows Screen Saver Settings after installation to check selection, wait time and sign-in preference. Package installation changes selection, not activation, wait time or password requirements.

Packages are unsigned. Completed VirusTotal analyses for both exact final packages reported zero malicious and zero suspicious results on 2026-10-10. See the report links below; this is not a safety guarantee. Luma remains an independent MIT-licensed fork of Flux by Sander Melnikov.

<!-- luma-virustotal:start -->
## VirusTotal

These release files are public samples. Reports are informational: false positives are possible, and zero detections do not guarantee safety. This does not replace code signing or remove SmartScreen warnings.

Last checked: 2026-10-10 20:14 UTC.

- [Luma-0.1.1-Setup-x64.msi](https://www.virustotal.com/gui/file/19afabb4206f17367ca5f71fe10e4c3663ee71a73108fc0951a81c436f9ec6ad/detection) — submitted; analysis ID: `NjUyZGJiZWI4ZDkyMGYzNmYwMDkwMTJlMjc1MzE1ZWI6MTc5MTY2Mjk1Mw==`.
  Analysis completed: 0 malicious, 0 suspicious engine results. See report for context.
- [Luma-0.1.1-windows-x64.zip](https://www.virustotal.com/gui/file/70110109409bd9bad52b6867fec7dd952d982c98887dffc4e318792ba7cd496b/detection) — submitted; analysis ID: `NzI3MTNlODIxMzRlY2U3MWIxMmE5MjUyODZhOWUyYWY6MTc5MTY2MzAxNw==`.
  Analysis completed: 0 malicious, 0 suspicious engine results. See report for context.
<!-- luma-virustotal:end -->
