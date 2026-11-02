# PiHoleBar

macOS menu bar app for Pi-hole v6. SwiftPM package, no dependencies, macOS 13+.

## Build, run, test
- `./build.sh` builds a universal, ad-hoc signed `PiHoleBar.app` (menu bar only, `LSUIElement`).
- `open PiHoleBar.app`. First launch: enter Pi-hole address and admin password (gear icon). macOS asks for Local Network access.
- `PiHoleBar.app/Contents/MacOS/PiHoleBar --screenshots docs` regenerates the README images offscreen with sample data.
- There is no test target. Verify API changes against a real Pi-hole v6 (`curl` the same endpoints).

## Code map (`Sources/PiHoleBar`)
- `App.swift`: `@main` app, `MenuBarExtra`, `PanelView` (popover UI), `MenuBarIcon`.
- `Model.swift`: `@MainActor` observable state; polls every 10 s; `generation` counter drops stale responses.
- `PiHoleClient.swift`: actor wrapping the v6 REST API; logs in lazily, re-logs in on 401, sid keyed by host.
- `Keychain.swift`: admin password storage.
- `PieIcon.swift`: template (single-color) menu bar icon drawn in code.
- `Screenshots.swift`: offscreen renderer for `docs/*.png`.

## Conventions
- Keep it dependency-free and small. Password only in Keychain, never logged or put in URLs.
- `ImageRenderer` cannot draw AppKit-backed controls, so `PanelView` swaps in `fake(...)` lookalikes when `model.isPreview`.
- Releases: zip `PiHoleBar.app` with `ditto -c -k --keepParent`, attach to a GitHub release, update `sha256` and `version` in the Homebrew cask in `Griff2325/homebrew-tap`.
