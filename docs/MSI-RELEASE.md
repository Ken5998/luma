# Production MSI release preparation

Luma's next packaging release is being prepared on `codex/msi-release`. It is
not published yet. Public downloads remain v0.1.0 until acceptance passes.
No automatic application updater is introduced by this installer work.

## Design

The existing native Rust selection/migration actions are reused. Windows
Installer owns the two payload files (`Luma.scr` and `LICENSE`). The production
MSI installs in `%LOCALAPPDATA%\Luma\MSI`, without administrator rights or UAC.
It has a separate upgrade family from the experimental prototype/candidate:
`A51E59BE-C086-48C8-8BDA-B382C44316AE`. Test hooks are absent from production.
WiX and its UI extension are pinned at 6.0.2; the native DLL uses a static CRT.
The [WiX maintenance-fee policy](https://docs.firegiant.com/wix/whatsnew/)
requires payment for revenue-generating use; Luma is an individual, noncommercial
open-source project. Reassess the tool policy if that changes.

Preferences at `%LOCALAPPDATA%\Luma\settings.json` are never installed, removed
or rewritten. Activation changes only the executable selection, not idle timeout,
password requirements or activation. Selection type and bytes are backed up and
rolled back. Removal restores the original selection only when Luma is still
selected. Repair and upgrades preserve a newer user selection.

Managed ZIP/Inno copies in the default legacy directory are migrated. Inno
registration is captured with native AppSearch, including the interactive client
registry view; the validated, directory-bound uninstaller runs only after MSI
commit. It is held read-only until process startup, then released so Inno can remove its own file. It is waited for and never forcibly killed.
Failure after commit is reported and can leave both installations present;
the old uninstaller is not part of Windows Installer's atomic transaction.
Unmanaged/invalid metadata or unreadable Inno registration fails before mutation.
Unknown legacy files remain. Reparse installation paths and custom production
install locations are rejected. Locked executables fail with instructions to
close the saver, preview and settings. Restart Manager is disabled.

ZIP installation remains supported independently. Do not use Install.cmd to
replace an MSI-owned file. Use Windows Installed Apps for MSI removal and a
newer MSI for updates. Open Windows Screen Saver Settings after installation
and check selection, preview, Settings, wait time and sign-in preference.

## Build and verify

Windows x64, stable Rust, PowerShell 7 and a .NET SDK (WiX build tool only):

```powershell
cargo test --locked --release -p luma -p luma-desktop
./scripts/test-deployment.ps1
./scripts/test-uninstall-handoff.ps1
./scripts/test-virustotal.ps1
./scripts/package-release.ps1
```

The user's PC needs neither Rust nor .NET for the MSI. The settings dialog still
uses Windows PowerShell. `package-release.ps1` builds the app, ZIP and MSI using
the existing pipeline, then verifies MSI metadata, exact ZIP contents and hashes.
There is no production dependency on Inno Setup.

The `Validate prepared MSI release` workflow builds/reviews the branch on a
disposable Windows runner, explicitly recording whether it is elevated. Such a
pass does not replace non-elevated acceptance. No review artifact is published
as a release or submitted to VirusTotal automatically.

Only after all acceptance checks pass, commit the release-ready documentation,
create the annotated `v0.1.1` tag on the reviewed source and push it. The `Build
draft MSI release` workflow validates the tag/version, runs tests, packages and
creates a **draft only**, refusing any existing release. Review the final Actions
hashes, obtain consent for new public antivirus uploads, and publish the draft
after final acceptance. No tag or existing release is overwritten. Historical Inno files remain
for migration/reproduction of old releases.

## Required acceptance before publication

- [ ] Non-elevated install, repair, upgrade, downgrade rejection and uninstall.
- [ ] Install rollback and uninstall rollback followed by successful removal.
- [ ] Managed ZIP migration, migration rollback and unknown-file preservation.
- [ ] Real v0.1.0 Inno migration and original selection restoration.
- [ ] Native Windows Screen Saver Settings selects the installed copy; preview
  and Settings work. All palettes, clock and multi-monitor exit still work.
- [ ] Existing appearance preferences remain byte-for-byte unchanged.
- [ ] Wait time, activation and sign-in preference remain unchanged.
- [ ] Final MSI and ZIP SHA-256 hashes verified; antivirus results refer to those
  exact files. Unsigned packages must never be described as code signed.
- [ ] README, website and release notes describe the published package accurately.

### Blocking evidence, 2026-10-10

The pure file-only rollback probe still fails on this Windows 11 26H2 host,
build 26300.9550, MSI 5.0.26100.9549, without elevation. A failed uninstall restores
the file, but a subsequent successful uninstall strands it. The runner repairs
ownership and then removes the probe; cleanup passes and selection is unchanged.
This occurs without any Luma DLL. It does not prove an OS-wide issue or justify
elevation.

An independent laptop run on 2026-10-10 reproduced the same sequence with
`Elevated=False`: install succeeded; the deliberately failed uninstall restored
the file; subsequent removal returned 0 but left it present. Repair followed by
removal then removed the file. The subsequently supplied report confirms the same
Windows 11 26H2 build 26300.9550 and MSI 5.0.26100.9549 as the desktop, with
`cleanupPassed=true` and `selectionUnchanged=true`. The supplied rollback log
shows the same failed registry restoration, including error 1307 (invalid owner)
for an Installer UpgradeCodes key, access-denied failures and skipped rollback
operations. File restoration itself succeeds. The laptop probe SHA-256 is
`4614c0495f5462617fb37b9498fba19f67f4c82668152f8d6c6ed7f181a7f261`.
The laptop result rules out a defect confined to the development PC, but does not
identify the underlying cause.

A fresh file-only probe built with WiX 6.0.2 and `InstallerVersion=200` also
reproduced the failure without elevation on the development PC; cleanup passed.
Lowering the minimum engine version alone did not resolve it.

[WiX issue #8574](https://github.com/wixtoolset/issues/issues/8574) reports a related
per-user rollback registration failure. That report concerns failed installation,
while this probe concerns failed uninstallation and subsequent removal. Its
existence is supporting context, not proof of a shared cause or a verified fix.
No installer downloaded from that issue was executed: its MSI metadata was only
read for comparison.

The full [GitHub validation run](https://github.com/Ken5998/luma/actions/runs/38076913244)
passed, including real v0.1.0 Inno migration and removal after uninstall rollback.
Downloaded MSI logs explicitly record `MsiRunningElevated=1`, `Privileged=1` and
`AdminUser=1`, so this pass does not establish the required non-elevated behavior.
The no-administrator publication gate remains open.

See [candidate evidence](msi-candidate.md) and
`scripts/test-msi-rollback-probe.ps1`. Never weaken the failing assertion or
manually delete files to manufacture a successful removal result.

### Local validation of prepared 0.1.1

- All 64 application tests pass, including the 11 GPU tests and embedded settings form normally ignored. Four native MSI unit tests also pass.
- Deployment, registered-uninstaller handoff, offline VirusTotal transport tests and preview resize/shutdown pass.
- Production MSI compilation and embedded MSI/ZIP payload hash comparison pass. Rust reports one informational localized linker-output warning for the action DLL; application build has no warnings.
- Non-elevated install, repair, normal removal, install rollback, upgrade, downgrade prevention, ZIP migration and failed migration rollback pass. Uninstall rollback followed by removal still fails as above; cleanup re-establishes MSI ownership and removes the test copy.
- No final production antivirus submission or signing result is claimed. Real Inno migration passes on the elevated CI runner; non-elevated release acceptance remains open.

### Standard-user comparison workflow

`msi-rollback-validation.yml` builds the isolated file-only probe with the same
pinned WiX 6.0.2 compiler and runs it on Windows Server 2022 and 2025 GitHub-hosted
runners. The CI harness creates a temporary standard account, loads its profile,
resolves its AppData paths, records its token and OS context, and rejects elevated
installer policies. A successful probe also requires MSI logs without elevated
execution properties. Diagnostics are retained as Actions artifacts on failure;
the normal repair/removal cleanup is kept, never replaced with file deletion.
The harness refuses to create accounts outside disposable GitHub-hosted runners.
Server results provide comparison evidence; they do not replace acceptance on the
supported Windows desktop builds. No publication is triggered by this workflow.
The first standard-user comparison run stopped before installation with 1625 on
both Server runners. Its logs report `DisableMsi=1`: unmanaged non-elevated MSI
is blocked by the runner policy. This is not a rollback result. The CI-only
harness temporarily sets `DisableMSI=0` on the disposable VM and restores the
previous policy afterward; it never enables `AlwaysInstallElevated`. No policy
is changed by Luma or by the portable probe on a user's PC. See Microsoft's
[DisableMSI policy documentation](https://learn.microsoft.com/en-us/windows/win32/msi/disablemsi).