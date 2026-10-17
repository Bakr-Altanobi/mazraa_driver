import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// Live markers only. No default city, fabricated road, or mock location.
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

  bool _valid(GeoPoint? value) => value != null &&
      value.latitude.isFinite && value.longitude.isFinite &&
      value.latitude >= -90 && value.latitude <= 90 &&
      value.longitude >= -180 && value.longitude <= 180;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final courier = _valid(driver) ? driver : null;
    final pickup = _valid(store) ? store : null;
    final destination = _valid(customer) ? customer : null;
    final center = courier ?? pickup ?? destination;
    if (center == null || !AppEnvironment.mapsEnabled) {
      return Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: MazraaColors.sand.withValues(alpha: .35),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: MazraaColors.forest, size: 42),
            const SizedBox(height: 12),
            Text(
              center == null
                  ? (ar ? 'لم تُرسل إحداثيات صحيحة لهذه الشحنة من السيرفر' : 'No valid shipment coordinates from the server')
                  : (ar ? 'فعّل خرائط Google في إعدادات تشغيل التطبيق' : 'Enable Google Maps in app configuration'),
              textAlign: TextAlign.center,
            ),
            if (onLocate != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onLocate,
                icon: const Icon(Icons.my_location_rounded),
                label: Text(ar ? 'تحديث الموقع' : 'Update location'),
              ),
            ],
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                key: const Key('liveDriverGoogleMap'),
                initialCameraPosition: CameraPosition(
                  target: LatLng(center.latitude, center.longitude),
                  zoom: 13.4,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                compassEnabled: true,
                markers: {
                  if (courier != null)
                    Marker(
                      markerId: const MarkerId('driver'),
                      position: LatLng(courier.latitude, courier.longitude),
                      infoWindow: InfoWindow(title: ar ? 'موقع السائق' : 'Driver'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    ),
                  if (pickup != null)
                    Marker(
                      markerId: const MarkerId('store'),
                      position: LatLng(pickup.latitude, pickup.longitude),
                      infoWindow: InfoWindow(title: ar ? 'المتجر' : 'Store'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                    ),
                  if (destination != null)
                    Marker(
                      markerId: const MarkerId('customer'),
                      position: LatLng(destination.latitude, destination.longitude),
                      infoWindow: InfoWindow(title: ar ? 'العميل' : 'Customer'),
                    ),
                },
              ),
            ),
            PositionedDirectional(
              top: 14,
              start: 14,
              child: StatusPill(
                label: ar ? 'خرائط Google' : 'Google Maps',
                icon: Icons.layers_rounded,
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
          ],
        ),
      ),
    );
  }
}
