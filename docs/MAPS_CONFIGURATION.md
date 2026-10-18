# Maps configuration

Google Maps is enabled in the ARM64 Debug APK only when the build is supplied a valid restricted Android SDK key through the GitHub Actions secret `GOOGLE_MAPS_API_KEY`, or via the untracked local Android properties and the `ENABLE_GOOGLE_MAPS=true` Flutter flag. The UI displays a branded map preview and can still open external Google Maps navigation when destination coordinates are available.

## Android

Add a restricted Android SDK key to the untracked `android/local.properties`:

```properties
MAPS_API_KEY=YOUR_ANDROID_KEY
```

Then run with the Dart feature flag:

```powershell
flutter run --dart-define=ENABLE_GOOGLE_MAPS=true
```

Restrict the key to package `com.mazraa.driver` and the correct SHA-1/SHA-256 signing certificates. Enable Maps SDK for Android. Do not use this key for server-side Routes REST calls.

## iOS

Copy `ios/Flutter/Secrets.xcconfig.example` to `ios/Flutter/Secrets.xcconfig`, set a restricted iOS key, and keep the file untracked. Restrict it to bundle ID `com.mazraa.driver`. `AppDelegate.swift` only initializes Google Maps when a non-placeholder key exists.

An actual iOS build requires macOS, Xcode, CocoaPods or supported Swift Package Manager configuration, and Apple signing.

## Routes and ETA

The current backend tracking endpoint returns Haversine distance and an estimated time based on recent driver speed. It does not expose a Google Routes proxy or an encoded road polyline. The app labels these as estimates and never draws a straight line as if it were a road route.

For production road routing, add an authenticated backend proxy that returns route distance, duration, encoded polyline, waypoint order, and traffic-aware ETA. Keep the server key restricted and never ship it in the application.



## GitHub Actions Debug APK

Set the repository Actions secret `GOOGLE_MAPS_API_KEY` to your restricted Android Maps SDK key. The key is read by Gradle from the build environment, not written into the Git repository or CI logs. The CI Flutter command enables Maps only when the secret exists. Confirm that the key allows package `com.mazraa.driver` and the **GitHub runner's debug signing certificate SHA-1**, which may differ from the local computer's debug key. Prefer a dedicated development key and restrict it by package and signing fingerprint; never commit the value. Enable billing and Maps SDK for Android on the Google Cloud project. Building with a secret does not itself prove tile rendering; verify it on a physical device.
