<p align="center">
  <img src="assets/vigil-logo.png" width="120" alt="Vigil logo" />
</p>

<h1 align="center">Vigil</h1>

<p align="center">
  <strong>Lock your Mac. Keep your work running.</strong>
</p>

<p align="center">
  A lightweight native macOS utility that blocks all physical input system-wide<br/>
  while keeping your long-running workloads — builds, renders, downloads — fully active.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-15.2%2B-blue?style=flat-square" alt="macOS 15.2+" />
  <img src="https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square" alt="MIT license" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat-square" alt="Swift 6.0" />
  <img src="https://img.shields.io/github/v/release/e-palmisano/vigil?style=flat-square&color=green" alt="Latest release" />
</p>

---

## Features

- 🔒 **Visible Lock** — blocks all input while keeping your screen visible
- 🖤 **Obscured Lock** — covers every display with a full-screen overlay
- 👆 **Touch ID unlock** with automatic password fallback
- 🖥️ **Multi-display support** — overlays all connected screens, updates on hot-plug
- ☕ **Sleep prevention** — keeps your Mac awake while locked
- ⌨️ **Global shortcuts** — lock from any app, instantly
- 🍎 **Menu bar integration** — one click away, always
- 🔕 **No telemetry** — fully local, no network calls

---

## Install

### Homebrew (recommended)

```bash
brew install --cask e-palmisano/tap/vigil
```

### Manual

Download the latest `.dmg` from [Releases](https://github.com/e-palmisano/vigil/releases), open it, and drag **Vigil.app** to `/Applications`.

---

## First Launch

Vigil needs **Accessibility permission** to block system-wide input via CGEventTap.

On the first lock attempt macOS will prompt you automatically. To grant it manually:

1. Open **System Settings**
2. Go to **Privacy & Security → Accessibility**
3. Enable the toggle next to **Vigil**

> Without this permission the lock will silently no-op. If Vigil isn't blocking input, this is the first thing to check.

---

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Lock Visibly | `⌃⌘L` |
| Lock & Obscure | `⌃⇧⌘L` |
| Emergency Unlock | `⌃⌥⌘V` (hold 3 s) |

Shortcuts are fully customisable in **Vigil → Settings → Shortcuts**.

---

## Building from Source

```bash
brew install xcodegen
xcodegen generate
open Vigil.xcodeproj
```

Then build and run with `⌘R` in Xcode. Requires macOS 15.2 SDK (Xcode 16.2+).

---

## FAQ

**Why does macOS ask for Accessibility permission?**
Vigil intercepts keyboard and mouse events at the HID level using `CGEventTap`. This is the only API that blocks input system-wide before it reaches any app. macOS gates it behind Accessibility to prevent malicious use.

**Does it work with multiple displays?**
Yes. In Obscured Lock mode Vigil creates a full-screen overlay on every connected display and listens for screen configuration changes — plug in a monitor while locked and it gets covered automatically.

**What happens if Vigil crashes while the screen is locked?**
On relaunch Vigil detects that it was locked at exit (`wasLockedOnExit`) and presents a recovery prompt. Choosing "Lock Again" restores the lock state immediately.

---

## Contributing

Bug reports and pull requests are welcome. For significant changes please open an issue first to discuss the approach.

```bash
# Run the test suite
xcodebuild test -project Vigil.xcodeproj -scheme VIGTests -destination 'platform=macOS'
```

All 13 test suites must pass before a PR can be merged.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

## Acknowledgements

Vigil was designed and built with the help of two AI collaborators:

- **[Claude Code](https://claude.ai/code)** by Anthropic — pair programmer, architect, and tireless reviewer throughout the entire development process.
- **[Pi Agent](https://github.com/superego-ai/pai)** — personal AI assistant that helped shape ideas, structure decisions, and keep the work grounded.

> *Good tools make good work possible.*
