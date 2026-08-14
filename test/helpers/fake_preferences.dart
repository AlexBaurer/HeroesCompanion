import 'package:heroescompanion/features/scores/data/game_record_storage.dart';

/// Фейк [Preferences] в памяти: хранит значения по ключам, чтобы тест мог
/// проверить, что именно было записано (списки строк и булевы флаги).
class FakePreferences implements Preferences {
  /// Списки строк по ключам (например, `score_records`).
  final Map<String, List<String>> strings = {};

  /// Булевы флаги по ключам (например, флаг миграции v1).
  final Map<String, bool> flags = {};

  @override
  Future<List<String>?> getStringList(String key) async => strings[key];

  @override
  Future<void> setStringList(String key, List<String> value) async {
    strings[key] = List.of(value);
  }

  @override
  Future<bool?> getBool(String key) async => flags[key];

  @override
  Future<void> setBool(String key, bool value) async {
    flags[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    strings.remove(key);
    flags.remove(key);
  }
}
