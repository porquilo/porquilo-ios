# Porquilo iOS — agents.md

Swift / SwiftUI nutrition tracker. Native iOS client for the self-hosted Porquilo server.
Household-scale multi-user: separate diaries per person, one shared server instance.

---

## Non-negotiables

- **`@Observable` only — never `ObservableObject`, `@StateObject`, or `@ObservedObject`.**
  iOS 17+ baseline makes `@Observable` universally available. Mixing the two systems causes
  subtle update-propagation bugs.
- **Never conflate the two error pipelines.** Server errors decode from the JSON envelope
  into `PorquiloAPIError`. BLE/scale errors come from the CoreBluetooth state machine into
  a separate `ScaleError` type (Phase 3). Different failure kinds, different UI responses —
  never merged into one `AppError`.
- **Never add a third confidence tier.** The model is strictly two states: `Measured`
  (scale only) and `Estimated` (everything else). "Calculated" does not exist in this app.
- **Never hard-code hex values in view files.** All colors come from `DesignTokens.swift`.
- **`project.yml` must keep `INFOPLIST_KEY_UILaunchScreen_Generation: YES` on the `Porquilo`
  target.** Without it, the generated `Info.plist` has no `UILaunchScreen` key, and iOS
  renders the whole app in a small legacy reference canvas centered on the real screen —
  large black bars top and bottom, on every screen, regardless of any SwiftUI code. This is
  a system-level rendering mode, not a safe-area bug; no `.ignoresSafeArea()` anywhere in the
  view hierarchy can fix it (confirmed by reproducing it on stock, pre-Quick-Log `main` with
  zero feature code in the build). Diagnosed by inspecting the *built* `Info.plist` in
  DerivedData for a missing `UILaunchScreen` entry — if the black bars come back, check this
  first before touching any view.
- **Full-screen view backgrounds should still ignore the safe area as a separate layer, not
  as a `.background()` modifier on the content stack** — this is a real, separate, much
  smaller-scale issue (tens of points behind the notch/home indicator, not the large bars
  above). `VStack { ... }.background(Color.x.ignoresSafeArea())` does not reliably fill
  behind the notch/dynamic island/home indicator, because the `VStack` only sizes to fit its
  children — the background inherits that smaller frame regardless of `ignoresSafeArea()`.
  Use `ZStack { Color.x.ignoresSafeArea(); VStack { ... } }` instead, with the background as
  an independent sibling — the pattern `TodayView` and `MainTabView` already use. Fixed this
  way in `WelcomeView` (081cda7) and the Quick Log screens (`QuickLogSearchView`,
  `BarcodeNotFoundView`, `BarcodeScanView`, iOS-10).

---

## Stack

- Swift / SwiftUI, iOS 17+ minimum
- `@Observable` for all state management
- SwiftData for local persistence (diary display cache + scale session durability)
- No third-party analytics, crash reporting, or telemetry SDKs

---

## Project structure

```
Sources/Porquilo/
  App/          PorquiloApp.swift · AppState.swift · AppConstants.swift
  Auth/         Login form, QR pairing scan, server URL entry
  Features/
    Today/      Diary, macro bar, FAB, mode picker sheet
    Library/    Food + recipe catalogue, search
    Reports/    Pinned cards (read-only on mobile)
    Settings/   Account, profile, scale, integrations, data
  Components/   Shared UI components
  Models/       Swift structs mirroring API response shapes
  Services/     KeychainService.swift · APIClient.swift
  Utilities/    DesignTokens.swift
Tests/PorquiloTests/
```

---

## Confidence model

`weight_source` values match the server enum: `scale` · `quick_search` · `quick_barcode` ·
`ai_describe` · `ai_photo`

Confidence rule — no exceptions:
- `scale` → **Measured**: full opacity, no prefix, herb green badge
- all other values → **Estimated**: `~` prefix on all numbers, honey amber badge

Confidence is per-entry, not per-session.

---

## Server error envelope

All non-2xx responses from the server use this shape:
```json
{"error": {"code": "barcode_not_found", "message": "Human-readable string.", "details": {}}}
```
Decoded into `PorquiloAPIError.serverError(code: String, message: String)` in `APIClient`.
All server calls go through `APIClient.shared` — never construct a `URLRequest` in a view.

---

## QR pairing contract

The web dashboard's pairing QR code encodes a JSON string (not a URL):
```json
{"server": "https://nutrition.home.local", "code": "<pairing-code>"}
```
The iOS client (`QRScannerView` / `QRPairingPayloadParser`) decodes this, validates `server`
starts with `http://`/`https://`, and POSTs `{"code": "..."}` to
`{server}/api/auth/pairing/exchange`.

**Assumption, not yet confirmed against the real server**: expired vs. already-used pairing
codes are distinguished by two separate error codes — `pairing_code_expired` and
`pairing_code_already_used` — in the standard error envelope above. Any other error
(network failure, unrecognized code) is treated as a generic scan failure, not routed to
the dedicated error screen. If the server's actual codes differ, update the mapping in
`AuthRootView.startPairingExchange`.