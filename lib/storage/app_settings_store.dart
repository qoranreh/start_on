import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.notificationsEnabled,
    required this.vibrationEnabled,
    required this.celebrationEffectEnabled,
    required this.autoSaveEnabled,
    required this.notionSyncEnabled,
    required this.notionApiToken,
    required this.notionDatabaseId,
    required this.notionDatabaseTitle,
  });

  final bool notificationsEnabled;
  final bool vibrationEnabled;
  final bool celebrationEffectEnabled;
  final bool autoSaveEnabled;
  final bool notionSyncEnabled;
  final String notionApiToken;
  final String notionDatabaseId;
  final String notionDatabaseTitle;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? vibrationEnabled,
    bool? celebrationEffectEnabled,
    bool? autoSaveEnabled,
    bool? notionSyncEnabled,
    String? notionApiToken,
    String? notionDatabaseId,
    String? notionDatabaseTitle,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      celebrationEffectEnabled:
          celebrationEffectEnabled ?? this.celebrationEffectEnabled,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      notionSyncEnabled: notionSyncEnabled ?? this.notionSyncEnabled,
      notionApiToken: notionApiToken ?? this.notionApiToken,
      notionDatabaseId: notionDatabaseId ?? this.notionDatabaseId,
      notionDatabaseTitle: notionDatabaseTitle ?? this.notionDatabaseTitle,
    );
  }
}

class AppSettingsStore {
  const AppSettingsStore();

  static const _notificationsEnabledKey = 'settings.notifications_enabled';
  static const _vibrationEnabledKey = 'settings.vibration_enabled';
  static const _celebrationEffectEnabledKey =
      'settings.celebration_effect_enabled';
  static const _autoSaveEnabledKey = 'settings.auto_save_enabled';
  static const _notionSyncEnabledKey = 'settings.notion_sync_enabled';
  static const _notionApiTokenKey = 'settings.notion_api_token';
  static const _notionDatabaseIdKey = 'settings.notion_database_id';
  static const _notionDatabaseTitleKey = 'settings.notion_database_title';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? true,
      vibrationEnabled: prefs.getBool(_vibrationEnabledKey) ?? true,
      celebrationEffectEnabled:
          prefs.getBool(_celebrationEffectEnabledKey) ?? true,
      autoSaveEnabled: prefs.getBool(_autoSaveEnabledKey) ?? true,
      notionSyncEnabled: prefs.getBool(_notionSyncEnabledKey) ?? false,
      notionApiToken: prefs.getString(_notionApiTokenKey) ?? '',
      notionDatabaseId: prefs.getString(_notionDatabaseIdKey) ?? '',
      notionDatabaseTitle: prefs.getString(_notionDatabaseTitleKey) ?? '',
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _notificationsEnabledKey,
      settings.notificationsEnabled,
    );
    await prefs.setBool(_vibrationEnabledKey, settings.vibrationEnabled);
    await prefs.setBool(
      _celebrationEffectEnabledKey,
      settings.celebrationEffectEnabled,
    );
    await prefs.setBool(_autoSaveEnabledKey, settings.autoSaveEnabled);
    await prefs.setBool(_notionSyncEnabledKey, settings.notionSyncEnabled);
    await prefs.setString(_notionApiTokenKey, settings.notionApiToken);
    await prefs.setString(_notionDatabaseIdKey, settings.notionDatabaseId);
    await prefs.setString(
      _notionDatabaseTitleKey,
      settings.notionDatabaseTitle,
    );
  }
}
