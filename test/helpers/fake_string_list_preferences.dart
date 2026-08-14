import 'package:heroescompanion/features/scores/data/game_record_storage.dart';

/// Фейк [StringListPreferences] в памяти: хранит значения по ключам,
/// чтобы тест мог проверить, что именно было записано в формате v1.
class FakeStringListPreferences implements StringListPreferences {
  final Map<String, List<String>> store = {};

  @override
  Future<List<String>?> getStringList(String key) async => store[key];

  @override
  Future<void> setStringList(String key, List<String> value) async {
    store[key] = List.of(value);
  }

  @override
  Future<void> remove(String key) async {
    store.remove(key);
  }
}
