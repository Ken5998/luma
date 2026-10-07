# Native MSI candidate — validation in progress

This experimental package adds screen saver activation and restoration to the
earlier file-only MSI prototype. It is **not ready to replace the published
installer**. The release workflow and public downloads still use the existing
v0.1.0 package.

## Behavior

- Per-user installation in `%LOCALAPPDATA%\Luma\WindowsInstaller`.
- Exact published v0.1.0 `Luma.scr`, plus the current repository MIT license,
  including both upstream and Luma copyright notices.
- Native Rust DLL actions; no PowerShell is shipped or launched for normal MSI
  activation, restoration, repair or ZIP migration. The legacy Inno uninstaller,
  if used for migration, still runs its existing PowerShell helper.
- First installation selects Luma and saves the previous selection's registry
  type and bytes. Uninstall restores that value only if this copy is still
  selected. Repair and upgrade preserve a newer user choice.
- Selection changes have matching rollback actions.
- Managed ZIP migration retains the pre-Luma selection, removes only explicitly
  owned legacy files after installation commits, and preserves unknown files and
  preferences. Unmanaged or invalid metadata stops installation before changes.
- Inno migration requires a valid registration pointing to the matching legacy
  directory. If an Inno uninstaller is present but registration is unavailable,
  installation stops: it must never delete that installation as if it were a ZIP.
  Uninstall the old installer through Windows Installed Apps before retrying.
- Legacy cleanup is a commit action. A cleanup failure is logged and can leave
  the old installation present; installation of the new copy has already committed.
- Close Luma and its Windows preview/settings before installation or removal.

The candidate uses the prototype's upgrade family; remove any old MSI prototype
before manual testing. Its test version numbers do not change Luma's public version.

## Build

Use Windows x64, Rust, PowerShell 7, and the WiX 5.0.2 tool/UI extension prepared
as described in [msi-prototype.md](msi-prototype.md). The native dependency lockfile
is committed. Cargo builds offline, so those locked crates must already be cached.
The build uses a static CRT and restores any existing `RUSTFLAGS` afterward.

```powershell
./scripts/package-msi-candidate.ps1
```

The output is under `target/msi-candidate/0.1.2/package/`. This build excludes the
test-only registry seeding, reporting, restoration and injected failure hooks.

For integration testing, build two dedicated test packages:

```powershell
./scripts/package-msi-candidate.ps1 -TestHooks
./scripts/package-msi-candidate.ps1 -Version 0.1.3 -TestHooks
./scripts/test-msi-candidate.ps1 `
  -MsiPath target/msi-candidate/0.1.2/test/Luma-0.1.2-MSI-Candidate-x64.msi `
  -UpgradeMsiPath target/msi-candidate/0.1.3/test/Luma-0.1.3-MSI-Candidate-x64.msi
```

The test runner supports Windows PowerShell 5.1 and PowerShell 7. Run the tests
directly from a normal PowerShell session outside Codex's restricted
execution environment, preferably in a dedicated Windows test account. They
temporarily change the screen saver selection and deliberately fail transactions.
They refuse an existing candidate directory and attempt to repair/remove the
candidate and restore the native initial selection in `finally`.

The optional `-LegacySetupPath` tests migration from the actual published Inno EXE.
It refuses an existing Inno registration; use a clean test account. Test logs and
receipts remain under `target/msi-candidate-tests-*`.

## Evidence on 2026-10-07

WiX compilation and validation pass. Production MSI custom-action tables contain
no test actions, and its DLL contains none of the test hook names.

The integration tests passed these cases in the automated environment:

- Installation, exact release payload hash, repair and normal removal.
- Exact restoration of the initial value, including an absent selection.
- Failed installation restores selection and removes its newly installed payload.
- Major upgrade, downgrade prevention, preservation of a newer selection.
- Managed ZIP migration, failed migration rollback and unknown-file preservation.

**Outstanding:** an injected uninstall failure restores Luma's selection, but
Windows Installer's own rollback logs registry errors (including access denied and
invalid owner). Subsequent uninstall can leave files because component ownership
was lost. Test cleanup repairs the MSI before removing it. The full test command
currently exits with a failure; it must pass outside the automated environment
before promotion. Do not interpret the passing selection assertion alone as a
successful uninstall rollback.

The actual Inno test also exposed different registry visibility: PowerShell could
read its registration while the native MSI action could not. The new guard stops
this case before deleting old files. Inno migration remains unvalidated.

Earlier selection discrepancies also reproduce between PowerShell and MSI actions
for the same user SID and registry key. Receipts therefore read values inside the
native action context. The cause is not established; these receipts do not replace
manual verification in Windows Screen Saver Settings.

The complete candidate has **not** been submitted to VirusTotal. The earlier
file-only prototype's 0/51 report does not apply to this new MSI or native DLL.
Scan both final artifacts after functional validation, and retain their SHA-256
checksums from `SHA256SUMS.txt` with the reports.
