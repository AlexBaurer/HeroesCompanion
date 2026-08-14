import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/domain/game_record.dart';
import 'package:heroescompanion/domain/game_record_codec.dart';
import 'package:heroescompanion/features/scores/data/game_record_migration.dart';
import 'package:heroescompanion/features/scores/data/game_record_storage.dart';

import '../../../helpers/fake_preferences.dart';
import '../../../helpers/v1_records.dart';

const _codec = GameRecordCodec();

GameRecord _v1Record() => _codec.decode(v1RecordSource);

void main() {
  late FakePreferences prefs;
  late GameRecordMigration migration;

  setUp(() {
    prefs = FakePreferences();
    migration = GameRecordMigration(preferences: prefs);
  });

  group('первый запуск: перенос записей v1', () {
    test('данные v1 переносятся и читаются хранилищем', () async {
      prefs.strings[GameRecordStorage.recordsKey] = [v1RecordSource];

      await migration.migrateIfNeeded();

      final records = await GameRecordStorage(preferences: prefs).loadAll();
      expect(records, hasLength(1));
      expect(records.single.toJson(), _v1Record().toJson());
    });

    test('после миграции ставится флаг «миграция выполнена»', () async {
      prefs.strings[GameRecordStorage.recordsKey] = [v1RecordSource];

      await migration.migrateIfNeeded();

      expect(prefs.flags[GameRecordMigration.migratedKey], isTrue);
    });

    test('записи сохраняются обратно в формате v1 байт-в-байт', () async {
      prefs.strings[GameRecordStorage.recordsKey] = [v1RecordSource];

      await migration.migrateIfNeeded();

      expect(prefs.strings[GameRecordStorage.recordsKey], [v1RecordSource]);
    });

    test('битые записи v1 пропускаются, валидные переносятся', () async {
      prefs.strings[GameRecordStorage.recordsKey] = ['не json', v1RecordSource];

      await migration.migrateIfNeeded();

      final records = await GameRecordStorage(preferences: prefs).loadAll();
      expect(records, hasLength(1));
      expect(records.single.toJson(), _v1Record().toJson());
    });

    test('отсутствие данных v1 не ломает первый запуск', () async {
      await migration.migrateIfNeeded();

      expect(prefs.flags[GameRecordMigration.migratedKey], isTrue);
      expect(await GameRecordStorage(preferences: prefs).loadAll(), isEmpty);
      expect(
        prefs.strings.containsKey(GameRecordStorage.recordsKey),
        isFalse,
      );
    });
  });

  group('повторный запуск: миграция не дублирует записи', () {
    test('при установленном флаге миграция не запускается', () async {
      prefs.strings[GameRecordStorage.recordsKey] = [v1RecordSource];
      await migration.migrateIfNeeded();

      // Новая запись v2 добавляется в тот же ключ и формат.
      final storage = GameRecordStorage(preferences: prefs);
      await storage.add(
        GameRecord(
          dateTime: DateTime(2026, 9, 1),
          playerScores: const [
            PlayerScore(playerName: 'Аня', score: 10, faction: 'Гномы'),
          ],
        ),
      );
      final before = await storage.loadAll();

      await migration.migrateIfNeeded();

      final after = await storage.loadAll();
      expect(after, hasLength(2));
      expect(
        after.map((record) => record.toJson()).toList(),
        before.map((record) => record.toJson()).toList(),
      );
    });

    test('даже без флага повторный прогон преобразования идемпотентен', () async {
      prefs.strings[GameRecordStorage.recordsKey] = [v1RecordSource];
      await migration.migrateIfNeeded();

      // Имитация сбоя между записью данных и установкой флага.
      prefs.flags.remove(GameRecordMigration.migratedKey);
      await migration.migrateIfNeeded();

      expect(
        await GameRecordStorage(preferences: prefs).loadAll(),
        hasLength(1),
      );
      expect(prefs.strings[GameRecordStorage.recordsKey], hasLength(1));
    });
  });
}
