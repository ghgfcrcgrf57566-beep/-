import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يدير إعدادات المستخدم المستمرة: وضع العرض (ليلي/نهاري/تلقائي) وحجم خط
/// قراءة المواد القانونية. الوضع الافتراضي هو الليلي (الهوية الأساسية
/// للتطبيق)، ويمكن للمستخدم التبديل إلى النهاري أو اتباع إعداد الهاتف.
class SettingsProvider extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _fontScaleKey = 'font_scale';

  ThemeMode _themeMode = ThemeMode.dark;
  double _fontScale = 1.0;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get isLoaded => _loaded;

  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.6;
  static const double fontScaleStep = 0.1;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> increaseFontScale() => _setFontScale(_fontScale + fontScaleStep);
  Future<void> decreaseFontScale() => _setFontScale(_fontScale - fontScaleStep);
  Future<void> resetFontScale() => _setFontScale(1.0);

  Future<void> _setFontScale(double value) async {
    _fontScale = value.clamp(minFontScale, maxFontScale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
  }
}
