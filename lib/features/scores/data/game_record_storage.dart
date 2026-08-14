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

/// Запись истории вместе с её позицией в списке [GameRecordStorage.loadAll]
/// (среди читаемых записей). Позиция — то, что ждёт
/// [GameRecordStorage.removeAt]: стабильна, пока хранилище не меняется,
/// и не совпадает с позицией карточки на экране (история сортируется).
class StoredGameRecord {
  const StoredGameRecord({required this.index, required this.record});

  final int index;
  final GameRecord record;
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

  /// Все записи истории: читаются как в v1 (битые строки пропускаются),
  /// каждая — с позицией в списке для [removeAt]. Позиция считается
  /// среди читаемых записей, как в [removeAt].
  Future<List<StoredGameRecord>> loadAll() async {
    final sources = await _readSources();
    final entries = <StoredGameRecord>[];
    for (final (_, record) in _readableEntries(sources)) {
      entries.add(StoredGameRecord(index: entries.length, record: record));
    }
    return entries;
  }

  /// Удаляет запись по позиции в списке [loadAll] (среди читаемых записей;
  /// битые строки не трогает и не считает). Бросает [RangeError],
  /// если позиции нет.
  Future<void> removeAt(int index) async {
    if (index < 0) {
      throw RangeError.range(index, 0, null, 'index');
    }
    final sources = await _readSources();
    final entries = _readableEntries(sources);
    if (index >= entries.length) {
      throw RangeError.range(index, 0, entries.length - 1, 'index');
    }
    final removedSourceIndex = entries[index].$1;
    final kept = [
      for (var i = 0; i < sources.length; i++)
        if (i != removedSourceIndex) sources[i],
    ];
    if (kept.isEmpty) {
      // Удалена последняя запись — история пустая, как после [clear].
      await preferences.remove(recordsKey);
    } else {
      await preferences.setStringList(recordsKey, kept);
    }
  }

  /// Удаляет всю историю (ключ `score_records`), как это делала v1.
  Future<void> clear() async {
    await preferences.remove(recordsKey);
  }

  /// Строки хранилища, читаемые кодеком (битые пропускаются, как в v1):
  /// каждая — сырой индекс строки в shared_preferences и разобранная
  /// запись. Единая точка, где запись считается читаемой, — и для
  /// [loadAll], и для [removeAt].
  List<(int, GameRecord)> _readableEntries(List<String> sources) {
    final entries = <(int, GameRecord)>[];
    for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
      try {
        entries.add((sourceIndex, _codec.decodeTolerant(sources[sourceIndex])));
      } on GameRecordParseException {
        // Запись нечитаема даже v1 — пропускается.
      }
    }
    return entries;
  }

  Future<List<String>> _readSources() async {
    // Копия: список из SharedPreferences кэшируется, мутировать нельзя.
    return [...?await preferences.getStringList(recordsKey)];
  }
}
