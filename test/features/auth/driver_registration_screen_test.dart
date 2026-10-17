import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/features/auth/driver_registration_screen.dart';

void main() {
  testWidgets('signup supports resuming a pending application', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DriverRegistrationScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('تأكيد كلمة المرور'), findsOneWidget);

    final resume = find.byKey(const Key('resumeDriverApplicationButton'));
    await tester.ensureVisible(resume);
    await tester.tap(resume);
    await tester.pumpAndSettle();

    expect(find.text('الاسم الكامل'), findsNothing);
    expect(find.text('تأكيد كلمة المرور'), findsNothing);
    expect(find.text('تسجيل الدخول واستكمال الطلب'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
  });
}
