import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// Interactive Google Maps SDK map with *only* server/device coordinates.
/// Road directions are opened through the Google Maps navigation app.
/// A decorative reference asset is never presented as a real road route.
class MapPanel extends StatelessWidget {
  const MapPanel({
    this.driver,
    this.store,
    this.customer,
    this.height = 310,
    this.onLocate,
    super.key,
  });

  final GeoPoint? driver;
  final GeoPoint? store;
  final GeoPoint? customer;
  final double height;
  final VoidCallback? onLocate;

  GeoPoint? get _center => driver ?? store ?? customer;
  bool get _hasLocations => _center != null;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final ready = AppEnvironment.mapsEnabled && _hasLocations;
    final center = _center;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: height,
        child: Stack(children: [
          Positioned.fill(
            child: ready
                ? GoogleMap(
                    key: ValueKey('map-${center!.latitude.toStringAsFixed(5)}-${center.longitude.toStringAsFixed(5)}'),
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(center.latitude, center.longitude),
                      zoom: 13.6,
                    ),
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                    markers: {
                      if (driver != null)
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: LatLng(driver!.latitude, driver!.longitude),
                          infoWindow: InfoWindow(title: ar ? 'موقعي' : 'My location'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                      if (store != null)
                        Marker(
                          markerId: const MarkerId('store'),
                          position: LatLng(store!.latitude, store!.longitude),
                          infoWindow: InfoWindow(title: ar ? 'الاستلام' : 'Pickup'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                        ),
                      if (customer != null)
                        Marker(
                          markerId: const MarkerId('customer'),
                          position: LatLng(customer!.latitude, customer!.longitude),
                          infoWindow: InfoWindow(title: ar ? 'العميل' : 'Customer'),
                        ),
                    },
                  )
                : ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              ReferenceAssets.routeMap,
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                              cacheWidth: 240,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              !_hasLocations
                                  ? (ar ? 'لا توجد إحداثيات متاحة بعد' : 'No location coordinates available yet')
                                  : (ar ? 'مفتاح خرائط Google غير مهيأ في هذه النسخة' : 'Google Maps key is not configured in this build'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (ready)
            PositionedDirectional(
              top: 12,
              start: 12,
              child: StatusPill(
                label: ar ? 'خرائط Google' : 'Google Maps',
                icon: Icons.map_outlined,
              ),
            ),
          if (onLocate != null)
            PositionedDirectional(
              end: 14,
              bottom: 14,
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: onLocate,
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
        ]),
      ),
    );
  }
}
