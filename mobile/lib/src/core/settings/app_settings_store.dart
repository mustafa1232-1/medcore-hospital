// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeStyle { classic, neon, rgbPulse }

class AppSettingsStore extends ChangeNotifier {
  // -----------------------------
  // Keys
  // -----------------------------
  static const _kLocale = 'locale_code';

  static const _kThemeMode = 'theme_mode';
  static const _kThemeStyle = 'theme_style';

  static const _kAccentSeed = 'accent_seed';

  static const _kReduceMotion = 'reduce_motion';
  static const _kCompactUi = 'compact_ui';
  static const _kTextScale = 'text_scale';
  static const _kHaptics = 'haptics';

  // -----------------------------
  // State
  // -----------------------------
  Locale? _locale;

  ThemeMode _themeMode = ThemeMode.system;
  AppThemeStyle _themeStyle = AppThemeStyle.classic;

  // Accent (for classic/neon)
  Color _accentSeed = const Color(0xFF1976D2);

  // UX/Accessibility
  bool _reduceMotion = false;
  bool _compactUi = false;
  double _textScale = 1.0;
  bool _haptics = true;

  // RGB Pulse runtime
  Color _rgbSeed = const Color(0xFF22C55E);
  Timer? _rgbTimer;

  // -----------------------------
  // Getters
  // -----------------------------
  Locale? get locale => _locale;

  ThemeMode get themeMode => _themeMode;
  AppThemeStyle get themeStyle => _themeStyle;

  Color get accentSeed => _accentSeed;

  bool get reduceMotion => _reduceMotion;
  bool get compactUi => _compactUi;
  double get textScale => _textScale;
  bool get haptics => _haptics;

  // For Settings UI (shown only when RGB Pulse)
  Color get rgbSeed => _rgbSeed;

  // Used by AppTheme.build()
  Color get effectiveSeed =>
      (_themeStyle == AppThemeStyle.rgbPulse) ? _rgbSeed : _accentSeed;

  // -----------------------------
  // Lifecycle
  // -----------------------------
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    final code = sp.getString(_kLocale);
    _locale = (code == null || code.isEmpty) ? null : Locale(code);

    final theme = sp.getString(_kThemeMode);
    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final style = sp.getString(_kThemeStyle);
    _themeStyle = switch (style) {
      'neon' => AppThemeStyle.neon,
      'rgb' => AppThemeStyle.rgbPulse,
      _ => AppThemeStyle.classic,
    };

    final accentInt = sp.getInt(_kAccentSeed);
    if (accentInt != null) _accentSeed = Color(accentInt);

    _reduceMotion = sp.getBool(_kReduceMotion) ?? false;
    _compactUi = sp.getBool(_kCompactUi) ?? false;
    _textScale = sp.getDouble(_kTextScale) ?? 1.0;
    _haptics = sp.getBool(_kHaptics) ?? true;

    _syncRgbPulse();
    notifyListeners();
  }

  @override
  void dispose() {
    _rgbTimer?.cancel();
    super.dispose();
  }

  // -----------------------------
  // Setters (persist + notify)
  // -----------------------------
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final sp = await SharedPreferences.getInstance();
    if (locale == null) {
      await sp.remove(_kLocale);
    } else {
      await sp.setString(_kLocale, locale.languageCode);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final sp = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await sp.setString(_kThemeMode, v);
    notifyListeners();
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    _themeStyle = style;
    final sp = await SharedPreferences.getInstance();
    final v = switch (style) {
      AppThemeStyle.neon => 'neon',
      AppThemeStyle.rgbPulse => 'rgb',
      _ => 'classic',
    };
    await sp.setString(_kThemeStyle, v);

    _syncRgbPulse();
    notifyListeners();
  }

  Future<void> setAccentSeed(Color color) async {
    _accentSeed = color;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kAccentSeed, color.value);

    // إذا كان RGB Pulse فعّال، لا نوقفه… فقط نخزن الـ accent للاستخدام لاحقاً
    notifyListeners();
  }

  Future<void> setReduceMotion(bool v) async {
    _reduceMotion = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kReduceMotion, v);

    _syncRgbPulse();
    notifyListeners();
  }

  Future<void> setCompactUi(bool v) async {
    _compactUi = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kCompactUi, v);
    notifyListeners();
  }

  Future<void> setTextScale(double v) async {
    _textScale = v.clamp(0.85, 1.35);
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kTextScale, _textScale);
    notifyListeners();
  }

  Future<void> setHaptics(bool v) async {
    _haptics = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kHaptics, v);
    notifyListeners();
  }

  // -----------------------------
  // RGB Pulse engine
  // -----------------------------
  void _syncRgbPulse() {
    _rgbTimer?.cancel();
    _rgbTimer = null;

    final shouldRun =
        _themeStyle == AppThemeStyle.rgbPulse && _reduceMotion == false;

    if (!shouldRun) return;

    // Start immediately
    _rgbSeed = _computeRgbSeed(DateTime.now().millisecondsSinceEpoch);

    // Gentle update rate (performance friendly)
    _rgbTimer = Timer.periodic(const Duration(milliseconds: 280), (_) {
      _rgbSeed = _computeRgbSeed(DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
    });
  }

  Color _computeRgbSeed(int ms) {
    // Hue cycles smoothly; keep saturation/value friendly for medical UI
    final t = ms / 1000.0;
    final hue = (t * 36.0) % 360.0; // ~10s per full cycle
    return HSVColor.fromAHSV(1.0, hue, 0.72, 0.92).toColor();
  }
}
