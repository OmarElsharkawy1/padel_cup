import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/settings_local_datasource.dart';

final settingsDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSourceImpl(),
);

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final ds = ref.read(settingsDataSourceProvider);
  return ThemeModeNotifier(ds);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsLocalDataSource _dataSource;

  ThemeModeNotifier(this._dataSource) : super(ThemeMode.system) {
    _load();
  }

  void _load() {
    final saved = _dataSource.getThemeMode();
    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _dataSource.setThemeMode(mode.name);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final ds = ref.read(settingsDataSourceProvider);
  return LocaleNotifier(ds);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SettingsLocalDataSource _dataSource;

  LocaleNotifier(this._dataSource) : super(const Locale('en')) {
    _load();
  }

  void _load() {
    final saved = _dataSource.getLocale();
    if (saved != null) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _dataSource.setLocale(locale.languageCode);
  }
}
