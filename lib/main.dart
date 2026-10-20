import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/app/app.dart';
import 'package:mazraa_driver/core/notifications/driver_push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDriverPush();
  runApp(const ProviderScope(child: MazraaDriverApp()));
}
