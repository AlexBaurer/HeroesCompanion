import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/domain/game_record.dart';
import 'package:heroescompanion/domain/game_record_codec.dart';
import 'package:heroescompanion/features/scores/data/game_record_storage.dart';

import '../../../helpers/fake_string_list_preferences.dart';

const _codec = GameRecordCodec();

PlayerScore _player(String name, int score, String faction) =>
    PlayerScore(playerName: name, score: score, faction: faction);

GameRecord _record({DateTime? dateTime, List<PlayerScore>? players}) {
  return GameRecord(
    dateTime: dateTime ?? DateTime(2026, 8, 12, 18, 30),
    playerScores: players ?? [_player('Иван', 42, 'Майя')],
  );
}

void main() {
  late FakeStringListPreferences prefs;
  late GameRecordStorage storage;

  setUp(() {
    prefs = FakeStringListPreferences();
    storage = GameRecordStorage(preferences: prefs);
  });

  group('add: запись в формате v1 по ключу score_records', () {
    test('пишет JSON-строку формата v1', () async {
      await storage.add(_record());

      final stored = prefs.store[GameRecordStorage.recordsKey];
      expect(stored, hasLength(1));
      expect(_codec.decode(stored!.single).toJson(), _record().toJson());
    });

    test('дополняет существующие записи, не затирая их', () async {
      final first = _record();
      final second = _record(
        dateTime: DateTime(2026, 7, 1),
        players: [_player('Аня', 10, 'Гномы'), _player('Боря', 8, 'Эльфы')],
      );
      await storage.add(first);
      await storage.add(second);

      final stored = prefs.store[GameRecordStorage.recordsKey]!;
      expect(stored, hasLength(2));
      expect(_codec.decode(stored[0]).toJson(), first.toJson());
      expect(_codec.decode(stored[1]).toJson(), second.toJson());
    });

    test('записывает байт-в-байт строку формата v1', () async {
      await storage.add(_record());

      final stored = prefs.store[GameRecordStorage.recordsKey]!.single;
      const expected =
          '{"dateTime":"2026-08-12T18:30:00.000","playerScores":'
          '[{"playerName":"Иван","score":42,"faction":"Майя"}]}';
      expect(stored, expected);
    });
  });

  group('loadAll: чтение истории', () {
    test('round-trip: добавленное читается как запись', () async {
      final record = _record(
        players: [_player('Иван', 42, 'Майя'), _player('Пётр', 35, 'Наги')],
      );
      await storage.add(record);

      final loaded = await storage.loadAll();

      expect(loaded, hasLength(1));
      expect(loaded.single.toJson(), record.toJson());
    });

    test('сохраняет порядок записей', () async {
      await storage.add(_record());
      await storage.add(_record(dateTime: DateTime(2026, 7, 1)));

      final loaded = await storage.loadAll();

      expect(loaded.map((record) => record.dateTime).toList(), [
        DateTime(2026, 8, 12, 18, 30),
        DateTime(2026, 7, 1),
      ]);
    });

    test('отсутствующий ключ — пустая история', () async {
      expect(await storage.loadAll(), isEmpty);
    });

    test('битые строки пропускаются, валидные читаются', () async {
      await storage.add(_record());
      prefs.store[GameRecordStorage.recordsKey]!.insert(0, 'не json');

      final loaded = await storage.loadAll();

      expect(loaded, hasLength(1));
      expect(loaded.single.playerScores.single.playerName, 'Иван');
    });
  });
}
