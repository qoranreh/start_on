import 'dart:convert';

import 'package:start_on/models/app_local_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataStore {
  const LocalDataStore();

  static const _storageKey = 'ad_focus.local_data';

  Future<AppLocalData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return AppLocalData.initial();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppLocalData.fromJson(decoded);
    } catch (_) {
      return AppLocalData.initial();
    }
  }

  Future<void> save(AppLocalData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data.toJson()));
  }
}
