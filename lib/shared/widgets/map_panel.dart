import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// Interactive Google Maps SDK map with *only* server/device coordinates.
/// Road directions are opened through the Google Maps navigation app.
/// A decorative reference asset is never presented as a real road route.
const _darkGoogleMapStyle = r'''
[
  {"elementType":"geometry","stylers":[{"color":"#17252b"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#dce9e4"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#17252b"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#34464b"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#517568"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#10202b"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]}
]
''';

class MapPanel extends StatefulWidget {
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

  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  GoogleMapController? _controller;

  GeoPoint? get _center => widget.driver ?? widget.store ?? widget.customer;
  bool get _hasLocations => _center != null;

  List<GeoPoint> get _points => [
    if (widget.driver != null) widget.driver!,
    if (widget.store != null) widget.store!,
    if (widget.customer != null) widget.customer!,
  ];

  @override
  void didUpdateWidget(covariant MapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driver?.latitude != widget.driver?.latitude ||
        oldWidget.driver?.longitude != widget.driver?.longitude ||
        oldWidget.store?.latitude != widget.store?.latitude ||
        oldWidget.store?.longitude != widget.store?.longitude ||
        oldWidget.customer?.latitude != widget.customer?.latitude ||
        oldWidget.customer?.longitude != widget.customer?.longitude) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _frameAllPoints());
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) => _frameAllPoints());
  }

  void _frameAllPoints() {
    final controller = _controller;
    final points = _points;
    if (!mounted || controller == null || points.isEmpty) return;
    if (points.length == 1) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(points.first.latitude, points.first.longitude), 15,
        ),
      ).catchError((Object _) {});
      return;
    }
    final south = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final north = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final west = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final east = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    // Fit actual locations; never display a straight line as a road route.
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        68,
      ),
    ).catchError((Object _) {});
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final ready = AppEnvironment.mapsEnabled && _hasLocations;
    final center = _center;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: widget.height,
        child: Stack(children: [
          Positioned.fill(
            child: ready
                ? GoogleMap(
                    key: const ValueKey('google-driver-map'),
                    onMapCreated: _onMapCreated,
                    style: Theme.of(context).brightness == Brightness.dark
                        ? _darkGoogleMapStyle
                        : null,
                    trafficEnabled: true,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(center!.latitude, center.longitude),
                      zoom: 13.6,
                    ),
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                    markers: {
                      if (widget.driver != null)
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: LatLng(widget.driver!.latitude, widget.driver!.longitude),
                          infoWindow: InfoWindow(title: ar ? 'موقعي' : 'My location'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                      if (widget.store != null)
                        Marker(
                          markerId: const MarkerId('store'),
                          position: LatLng(widget.store!.latitude, widget.store!.longitude),
                          infoWindow: InfoWindow(title: ar ? 'الاستلام' : 'Pickup'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                        ),
                      if (widget.customer != null)
                        Marker(
                          markerId: const MarkerId('customer'),
                          position: LatLng(widget.customer!.latitude, widget.customer!.longitude),
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
          if (widget.onLocate != null)
            PositionedDirectional(
              end: 14,
              bottom: 14,
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: () {
                  widget.onLocate?.call();
                  _frameAllPoints();
                },
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
