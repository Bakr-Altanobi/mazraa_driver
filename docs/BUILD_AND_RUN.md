# Build and run

## Requirements

- Flutter 3.44 beta / Dart 3.12 as used during verification, or a compatible newer stable toolchain.
- Android SDK with Java 17.
- Android device/emulator for runtime verification.
- macOS + Xcode for an iOS build.

## Commands

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

The API base URL defaults to production and can be changed safely:

```powershell
flutter run --dart-define=MAZRAA_API_URL=https://example.test/
```

Optional local test credentials:

```powershell
flutter run `
  --dart-define=DRIVER_TEST_EMAIL=driver@example.test `
  --dart-define=DRIVER_TEST_PASSWORD=local-only
```

Never commit those values or use an administrator account in the driver app.

## Release signing

Android release signing reads untracked `android/key.properties` when present:

```properties
storeFile=C:/secure/path/mazraa-driver.jks
storePassword=...
keyAlias=...
keyPassword=...
```

Without this file, local release builds fall back to debug signing and are not suitable for store distribution. Rotate any signing or Maps key that has previously been exposed.

## Android permissions

The manifest declares internet, network state, foreground location, camera, and Android 13 notification permission. Background location is intentionally not requested because continuous background tracking and its legal/policy flow are not yet implemented.

## iOS

The iOS structure, bundle ID, location/camera descriptions, and optional Maps secret are prepared. This Windows environment cannot run Xcode, CocoaPods, signing, simulator tests, or create an IPA.

