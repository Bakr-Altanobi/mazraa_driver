# Driver maps

The owner explicitly authorized reusing the development Google project key embedded in the customer app. Android reads it from `android/dev-maps.properties`; iOS reads `ios/Flutter/DevelopmentMaps.xcconfig`. Google Maps is enabled by default, including CI debug APKs. These are development settings, not a claim that the Google project enables every Maps API or permits every signing certificate.

Override the development key with `GOOGLE_MAPS_API_KEY`, or `MAPS_API_KEY` in `android/local.properties`. iOS `Secrets.xcconfig` overrides the checked-in development configuration. The package/bundle identifier is `com.mazraa.driver`. Maps SDK for Android/iOS and the appropriate Google project billing/credentials restrictions must permit that app. CI checks that a nonempty Google key is packaged in the native Android manifest without logging its value.

The native map displays actual driver, pickup and customer coordinates, traffic and dark styling. `/shipments/{id}/navigation` requests the authenticated server endpoint `GET api/Shipments/{id}/road-route?to=pickup|customer`. Only a successful `isRoadRoute=true` response with a valid encoded polyline is drawn as a road route. An unavailable/unconfigured server Routes service produces an explicit message and external Google Maps navigation remains available. The SDK key is not used to make unauthenticated client Routes REST calls.

Widget tests disable native map surfaces with `ENABLE_GOOGLE_MAPS=false`; APK and unsigned iOS builds enable them. Compilation and a packaged key do not prove Google authorization or tile rendering on a real device. Device validation should confirm map tiles, live permission grants, GPS, QR camera and push delivery. Driver Firebase app configuration is separate from the existing Google key.

Google setup reference: https://developers.google.com/maps/flutter-package/config


## Device verification on 2026-10-21

The Android emulator confirmed a Google SDK `Authorization failure` for the existing key and package `com.mazraa.driver`. A blank Google surface is not treated as working maps. OpenStreetMap is therefore the default real map, with real coordinates and the same road polylines/markers; the map's provider menu retains Google for a replacement/authorized key. Set `MAP_PROVIDER=google` at build time to choose Google by default after credentials are fixed.

OpenStreetMap requests identify `com.mazraa.driver` and display permanent attribution. `MAP_TILE_URL` supports replacing the tile provider for deployment scale. The app does not implement bulk tile downloads or offline prefetch. Policy: https://operations.osmfoundation.org/policies/tiles/ . The native emulator smoke test now verifies the working default surface; the failed Google check remains recorded in run 39533037791 and its redacted device artifact.
