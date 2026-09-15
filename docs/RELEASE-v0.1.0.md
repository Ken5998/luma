# Luma v0.1.0

The first Luma release: flowing, GPU-rendered light for your Windows displays.

## Highlights

- Independent fullscreen animation on every display connected at startup.
- Five color palettes: Original, Plasma, Poolside, Freedom, and Aurora.
- Optional 24-hour clock at the top center of a selected display.
- Native settings for palette, animation speed, line size, and simulation quality.
- Windows Screen Saver Settings integration, including an animated preview.
- A graphical per-user installer with upgrade support and an Installed Apps entry.

## Downloads

- **Luma-0.1.0-Setup-x64.exe** — recommended. Install for the current user without administrator rights.
- **Luma-0.1.0-windows-x64.zip** — extract all files and run `Install.cmd`.
- **SHA256SUMS.txt** — SHA-256 checksums for both packages.

Close Luma and Windows Screen Saver Settings before installing or updating.
Setup can upgrade an existing script-based installation. Both packages preserve
appearance preferences. Uninstall restores the previous screensaver when appropriate
and preserves a newer selection made in Windows.

## Current limits

Packages are unsigned. A supported GPU is required, and Windows PowerShell is used
for settings and installation. Restart Luma after connecting or disconnecting a
display. Code signing and automatic updates are not included.

Luma begins its own version history at 0.1.0. It is an independent MIT-licensed fork
of Flux by Sander Melnikov; original credits and license notices are retained.

Website: https://luma.ksmvc.ch
