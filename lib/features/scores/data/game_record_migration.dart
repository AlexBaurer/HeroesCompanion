import 'package:heroescompanion/domain/game_record_codec.dart';

import 'game_record_storage.dart';

/// Миграция записей v1 при первой партии (тикет 10): при первом запуске v2
/// на устройстве с установленной v1 читает ключ `score_records` из
/// shared_preferences (формат v1, тот же applicationId — ADR-0002),
/// преобразует записи через кодек ([GameRecordCodec.decodeAll]) и
/// сохраняет обратно в том же ключе и формате v1, после чего ставит флаг
/// «миграция выполнена» — повторно миграция не запускается.
///
/// Формат хранения v2 совпадает с v1 (ADR-0002), поэтому миграция не меняет
/// данные, а нормализует их (пропускает записи, нечитаемые даже v1) и
/// отмечает завершение; идемпотентна — повторный прогон не дублирует записи.
class GameRecordMigration {
  const GameRecordMigration({required this.preferences});

  /// Ключ флага «миграция v1 выполнена» в shared_preferences.
  static const migratedKey = 'score_records_migrated';

  final Preferences preferences;

  static const _codec = GameRecordCodec();

  /// Выполняет миграцию, если она ещё не выполнялась; иначе — no-op.
  Future<void> migrateIfNeeded() async {
    final alreadyMigrated = await preferences.getBool(migratedKey) ?? false;
    if (alreadyMigrated) return;

    final sources = await preferences.getStringList(
      GameRecordStorage.recordsKey,
    );
    if (sources != null) {
      await preferences.setStringList(
        GameRecordStorage.recordsKey,
        _codec.encodeAll(_codec.decodeAll(sources)),
      );
    }
    await preferences.setBool(migratedKey, true);
  }
}
