// CI-only native map verification entry point. Never used by lib/main.dart.
// Fixed public coordinates exercise the shared native map without account data.
import 'package:flutter/material.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/shared/widgets/map_panel.dart';

void main() => runApp(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      appBar: AppBar(title: const Text('Driver map verification')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: MapPanel(
          driver: GeoPoint(15.3694, 44.1910),
          store: GeoPoint(15.378, 44.198),
          customer: GeoPoint(15.35, 44.22),
          height: 560,
        ),
      ),
    ),
  ),
);
