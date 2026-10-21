import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

/// Interactive map using only server/device coordinates; OSM works without
/// the rejected development Google key. The Google SDK remains selectable.
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
    this.route = const [],
    super.key,
  });

  final List<GeoPoint> route;
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
  final _osmController = fm.MapController();
  bool _osmReady = false;
  bool _tileError = false;
  bool _google =
      const String.fromEnvironment(
        'MAP_PROVIDER',
        defaultValue: 'openstreetmap',
      ) ==
      'google';

  GeoPoint? get _center => widget.driver ?? widget.store ?? widget.customer;
  bool get _hasLocations => _center != null;

  List<GeoPoint> get _points => [
    ...widget.route,
    if (widget.driver != null) widget.driver!,
    if (widget.store != null) widget.store!,
    if (widget.customer != null) widget.customer!,
  ];

  @override
  void didUpdateWidget(covariant MapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route ||
        oldWidget.driver?.latitude != widget.driver?.latitude ||
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
    if (!mounted || points.isEmpty) return;
    if (!_google) {
      if (!_osmReady) return;
      if (points.length == 1) {
        _osmController.move(
          ll.LatLng(points.first.latitude, points.first.longitude),
          15,
        );
      } else {
        _osmController.fitCamera(
          fm.CameraFit.bounds(
            bounds: fm.LatLngBounds.fromPoints(
              points.map((p) => ll.LatLng(p.latitude, p.longitude)).toList(),
            ),
            padding: const EdgeInsets.all(58),
            maxZoom: 16,
          ),
        );
      }
      return;
    }
    if (controller == null) return;
    if (points.length == 1) {
      controller
          .animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(points.first.latitude, points.first.longitude),
              15,
            ),
          )
          .catchError((Object _) {});
      return;
    }
    final south = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final north = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final west = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final east = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    // Fit actual locations; never display a straight line as a road route.
    controller
        .animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(south, west),
              northeast: LatLng(north, east),
            ),
            68,
          ),
        )
        .catchError((Object _) {});
  }

  Widget _osmMap(BuildContext context, GeoPoint center) {
    final ar = isArabic(context);
    fm.Marker marker(
      GeoPoint point,
      IconData icon,
      Color color,
      String label,
    ) => fm.Marker(
      point: ll.LatLng(point.latitude, point.longitude),
      width: 42,
      height: 42,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
    return fm.FlutterMap(
      key: const ValueKey('openstreetmap-driver-map'),
      mapController: _osmController,
      options: fm.MapOptions(
        initialCenter: ll.LatLng(center.latitude, center.longitude),
        initialZoom: 13.6,
        initialCameraFit: _points.length < 2
            ? null
            : fm.CameraFit.bounds(
                bounds: fm.LatLngBounds.fromPoints(
                  _points
                      .map((p) => ll.LatLng(p.latitude, p.longitude))
                      .toList(),
                ),
                padding: const EdgeInsets.all(58),
                maxZoom: 16,
              ),
        onPositionChanged: (camera, gesture) {
          if (const bool.fromEnvironment('MAP_DEVICE_VERIFICATION'))
            debugPrint(
              'MAP_VIEWPORT ${camera.center.latitude}|${camera.center.longitude}|${camera.zoom}',
            );
        },
        onMapReady: () {
          _osmReady = true;
          debugPrint('Mazraa map ready: OpenStreetMap');
          if (const bool.fromEnvironment('MAP_DEVICE_VERIFICATION'))
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _osmReady) {
                final camera = _osmController.camera;
                debugPrint(
                  'MAP_VIEWPORT ${camera.center.latitude}|${camera.center.longitude}|${camera.zoom}',
                );
              }
            });
        },
      ),
      children: [
        fm.TileLayer(
          urlTemplate: const String.fromEnvironment(
            'MAP_TILE_URL',
            defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          userAgentPackageName: 'com.mazraa.driver',
          maxNativeZoom: 19,
          errorTileCallback: (tile, error, stack) {
            if (mounted && !_tileError)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _tileError = true);
              });
          },
        ),
        if (widget.route.length > 1)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: widget.route
                    .map((p) => ll.LatLng(p.latitude, p.longitude))
                    .toList(),
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 5,
              ),
            ],
          ),
        fm.MarkerLayer(
          markers: [
            if (widget.driver != null)
              marker(
                widget.driver!,
                Icons.local_shipping,
                Colors.green,
                ar ? 'موقعي' : 'Driver',
              ),
            if (widget.store != null)
              marker(
                widget.store!,
                Icons.store,
                Colors.deepOrange,
                ar ? 'الاستلام' : 'Pickup',
              ),
            if (widget.customer != null)
              marker(
                widget.customer!,
                Icons.location_on,
                Colors.red,
                ar ? 'العميل' : 'Customer',
              ),
          ],
        ),
        fm.SimpleAttributionWidget(
          source: const Text(
            'OpenStreetMap contributors',
            style: TextStyle(fontSize: 10),
          ),
          alignment: Alignment.bottomLeft,
          onTap: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/copyright'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller = null;
    _osmController.dispose();
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
        child: Stack(
          children: [
            Positioned.fill(
              child: ready
                  ? (_google
                        ? GoogleMap(
                            key: const ValueKey('google-driver-map'),
                            onMapCreated: _onMapCreated,
                            style:
                                Theme.of(context).brightness == Brightness.dark
                                ? _darkGoogleMapStyle
                                : null,
                            trafficEnabled: true,
                            mapType: MapType.normal,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                center!.latitude,
                                center.longitude,
                              ),
                              zoom: 13.6,
                            ),
                            myLocationButtonEnabled: false,
                            myLocationEnabled: false,
                            zoomControlsEnabled: false,
                            compassEnabled: true,
                            mapToolbarEnabled: true,
                            polylines: {
                              if (widget.route.length > 1)
                                Polyline(
                                  polylineId: const PolylineId("road-route"),
                                  points: widget.route
                                      .map(
                                        (p) => LatLng(p.latitude, p.longitude),
                                      )
                                      .toList(),
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 5,
                                ),
                            },
                            markers: {
                              if (widget.driver != null)
                                Marker(
                                  markerId: const MarkerId('driver'),
                                  position: LatLng(
                                    widget.driver!.latitude,
                                    widget.driver!.longitude,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: ar ? 'موقعي' : 'My location',
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueGreen,
                                  ),
                                ),
                              if (widget.store != null)
                                Marker(
                                  markerId: const MarkerId('store'),
                                  position: LatLng(
                                    widget.store!.latitude,
                                    widget.store!.longitude,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: ar ? 'الاستلام' : 'Pickup',
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueOrange,
                                  ),
                                ),
                              if (widget.customer != null)
                                Marker(
                                  markerId: const MarkerId('customer'),
                                  position: LatLng(
                                    widget.customer!.latitude,
                                    widget.customer!.longitude,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: ar ? 'العميل' : 'Customer',
                                  ),
                                ),
                            },
                          )
                        : _osmMap(context, center!))
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
                                    ? (ar
                                          ? 'لا توجد إحداثيات متاحة بعد'
                                          : 'No location coordinates available yet')
                                    : (ar
                                          ? 'الخريطة غير متاحة حاليًا'
                                          : 'Map is currently unavailable'),
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
                child: PopupMenuButton<bool>(
                  tooltip: ar ? 'مزود الخريطة' : 'Map provider',
                  onSelected: (value) {
                    if (value == _google) return;
                    setState(() {
                      _google = value;
                      _tileError = false;
                      _osmReady = false;
                    });
                  },
                  itemBuilder: (c) => const [
                    PopupMenuItem(value: false, child: Text('OpenStreetMap')),
                    PopupMenuItem(value: true, child: Text('Google Maps')),
                  ],
                  child: StatusPill(
                    label: _google ? 'Google Maps' : 'OpenStreetMap',
                    icon: Icons.layers_outlined,
                  ),
                ),
              ),
            if (ready && _tileError && !_google)
              PositionedDirectional(
                top: 52,
                start: 12,
                end: 12,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      ar
                          ? 'تعذر تحميل بعض أجزاء الخريطة. تحقق من الاتصال.'
                          : 'Some map tiles could not load. Check your connection.',
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}
