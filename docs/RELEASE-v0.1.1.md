# Luma v0.1.1 — MSI installer (prepared, unpublished)

- Native per-user Windows Installer package, without administrator privileges.
- Migration from the default managed ZIP/Inno installation preserves appearance
  preferences and the original screen saver selection.
- Repair, upgrade, downgrade prevention and selective restoration on uninstall.
- Native Rust installer actions; no PowerShell setup helper is shipped by MSI.
  The application's settings dialog continues to use Windows PowerShell.
- Portable/script ZIP remains available alongside the MSI.
- Website download buttons follow the latest published release rather than
  rebuilding public downloads when documentation changes.

Expected assets: `Luma-0.1.1-Setup-x64.msi`, `Luma-0.1.1-windows-x64.zip`
and `SHA256SUMS.txt`.

These packages are unsigned. No antivirus result is claimed for rebuilt files.
Publication is gated on the [MSI acceptance checks](MSI-RELEASE.md), including
independent non-elevated rollback and real legacy-migration validation.
