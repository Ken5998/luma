![Luma — Windows screensaver](docs/luma-banner.svg)

# Luma

A Windows screensaver with flowing, GPU-rendered light. Based on [Flux by Sander Melnikov](https://github.com/sandydoo/flux), inspired by the Drift screensaver on macOS.

Luma is an independent MIT-licensed fork, currently under development.

## Features

- Fullscreen animation on each display connected at startup.
- Independent scenes with per-monitor resolution and DPI scaling.
- Hidden cursor in screensaver mode.
- Exit all screens with a key press, mouse click, scroll, or mouse movement.
- A two-second input grace period after each window's first frame prevents accidental startup exits. Keyboard auto-repeat is ignored; mouse movement uses an 8-logical-pixel threshold.
- A windowed desktop mode for development and testing.

## Build

Requires Windows, a stable Rust toolchain installed with rustup, and Visual Studio Build Tools with the C++ x64 tools and Windows SDK.

Run from the repository root in PowerShell:

```powershell
.\scripts\build-windows.ps1
```

The script produces `target\release\Luma.exe` and `target\release\Luma.scr`, and copies the MIT license alongside them. The first build needs access to crates.io.

## Run

```powershell
# Windowed desktop application
.\target\release\Luma.exe

# Fullscreen screensaver on all connected displays
.\scripts\run-screensaver.ps1

# Run the .scr executable in a window
.\scripts\run-screensaver.ps1 -Windowed
```

The launcher runs the executable directly because the Windows `.scr` file association can replace command-line arguments.

### Windows screensaver modes

| Argument | Current behavior |
| --- | --- |
| `/s` | Fullscreen screensaver on every display detected at startup |
| `--windowed` | Windowed desktop prototype |
| `/c` | Informational dialog; settings UI is not implemented yet |
| `/p` | Exits without opening a window; embedded Windows preview is not implemented yet |
| No arguments | Windowed mode for `.exe`; informational dialog for `.scr` |

## Tests

```powershell
cargo test --locked --release -p luma -p luma-desktop
```

GPU tests are ignored by default. Run them on a machine with a supported GPU:

```powershell
cargo test --locked --release -p luma -p luma-desktop -- --ignored --test-threads=1
```

### Manual acceptance checks

1. Run the windowed application and check animation and resizing.
2. Launch the screensaver with multiple displays connected; each should fill its own screen without borders or a visible cursor.
3. Check mixed resolutions and DPI settings, including displays positioned left of or above the primary display.
4. Let the startup grace period finish, then move the mouse or press a key. All windows should close together.
5. Repeat from PowerShell to check that startup modifier-key events do not close the screensaver.

Automated tests do not replace visual checks on real multi-monitor hardware.

## Diagnostics

The launcher enables informational logging. Luma writes `Luma.log` next to its executable (`target\release\Luma.log` for a local build), including detected displays, the first rendered frame on each display, and input-triggered exits. The file is overwritten on each launch. If it cannot be created, logging falls back to stderr.

Losing focus does not close the screensaver.

## Roadmap and current limits

- Embedded preview in Windows Screen Saver Settings.
- Settings UI and persistent preferences.
- Display hot-plug handling; restart Luma after connecting or disconnecting a monitor.
- Custom icon, installer, and uninstall support.
- Performance tuning for multiple high-resolution displays. Each display currently owns a separate simulation and GPU context; scenes do not span display boundaries.

This prototype does not yet include an installer.

## Repository structure

The renderer and desktop Cargo packages are named `luma` and `luma-desktop`. The `flux/` and `flux-desktop/` directories, the Rust dependency alias `flux`, and internal renderer names are retained to make comparison with upstream easier.

`flux-wasm/`, `flux-gl/`, and `web/` contain the inherited web and OpenGL targets. Their full rebranding is still pending; the current development focus is the Windows desktop screensaver.

## Credits and license

Luma is derived from Flux, copyright © 2021 Sander Melnikov, under the [MIT license](LICENSE). Original rendering work remains credited to Flux and its author. The Luma banner is a new SVG asset created for this fork.
