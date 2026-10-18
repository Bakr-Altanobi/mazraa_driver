# Driver Android release checklist

The reference catalog contains 48 asset-backed screens and the operational app enters `/home` after the real driver session is restored. The release build does **not** use CI smoke identity or test data.

## Google Maps

The native Android Google Maps SDK reads `MAPS_API_KEY` from `android/local.properties` (local build) or `MAPS_API_KEY` environment variable. The checked-in Android manifest resolves the `${MAPS_API_KEY}` placeholder. Google Maps is enabled in production builds; the CI smoke flavor uses its test-only fallback.

The previously provided trial key must be installed **locally** in `android/local.properties` or as GitHub secret `GOOGLE_MAPS_ANDROID_API_KEY` for a signed release build. The key has not been committed to this repository. Replace the trial key before public release, enable Maps SDK for Android in the correct Google Cloud project, restrict by package `com.mazraa.driver` and the signing certificate's SHA-1, and test map tiles on a real Android device.

## Signed Play Store bundle

Use workflow **Build Signed Driver Android Bundle** (manual dispatch) once these GitHub Actions secrets are set:

- `GOOGLE_MAPS_ANDROID_API_KEY`
- `ANDROID_SIGNING_KEYSTORE_BASE64` — base64 of the upload keystore (not the password)
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

The workflow fails if any secret is absent, produces `mazraa-driver-signed-release-aab`, and cleans up the temporary keystore. The smoke workflow's `arm64-release.apk` can be **debug-signed** when no `android/key.properties` is supplied; do not upload it to Play Console as a production artifact.

## Required acceptance tests

1. From a clean install, verify splash → onboarding → approved driver login → operational home. Current driver auth uses the server's email/password session and stored access/refresh tokens; phone OTP cannot be claimed complete without a verified external SMS/phone-auth provider.
2. Confirm offline/online and available-offers actions with an **approved** real driver account, including conflict responses for stale offers.
3. Check assigned shipment → accept → pickup → depart → near customer → delivery proof → delivered; also test failure and rejection paths with dedicated test orders.
4. Exercise a shipment's navigation and opt-in foreground location updates; confirm the coordinates update on the server and in customer tracking. Foreground tracking stops when leaving the screen, and this app does not claim background GPS execution.
5. Verify bank account update, payout request, shift updates, delivery preferences, wallet, notifications, documents and support with seeded staging accounts and backend credentials; handle API errors and account restrictions honestly.
6. Compare the 48 asset-backed screens, both light/dark themes, RTL, small devices, screenshots and accessibility. Catalog screens that explicitly show an unsupported server capability are **not** production-ready for that capability.
7. Run both PR CI workflows successfully, verify AAB signing and Maps on a physical Android device, test privacy disclosures and location permissions, check backend uptime and database migrations, and complete the Google Play Data Safety/store listing before publishing.

No real customer orders should be mutated as part of release testing. Do not treat a passing widget/render test or APK compile as an authenticated end-to-end acceptance test.
