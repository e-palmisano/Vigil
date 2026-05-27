# Vigil

A lightweight native macOS utility that locks all physical input devices system-wide while keeping your long-running workloads active.

## Features

- **Visible Lock** — blocks keyboard, mouse, and trackpad while keeping the screen visible
- **Obscured Lock** — covers every connected display with a full-screen overlay
- **Touch ID unlock** with password fallback
- **Multi-display support** — covers all connected displays, updates on hot-plug
- **Sleep prevention** — optional, keeps your Mac awake while locked
- **Global keyboard shortcuts** — lock from anywhere
- **Menu bar integration** — always accessible
- **No telemetry** — fully local

## Install

### Homebrew (recommended)

```bash
brew install --cask YOUR_GITHUB_USERNAME/tap/vigil
```

### Manual

Download the latest `.dmg` from [Releases](https://github.com/YOUR_GITHUB_USERNAME/vigil/releases).

## First Launch

Vigil requires **Accessibility permission** to block system-wide input.

On first lock attempt, macOS will prompt you to grant access:
**System Settings → Privacy & Security → Accessibility → Vigil ✓**

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Lock Visibly | `Ctrl+Cmd+L` |
| Lock & Obscure | `Ctrl+Shift+Cmd+L` |
| Emergency Unlock | `Ctrl+Opt+Cmd+V` (hold 3s) |

## Requirements

- macOS 15.2 (Sequoia) or later
- Apple Silicon or Intel Mac

## Building from Source

```bash
brew install xcodegen
xcodegen generate
open Vigil.xcodeproj
```

## License

MIT
