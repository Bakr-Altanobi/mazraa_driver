import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  Locale locale = const Locale('ar');
  bool onboardingCompleted = false;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
    themeMode = switch (prefs.getString('themeMode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    locale = Locale(prefs.getString('locale') ?? 'ar');
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingCompleted = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
  }

  Future<void> setLocale(Locale next) async {
    locale = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', next.languageCode);
  }

  Future<void> setThemeMode(ThemeMode next) async {
    themeMode = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', next.name);
  }
}

final appSettingsProvider = ChangeNotifierProvider<AppSettingsController>((
  ref,
) {
  return AppSettingsController()..restore();
});
