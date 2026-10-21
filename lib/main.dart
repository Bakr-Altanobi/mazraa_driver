import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/app/app.dart';
import 'package:mazraa_driver/core/notifications/driver_push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Noto Sans Arabic',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await initializeDriverPush();
  runApp(const ProviderScope(child: MazraaDriverApp()));
}
