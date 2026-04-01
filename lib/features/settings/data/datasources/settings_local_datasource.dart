import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';

abstract class SettingsLocalDataSource {
  String? getThemeMode();
  Future<void> setThemeMode(String mode);
  String? getLocale();
  Future<void> setLocale(String locale);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  @override
  String? getThemeMode() {
    final box = Hive.box(AppConstants.settingsBox);
    final response = box.get(AppConstants.themeKey) as String?;
    return response;
  }

  @override
  Future<void> setThemeMode(String mode) async {
    final box = Hive.box(AppConstants.settingsBox);
    final response = await box.put(AppConstants.themeKey, mode);
    return response;
  }

  @override
  String? getLocale() {
    final box = Hive.box(AppConstants.settingsBox);
    final response = box.get(AppConstants.localeKey) as String?;
    return response;
  }

  @override
  Future<void> setLocale(String locale) async {
    final box = Hive.box(AppConstants.settingsBox);
    final response = await box.put(AppConstants.localeKey, locale);
    return response;
  }
}
