import 'package:heroescompanion/domain/game_record.dart';
import 'package:heroescompanion/domain/game_record_codec.dart';

/// Минимальный доступ к хранилищу ключ-значение (в проде —
/// shared_preferences): чтение, запись и удаление значений по ключу.
abstract interface class Preferences {
  Future<List<String>?> getStringList(String key);

  Future<void> setStringList(String key, List<String> value);

  Future<bool?> getBool(String key);

  Future<void> setBool(String key, bool value);

  Future<void> remove(String key);
}

/// Хранилище записей игр в shared_preferences: ключ `score_records`,
/// список JSON-строк в формате v1 (ADR-0002) — тот же формат, что писала
/// v1, чтобы история оставалась совместимой и читаемой.
///
/// Хранилище инжектируется ([Preferences]), чтобы код оставался
/// чистым Dart: в приложении — адаптер над SharedPreferences, в тестах —
/// фейк в памяти.
class GameRecordStorage {
  const GameRecordStorage({required this.preferences});

  /// Ключ истории в shared_preferences (совпадает с v1).
  static const recordsKey = 'score_records';

  final Preferences preferences;

  static const _codec = GameRecordCodec();

  /// Добавляет запись в конец истории в формате v1.
  Future<void> add(GameRecord record) async {
    final sources = await _readSources();
    sources.add(_codec.encode(record));
    await preferences.setStringList(recordsKey, sources);
  }

  /// Все записи истории: читаются как в v1 (битые строки пропускаются).
  Future<List<GameRecord>> loadAll() async {
    return _codec.decodeAll(await _readSources());
  }

  /// Удаляет всю историю (ключ `score_records`), как это делала v1.
  Future<void> clear() async {
    await preferences.remove(recordsKey);
  }

  Future<List<String>> _readSources() async {
    // Копия: список из SharedPreferences кэшируется, мутировать нельзя.
    return [...?await preferences.getStringList(recordsKey)];
  }
}
