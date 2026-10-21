# Driver maps

The owner explicitly authorized reusing the development Google project key embedded in the customer app. Android reads it from `android/dev-maps.properties`; iOS reads `ios/Flutter/DevelopmentMaps.xcconfig`. Google Maps is enabled by default, including CI debug APKs. These are development settings, not a claim that the Google project enables every Maps API or permits every signing certificate.

Override the development key with `GOOGLE_MAPS_API_KEY`, or `MAPS_API_KEY` in `android/local.properties`. iOS `Secrets.xcconfig` overrides the checked-in development configuration. The package/bundle identifier is `com.mazraa.driver`. Maps SDK for Android/iOS and the appropriate Google project billing/credentials restrictions must permit that app. CI checks that a nonempty Google key is packaged in the native Android manifest without logging its value.

The native map displays actual driver, pickup and customer coordinates, traffic and dark styling. `/shipments/{id}/navigation` requests the authenticated server endpoint `GET api/Shipments/{id}/road-route?to=pickup|customer`. Only a successful `isRoadRoute=true` response with a valid encoded polyline is drawn as a road route. An unavailable/unconfigured server Routes service produces an explicit message and external Google Maps navigation remains available. The SDK key is not used to make unauthenticated client Routes REST calls.

Widget tests disable native map surfaces with `ENABLE_GOOGLE_MAPS=false`; APK and unsigned iOS builds enable them. Compilation and a packaged key do not prove Google authorization or tile rendering on a real device. Device validation should confirm map tiles, live permission grants, GPS, QR camera and push delivery. Driver Firebase app configuration is separate from the existing Google key.

Google setup reference: https://developers.google.com/maps/flutter-package/config
