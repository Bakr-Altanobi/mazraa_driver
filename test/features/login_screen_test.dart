import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_screens.dart';

Widget _app(Locale locale, {ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('Arabic login renders RTL content and validates input', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Locale('ar')));
    await tester.pump();

    expect(find.text('أهلًا بك يا كابتن'), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();
    expect(find.text('أدخل بريدًا صحيحًا'), findsOneWidget);
  });

  testWidgets('English login supports dark mode', (tester) async {
    await tester.pumpWidget(
      _app(const Locale('en'), themeMode: ThemeMode.dark),
    );
    await tester.pump();

    expect(find.text('Welcome, driver'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(LoginScreen))).brightness,
      Brightness.dark,
    );
  });
}
