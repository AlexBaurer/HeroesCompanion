import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_record_storage.dart';

/// Адаптер [StringListPreferences] поверх shared_preferences.
class SharedPreferencesStringListAdapter implements StringListPreferences {
  const SharedPreferencesStringListAdapter({required this.instance});

  final SharedPreferences instance;

  @override
  Future<List<String>?> getStringList(String key) async {
    return instance.getStringList(key);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await instance.setStringList(key, value);
  }
}

/// Хранилище записей игр: пишет и читает историю в формате v1
/// (ключ `score_records`, ADR-0002).
final gameRecordStorageProvider = FutureProvider<GameRecordStorage>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return GameRecordStorage(
    preferences: SharedPreferencesStringListAdapter(instance: prefs),
  );
});
