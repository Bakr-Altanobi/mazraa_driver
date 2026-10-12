# Test report

Date: 2026-10-10 (Asia/Aden)

## Toolchain

- Flutter `3.44.0-0.3.pre` (beta), Dart `3.12.0`.
- Java 17, Android compile/target SDK 36.
- Built APK minimum SDK resolved to 24.
- Android SDK licenses are not all accepted on this machine.
- No Android phone or emulator was connected during the verified session. Windows, Chrome, and Edge were detected; mobile runtime testing was therefore not claimed.
- iOS execution/build was not possible on Windows.

## Static analysis and automated tests

| Command | Result |
|---|---|
| `flutter pub get` | Passed |
| `dart format lib test` | Passed; all files formatted |
| `flutter analyze` | Passed: **No issues found** |
| `flutter test --reporter expanded` | Passed: **14/14 tests** |

Test coverage in this delivery includes:

- Production-shaped auth response parsing, including empty role fields.
- Driver/shipment/tracking JSON parsing and enum variants.
- Shipment state-machine valid, invalid, and closed transitions.
- Explicit regression for the unreachable PickedUp → InTransit workflow.
- Distance, ETA, and financial/currency formatting.
- Arabic login validation and RTL content.
- English login and dark theme.
- Shipment, wallet, and notification widget states using typed server models.

Not executed: device permission UI automation, Google Maps SDK rendering, background location, notification push delivery, SignalR reconnect, camera proof flow, or a full integration test on Android hardware.

## Production API smoke verification

Only authentication and read operations were performed. Tokens and secrets were not printed or persisted in project files.

| Operation | Result |
|---|---|
| `GET /api/products` | Passed; array response |
| `POST /api/Auth/login` with seeded Driver account | Passed; `userId=6`, access and refresh tokens present |
| Role fields in login response | Empty in deployed response; app compensates with driver-profile verification |
| `GET /api/Drivers/6` | Passed; Omar Al-Qadhi, Van, Approved |
| `GET /api/Shipments` | Passed; 4 driver-visible rows at test time |
| `GET /api/wallets/me` | Passed; currency SAR, balance 500.00 at test time |
| `GET /api/notifications/unread-count` | Passed; 7 unread at test time |

No shipment transition, location write, wallet write, notification read receipt, database seed, or production backend change was executed.

## APK builds

| Artifact | Result | Size | SHA-256 |
|---|---|---:|---|
| `build/app/outputs/flutter-apk/app-debug.apk` | Passed | 188,058,787 bytes (179.35 MiB) | `4570836C1F4B187146EBEE4DE797AF8AA87BB31EE71C6AA3A9F1F8B79F1AF4C7` |
| `build/app/outputs/flutter-apk/app-release.apk` | Passed | 57,097,363 bytes (54.45 MiB) | `8100453B01F4DA136B487B15ABCB5DBDD457C0384907B5492E044B7FF7E2CF38` |

`aapt` confirmed package `com.mazraa.driver`, version `1.0.0+1`, compile/target SDK 36, minimum SDK 24. `apksigner` verified APK Signature Scheme v2.

The release artifact is signed with the Android Debug certificate because no private `android/key.properties` was provided. It is installable for testing but **not** a store-production release. A split-per-ABI build was attempted but exceeded the execution timeout and produced no separate artifacts, so no split build is claimed.

## Maps and navigation

- Map UI and safe no-key fallback: implemented and analyzer/widget compatible.
- External Google Maps navigation URI: implemented when coordinates exist.
- Embedded native Google map: not runtime-tested because no Maps key/device was available.
- Road polyline/traffic ETA: not claimed; backend proxy is absent.
- Server Haversine distance/ETA: parsed and labelled as estimated.

## Remaining external blockers

- Android hardware/emulator for install, permission, GPS, camera, and lifecycle verification.
- Restricted Android/iOS Maps keys and enabled billing/APIs.
- macOS/Xcode/Apple signing for iOS build and tests.
- Production release keystore.
- Backend endpoints listed in `KNOWN_BACKEND_GAPS.md`.
- Flutter warns that the project/plugins will eventually need migration to Built-in Kotlin; the current Flutter/Gradle build succeeds.
