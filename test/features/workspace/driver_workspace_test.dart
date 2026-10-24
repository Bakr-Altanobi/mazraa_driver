import 'package:flutter/material.dart';
import 'package:mazraa_driver/features/operations/driver_account_cache.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/network/api_exception.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/workspace/driver_tool_catalog.dart';
import 'package:mazraa_driver/features/workspace/driver_tool_screens.dart';
import 'package:mazraa_driver/features/workspace/driver_workspace_repository.dart';
import 'package:mazraa_driver/features/workspace/driver_forms.dart';
import 'package:mazraa_driver/features/workspace/driver_delivery_screens.dart';

class RecordingClient extends ApiClient {
  RecordingClient() : super(SecureSessionStore());
  final calls = <String>[];
  Map<String, dynamic>? sent;
  @override
  Future<T> post<T>(String path, {Object? data}) async {
    calls.add('POST $path');
    sent = Map<String, dynamic>.from(data as Map);
    return <String, dynamic>{} as T;
  }

  @override
  Future<T> put<T>(String path, {Object? data}) async {
    calls.add('PUT $path');
    sent = Map<String, dynamic>.from(data as Map);
    return <String, dynamic>{} as T;
  }
}

class UnsupportedRepository extends DriverWorkspaceRepository {
  UnsupportedRepository() : super(RecordingClient());
  @override
  Future<void> submit(String form, Map<String, dynamic> values) async {
    throw const ApiException('Not implemented', statusCode: 404);
  }
}

