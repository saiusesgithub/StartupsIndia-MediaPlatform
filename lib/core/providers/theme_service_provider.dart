import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDarkMode = 'isDarkMode';

class ThemeServiceNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_kDarkMode) ?? true;
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    return ThemeMode.dark;
  }

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> setDarkMode(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, isDark);
  }

  Future<void> toggle() => setDarkMode(state != ThemeMode.dark);
}

final themeServiceProvider = NotifierProvider<ThemeServiceNotifier, ThemeMode>(
  ThemeServiceNotifier.new,
);
