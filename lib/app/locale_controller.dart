import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { system, english, simplifiedChinese }

class LocaleController extends ValueNotifier<AppLanguage> {
  LocaleController._() : super(AppLanguage.system);

  static final LocaleController instance = LocaleController._();
  static const _preferenceKey = 'app_language';

  SharedPreferences? _preferences;

  Locale? get locale => switch (value) {
    AppLanguage.system => null,
    AppLanguage.english => const Locale('en'),
    AppLanguage.simplifiedChinese => const Locale('zh'),
  };

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    value = _decode(_preferences?.getString(_preferenceKey));
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (value == language) return;
    value = language;
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, language.name);
  }

  @visibleForTesting
  void resetForTesting() {
    _preferences = null;
    value = AppLanguage.system;
  }

  AppLanguage _decode(String? value) => AppLanguage.values.firstWhere(
    (language) => language.name == value,
    orElse: () => AppLanguage.system,
  );
}