Widget host(
  Widget child, {
  String language = 'ar',
  bool dark = false,
  List<Override> overrides = const [],
}) => ProviderScope(
  key: UniqueKey(),
  overrides: overrides,
  child: MaterialApp(
    locale: Locale(language),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    home: child,
  ),
);
Future<void> loadDriverFonts() async {
  final arabic = FontLoader('NotoSansArabic')
    ..addFont(rootBundle.load('assets/fonts/NotoSansArabic.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([arabic.load(), icons.load()]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDriverFonts);
  test(
    'switching accounts clears cached bank records and phone verification state',
    () async {
      var actor = 11;
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          driverBankAccountsProvider.overrideWith((ref) async {
            calls++;
            return [
              {'id': actor, 'bankName': 'Bank $actor'},
            ];
          }),
        ],
      );
      addTearDown(container.dispose);
      final first = await container.read(toolDataProvider('bank').future);
      expect(recordRows(first).single['id'], 11);
      container.read(phoneVerificationTargetProvider.notifier).state =
          '123456789';
      actor = 22;
      container.read(resetDriverAccountCacheProvider)();
      final next = await container.read(toolDataProvider('bank').future);
      expect(recordRows(next).single['id'], 22);
      expect(container.read(phoneVerificationTargetProvider), isNull);
      expect(calls, 2);
    },
  );
  test('all 48 existing design destinations lead to operational routes', () {
    expect(journeyDestinations.length, 48);
    expect(journeyDestinations.keys.toSet(), {for (var i = 1; i <= 48; i++) i});
    expect(driverTools.map((t) => t.id).toSet().length, driverTools.length);
    for (final t in driverTools) {
      if (t.form != null) expect(toolForms.containsKey(t.form), true);
    }
  });
  test(
    'return custody and approved participation expose only legal next actions',
    () {
      expect(returnAction('Assigned'), 'accept');
      expect(returnAction(1), 'pickup');
      expect(returnAction('PickedUp'), 'complete');
      expect(returnAction('ReturnedToStore'), isNull);
      expect(participationAction('Approved'), isNull);
      expect(participationAction(1), isNull);
      expect(participationAction('Requested'), 'withdraw');
      expect(participationAction(null), 'join');
    },
  );
  test('availability retains clock intent and rejects reversed windows', () {
    final row = normalizeToolForm('availability', {
      'dayOfWeek': 2,
      'startTime': '08:00',
      'endTime': '17:30',
    });
    expect(row['startTime'], '08:00:00');
    expect(
      () => normalizeToolForm('availability', {
        'startTime': '18:00',
        'endTime': '17:00',
      }),
      throwsFormatException,
    );
  });
  test(
    'password matching, deletion consent and maintenance chronology enforced',
    () {
      expect(
        () => normalizeToolForm('password', {
          'newPassword': 'password123',
          'confirmPassword': 'different',
        }),
        throwsFormatException,
      );
      expect(
        () => normalizeToolForm('deletion', {'confirmed': false}),
        throwsFormatException,
      );
      expect(
        () => normalizeToolForm('maintenance', {
          'serviceAt': '2024-03-20',
          'nextServiceAt': '2024-03-01',
        }),
        throwsFormatException,
      );
      expect(
        () => normalizeToolForm('maintenance', {
          'serviceAt': '2024-03-20',
          'odometerKm': 200,
          'nextServiceOdometerKm': 100,
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'bank details normalize without a made-up currency or account identity',
    () {
      final row = normalizeToolForm('bank', {
        'iban': 'sa12 3456 7890 1234 5678 9012',
      });
      expect(row['iban'], 'SA1234567890123456789012');
    },
  );
  test('QR envelopes reject another shipment and preserve server token', () {
    expect(
      parseDeliveryQr('{"shipmentId":42,"qrToken":"signed-value"}', 42),
      'signed-value',
    );
    expect(
      parseDeliveryQr(
        'https://example.test/handoff?shipmentId=42&token=signed-value',
        42,
      ),
      'signed-value',
    );
    expect(
      () => parseDeliveryQr('{"shipmentId":43,"qrToken":"signed-value"}', 42),
      throwsFormatException,
    );
    expect(
      () => parseDeliveryQr('{"shipmentId":42}', 42),
      throwsFormatException,
    );
  });
  test('road decoder validates known Google geometry and malformed routes', () {
    final p = decodeRoadPolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(p.length, 3);
    expect(p.first.latitude, 38.5);
    expect(p.last.longitude, closeTo(-126.453, 0.00001));
    expect(() => decodeRoadPolyline('_'), throwsFormatException);
    expect(() => decodeRoadPolyline('!'), throwsFormatException);
  });
  test('forms call the exact existing server contracts', () async {
    final c = RecordingClient();
    final r = DriverWorkspaceRepository(c);
    await r.submit('notifications', {'pushNotifications': false});
    expect(c.calls.last, 'PUT api/driver-journey/me/notification-preferences');
    expect(c.sent!['pushNotifications'], false);
    await r.submit('availability', {'dayOfWeek': 2});
    expect(c.calls.last, 'POST api/driver-journey/me/availability');
    await r.submit('maintenance', {'vehicleId': 7});
    expect(c.calls.last, 'POST api/driver-journey/vehicle-maintenance');
  });
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'operational tool screens render at 360px $language dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          for (final tool in driverTools.where(
            (s) => s.id != 'health' && s.id != 'shifts',
          )) {
            await tester.pumpWidget(
              host(
                DriverToolScreen(key: ValueKey(tool.id), toolId: tool.id),
                language: language,
                dark: dark,
                overrides: [
                  toolDataProvider(tool.id).overrideWith(
                    (ref) async => tool.id == 'feedback'
                        ? {'total': 0, 'items': []}
                        : <dynamic>[],
                  ),
                ],
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(Key('tool-${tool.id}')), findsOneWidget);
            expect(tester.takeException(), isNull, reason: tool.id);
          }
        },
      );
    }
    testWidgets('all editable forms render with keyboard space $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final form in toolForms.keys) {
        await tester.pumpWidget(
          host(
            DriverToolFormScreen(key: ValueKey(form), form: form, title: form),
            language: language,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('submit-tool-form')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: form);
      }
    });
  }
  testWidgets(
    'unsupported server save retains driver input and shows no success',
    (tester) async {
      await tester.pumpWidget(
        host(
          const DriverToolFormScreen(
            form: 'profile',
            title: 'Edit profile',
            pending: true,
          ),
          language: 'en',
          overrides: [
            workspaceRepositoryProvider.overrideWithValue(
              UnsupportedRepository(),
            ),
          ],
        ),
      );
      await tester.enterText(
        find.byKey(const Key('field-name')),
        'Driver Name',
      );
      await tester.enterText(find.byKey(const Key('field-phone')), '123456789');
      await tester.enterText(
        find.byKey(const Key('field-email')),
        'driver@example.test',
      );
      await tester.tap(find.byKey(const Key('submit-tool-form')));
      await tester.pumpAndSettle();
      expect(find.text('Driver Name'), findsOneWidget);
      expect(find.byKey(const Key('form-error')), findsOneWidget);
      expect(find.byKey(const Key('submit-tool-form')), findsOneWidget);
    },
  );
}
