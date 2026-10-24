import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/driver_api.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/profile/profile_screen.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class _ProfileApi extends DriverApi {
  _ProfileApi(this.result, {this.failCount = 0})
      : super(ApiClient(SecureSessionStore()), SecureSessionStore());
  final DriverProfile result;
  int failCount;
  int calls = 0;

  @override
  Future<DriverProfile> getDriver(int userId) async {
    calls++;
    if (failCount-- > 0) throw StateError('test profile service unavailable');
    if (userId != result.userId) throw StateError('wrong profile requested');
    return result;
  }
}

const _driver = DriverProfile(
  userId: 81, name: 'سائق الاختبار', email: 'driver@example.invalid',
  phone: '+967777000000', vehicleType: 'Van', approvalStatus: 'Approved',
  operationalStatus: 'Online', isAcceptingOrders: true, isVerified: true,
  ratingAverage: 4.5, ratingCount: 12,
  driverCode: 'DRV-81',
);

AuthController _controller(_ProfileApi api, {DriverProfile? profile}) {
  return AuthController(api, SecureSessionStore())
    ..state = AuthState.authenticated
    ..session = const AuthSession(accessToken: 'test-session', refreshToken: 'test-refresh', userId: 81)
    ..profile = profile;
}

Widget _host(AuthController auth) => ProviderScope(
  overrides: [authControllerProvider.overrideWith((ref) => auth)],
  child: const MaterialApp(
    locale: Locale('ar'),
    supportedLocales: [Locale('ar'), Locale('en')],
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: ProfileScreen(),
  ),
);

void main() {
  testWidgets('profile loads real driver and shows account information', (tester) async {
    final api = _ProfileApi(_driver);
    await tester.pumpWidget(_host(_controller(api)));
    await tester.pumpAndSettle();
    expect(api.calls, 1);
    expect(find.text('سائق الاختبار'), findsOneWidget);
    expect(find.text('DRV-81'), findsOneWidget);
    expect(find.byType(ErrorState), findsNothing);
    expect(find.byKey(const Key('profileLoadingIndicator')), findsNothing);
  });

  testWidgets('profile request failure resolves to retry instead of spinner', (tester) async {
    final api = _ProfileApi(_driver, failCount: 1);
    await tester.pumpWidget(_host(_controller(api)));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.byKey(const Key('profileLoadingIndicator')), findsNothing);
    expect(find.textContaining('test profile service unavailable'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(api.calls, 2);
    expect(find.text('سائق الاختبار'), findsOneWidget);
    expect(find.byType(ErrorState), findsNothing);
  });

  testWidgets('refresh error preserves confirmed profile with visible retry', (tester) async {
    final api = _ProfileApi(_driver, failCount: 1);
    await tester.pumpWidget(_host(_controller(api, profile: _driver)));
    await tester.pumpAndSettle();
    expect(find.text('سائق الاختبار'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('سائق الاختبار'), findsOneWidget);
    expect(find.textContaining('test profile service unavailable'), findsOneWidget);
  });
}
