import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTextSize { system, small, standard, large, extraLarge }

class TextScaleController extends ValueNotifier<AppTextSize> {
  TextScaleController._() : super(AppTextSize.system);

  static final TextScaleController instance = TextScaleController._();
  static const preferenceKey = 'app_text_size';

  SharedPreferences? _preferences;

  TextScaler apply(TextScaler systemScaler) => switch (value) {
    AppTextSize.system => systemScaler,
    AppTextSize.small => const TextScaler.linear(0.9),
    AppTextSize.standard => TextScaler.noScaling,
    AppTextSize.large => const TextScaler.linear(1.15),
    AppTextSize.extraLarge => const TextScaler.linear(1.3),
  };

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    value = _decode(_preferences?.getString(preferenceKey));
  }

  Future<void> setTextSize(AppTextSize textSize) async {
    if (value == textSize) return;
    value = textSize;
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(preferenceKey, textSize.name);
  }

  @visibleForTesting
  void resetForTesting() {
    _preferences = null;
    value = AppTextSize.system;
  }

  AppTextSize _decode(String? value) => AppTextSize.values.firstWhere(
    (textSize) => textSize.name == value,
    orElse: () => AppTextSize.system,
  );
}
