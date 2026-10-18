import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mazraa_driver/core/models/app_models.dart';

/// Opens navigation from the real shipment/driver coordinates. No fake route
/// line, canned ETA or additional Google Directions API key is used.
class ShipmentNavigationButton extends StatelessWidget {
  const ShipmentNavigationButton({
    required this.destination,
    required this.label,
    required this.icon,
    super.key,
  });

  final GeoPoint destination;
  final String label;
  final IconData icon;

  static Uri navigationUrl(GeoPoint point) {
    final latitude = point.latitude;
    final longitude = point.longitude;
    if (!latitude.isFinite || !longitude.isFinite ||
        latitude.abs() > 90 || longitude.abs() > 180) {
      throw const FormatException('إحداثيات الوجهة غير صالحة.');
    }
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    });
  }

  Future<void> _navigate(BuildContext context) async {
    try {
      final opened = await launchUrl(
        navigationUrl(destination),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw StateError('تعذر فتح تطبيق الخرائط على هذا الجهاز.');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        onPressed: () => _navigate(context),
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
}
