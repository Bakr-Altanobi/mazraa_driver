import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';
import 'package:mazraa_driver/shared/widgets/shipment_navigation_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final center = _center;
    if (center == null) {
      // No fabricated Riyadh coordinate or simulated route is presented to
      // drivers when neither their device nor the backend provides a location.
      return SizedBox(
        height: height,
        child: Card(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    isArabic(context)
                        ? 'الموقع غير متاح، فعّل إذن الموقع أو افتح شحنة ذات إحداثيات.'
                        : 'Location unavailable. Enable location permission or open a shipment with coordinates.',
                    textAlign: TextAlign.center,
                  ),
                  if (onLocate != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onLocate,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(isArabic(context) ? 'تحديث الموقع' : 'Refresh location'),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
              child: AppEnvironment.mapsEnabled
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(center.latitude, center.longitude),
                        zoom: 13.4,
                      ),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                      markers: {
                        if (driver != null)
                          Marker(
                            markerId: const MarkerId('driver'),
                            position: LatLng(
                              driver!.latitude,
                              driver!.longitude,
                            ),
                            infoWindow: InfoWindow(
                              title: isArabic(context)
                                  ? 'موقعك'
                                  : 'Your location',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen,
                            ),
                          ),
                        if (store != null)
                          Marker(
                            markerId: const MarkerId('store'),
                            position: LatLng(store!.latitude, store!.longitude),
                            infoWindow: InfoWindow(
                              title: isArabic(context) ? 'المتجر' : 'Store',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange,
                            ),
                          ),
                        if (customer != null)
                          Marker(
                            markerId: const MarkerId('customer'),
                            position: LatLng(
                              customer!.latitude,
                              customer!.longitude,
                            ),
                            infoWindow: InfoWindow(
                              title: isArabic(context) ? 'العميل' : 'Customer',
                            ),
                          ),
                      },
                    )
                  : CustomPaint(
                      painter: _MapPainter(
                        dark: Theme.of(context).brightness == Brightness.dark,
                        hasStore: store != null,
                        hasCustomer: customer != null,
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
            PositionedDirectional(
              top: 14,
              start: 14,
              child: StatusPill(
                label: AppEnvironment.mapsEnabled
                    ? (isArabic(context) ? 'خرائط مباشرة' : 'Live map')
                    : (isArabic(context) ? 'معاينة الخريطة' : 'Map preview'),
                icon: AppEnvironment.mapsEnabled
                    ? Icons.layers_rounded
                    : Icons.map_outlined,
              ),
            ),
            if (!AppEnvironment.mapsEnabled)
              PositionedDirectional(
                bottom: 14,
                start: 14,
                end: 72,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    isArabic(context)
                        ? 'فعّل مفتاح Google Maps لإظهار الخريطة الحقيقية'
                        : 'Configure Google Maps to show the live map',
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            if (store != null || customer != null)
              PositionedDirectional(
                start: 12,
                end: onLocate == null ? 12 : 66,
                bottom: AppEnvironment.mapsEnabled ? 10 : 72,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (store != null)
                        ShipmentNavigationButton(
                          key: const Key('navigateToPickup'),
                          destination: store!,
                          label: 'الاستلام',
                          icon: Icons.storefront_outlined,
                        ),
                      if (store != null && customer != null)
                        const SizedBox(width: 8),
                      if (customer != null)
                        ShipmentNavigationButton(
                          key: const Key('navigateToCustomer'),
                          destination: customer!,
                          label: 'العميل',
                          icon: Icons.navigation_rounded,
                        ),
                    ],
                  ),
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

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.dark,
    required this.hasStore,
    required this.hasCustomer,
  });
  final bool dark;
  final bool hasStore;
  final bool hasCustomer;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = dark ? const Color(0xFF1C2A21) : const Color(0xFFE8E2D2);
    canvas.drawRect(Offset.zero & size, background);
    final field = Paint()
      ..color = dark ? const Color(0xFF213A2B) : const Color(0xFFDCE5C9);
    for (var i = 0; i < 9; i++) {
      final x = (i * 79.0) % size.width;
      final y = (i * 47.0) % size.height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 35, y - 22, 94, 54),
          const Radius.circular(12),
        ),
        field,
      );
    }
    final road = Paint()
      ..color = dark ? const Color(0xFF667069) : Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final roadEdge = Paint()
      ..color = dark ? const Color(0xFF3D4941) : const Color(0xFFD2CCBC)
      ..strokeWidth = 23
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-20, size.height * .78)
      ..cubicTo(
        size.width * .25,
        size.height * .58,
        size.width * .35,
        size.height * .9,
        size.width * .58,
        size.height * .5,
      )
      ..cubicTo(
        size.width * .72,
        size.height * .24,
        size.width * .85,
        size.height * .44,
        size.width + 20,
        size.height * .15,
      );
    canvas.drawPath(path, roadEdge);
    canvas.drawPath(path, road);
    _marker(
      canvas,
      Offset(size.width * .56, size.height * .51),
      MazraaColors.forest,
      Icons.local_shipping_rounded,
    );
    if (hasStore) {
      _marker(
        canvas,
        Offset(size.width * .22, size.height * .68),
        MazraaColors.orange,
        Icons.storefront_rounded,
      );
    }
    if (hasCustomer) {
      _marker(
        canvas,
        Offset(size.width * .82, size.height * .28),
        MazraaColors.leaf,
        Icons.home_rounded,
      );
    }
  }

  void _marker(Canvas canvas, Offset point, Color color, IconData icon) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: .18);
    canvas.drawCircle(point.translate(0, 3), 19, shadow);
    canvas.drawCircle(point, 18, Paint()..color = color);
    canvas.drawCircle(point, 13, Paint()..color = Colors.white);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 19,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      point - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.dark != dark ||
      oldDelegate.hasStore != hasStore ||
      oldDelegate.hasCustomer != hasCustomer;
}
