# Installer detection investigation

## Baseline, 2026-09-16

The released v0.1.0 installer, SHA-256
`e0361bffc45347e45bb9721e07adb88c6fbd5556e9e164c7264f3b2a19861fe4`,
received **2/68** detections: **DeepInstinct — MALICIOUS** and
**SecureAge — Malicious**. Microsoft and the other engines with completed
supported results did not flag it. These are generic labels, not an identified
malware family or a vendor explanation of the triggering feature.

The v0.1.0 ZIP, SHA-256
`ddc3c6a62d59771c9e1cb7dd7e75565302b61a60bbc3be9dd782fa052e3ad1d6`,
returned zero malicious and zero suspicious results. A clean archive report
does not prove every nested executable is clean.

Links: [original setup report](https://www.virustotal.com/gui/file/e0361bffc45347e45bb9721e07adb88c6fbd5556e9e164c7264f3b2a19861fe4/detection),
[original ZIP report](https://www.virustotal.com/gui/file/ddc3c6a62d59771c9e1cb7dd7e75565302b61a60bbc3be9dd782fa052e3ad1d6/detection).

## Engineering change

The old setup extracted PowerShell scripts to a temporary directory and ran
them hidden with `-ExecutionPolicy Bypass` for preparation and uninstall.
Those actions only needed local file checks, JSON metadata and the current
user's screensaver registry value. The new `luma-installer` Rust helper performs
those same limited operations directly, with no shell, interpreter, network,
downloads or elevation. The graphical setup no longer ships those legacy
PowerShell action files. The ZIP install scripts and the application's existing
settings dialog remain separate and unchanged.

This removes an unnecessary interpreter dependency and policy override; it is
not proof that either feature caused the two antivirus detections. The helper
validates existing metadata, checks exclusive access to the installed binary,
preserves the original screensaver across upgrades, accepts old ZIP metadata,
and leaves newer user selections untouched. A missing prior screensaver is
restored to no selection. Invalid metadata fails without registry changes.

## Verification

`Verify installer remediation` downloads the original release and checks both
asset hashes before extracting its exact screensaver payload. It builds/tests
the helper, compiles setup using pinned, hash- and publisher-verified Inno Setup
6.7.3, runs the real install/update/uninstall/migration tests on a disposable
Windows runner, and submits the resulting setup and original ZIP to VirusTotal.
The existing public release is not replaced during this investigation.

Generic classifications cannot establish the exact cause. A new file also has
a different hash and reputation. Even if a new scan improves, it does not by
itself prove causation, certify safety, or remove SmartScreen warnings.
Only the detecting vendors can confirm and correct their classifications:
[VirusTotal guidance](https://docs.virustotal.com/docs/false-positive).
