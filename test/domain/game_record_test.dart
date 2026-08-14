import 'package:flutter_test/flutter_test.dart';
import 'package:heroescompanion/domain/game_record.dart';
import 'package:heroescompanion/domain/game_record_codec.dart';

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
  group('GameRecord: 1–4 игрока', () {
    test('0 игроков → ArgumentError', () {
      expect(
        () => GameRecord(dateTime: DateTime.now(), playerScores: const []),
        throwsArgumentError,
      );
    });

    test('5 игроков → ArgumentError', () {
      final players = [
        for (var i = 0; i < 5; i++) _player('Игрок $i', i, 'Майя'),
      ];
      expect(
        () => GameRecord(dateTime: DateTime.now(), playerScores: players),
        throwsArgumentError,
      );
    });

    test('1 и 4 игрока принимаются', () {
      expect(_record().playerScores, hasLength(1));

      final four = [for (var i = 0; i < 4; i++) _player('Игрок $i', i, 'Майя')];
      final record = GameRecord(dateTime: DateTime.now(), playerScores: four);
      expect(record.playerScores, hasLength(4));
    });
  });

  group('totalScore: сумма очков игроков', () {
    test('суммирует очки всех игроков', () {
      final record = _record(
        players: [_player('Иван', 42, 'Майя'), _player('Пётр', 35, 'Наги')],
      );

      expect(record.totalScore, 77);
    });

    test('один игрок — его очки', () {
      expect(_record().totalScore, 42);
    });

    test('нулевые и отрицательные очки учитываются', () {
      final record = _record(
        players: [_player('Аня', 0, 'Майя'), _player('Боря', -3, 'Наги')],
      );

      expect(record.totalScore, -3);
    });
  });

  group('round-trip: запись → JSON → запись', () {
    test('одна запись с несколькими игроками идентична', () {
      final record = _record(
        dateTime: DateTime(2026, 1, 2, 3, 4, 5, 123),
        players: [_player('Иван', 42, 'Майя'), _player('Пётр', 35, 'Наги')],
      );

      final decoded = _codec.decode(_codec.encode(record));

      expect(decoded.toJson(), record.toJson());
      expect(decoded.dateTime, record.dateTime);
      expect(decoded.playerScores, hasLength(2));
      expect(decoded.playerScores[0].playerName, 'Иван');
      expect(decoded.playerScores[0].score, 42);
      expect(decoded.playerScores[0].faction, 'Майя');
      expect(decoded.playerScores[1].playerName, 'Пётр');
      expect(decoded.playerScores[1].score, 35);
      expect(decoded.playerScores[1].faction, 'Наги');
    });

    test('дата сохраняет признак UTC', () {
      final record = _record(
        dateTime: DateTime.utc(2026, 8, 12, 18, 30),
        players: [_player('Иван', 42, 'Майя')],
      );

      final decoded = _codec.decode(_codec.encode(record));

      expect(decoded.dateTime.isUtc, isTrue);
      expect(decoded.dateTime, DateTime.utc(2026, 8, 12, 18, 30));
    });

    test('список записей → список JSON-строк → тот же список', () {
      final records = [
        _record(),
        _record(
          dateTime: DateTime(2026, 7, 1),
          players: [_player('Аня', 10, 'Гномы'), _player('Боря', 8, 'Эльфы')],
        ),
      ];

      final decoded = _codec.decodeAll(_codec.encodeAll(records));

      expect(
        decoded.map((record) => record.toJson()).toList(),
        records.map((record) => record.toJson()).toList(),
      );
    });
  });

  group('JSON-формат совпадает с v1', () {
    test('ключи: dateTime и playerScores с playerName/score/faction', () {
      final encoded = _codec.encode(_record());

      expect(encoded, contains('"dateTime":'));
      expect(encoded, contains('"playerScores":'));
      expect(encoded, contains('"playerName":'));
      expect(encoded, contains('"score":'));
      expect(encoded, contains('"faction":'));
    });

    test('запись сериализуется в формат v1', () {
      final record = _record(
        dateTime: DateTime(2026, 8, 12, 18, 30),
        players: [_player('Иван', 42, 'Майя'), _player('Пётр', 35, 'Наги')],
      );

      const expected =
          '{"dateTime":"2026-08-12T18:30:00.000","playerScores":'
          '[{"playerName":"Иван","score":42,"faction":"Майя"},'
          '{"playerName":"Пётр","score":35,"faction":"Наги"}]}';
      expect(_codec.encode(record), expected);
    });

    test('строка, написанная v1, читается как есть', () {
      // Точная строка, которую писал кодек v1 (score_record.dart v1:
      // dateTime.toIso8601String() + playerName/score/faction).
      const v1String =
          '{"dateTime":"2024-03-15T14:22:07.123","playerScores":'
          '[{"playerName":"Саша","score":47,"faction":"Гномы"}]}';

      final record = _codec.decode(v1String);

      expect(record.dateTime, DateTime(2024, 3, 15, 14, 22, 7, 123));
      expect(record.playerScores.single.playerName, 'Саша');
      expect(record.playerScores.single.score, 47);
      expect(record.playerScores.single.faction, 'Гномы');
    });

    test('round-trip на пределе: 4 игрока', () {
      final record = _record(
        players: [
          _player('Игрок 1', 41, 'Майя'),
          _player('Игрок 2', 35, 'Наги'),
          _player('Игрок 3', 30, 'Гномы'),
          _player('Игрок 4', 28, 'Эльфы'),
        ],
      );

      expect(_codec.decode(_codec.encode(record)).toJson(), record.toJson());
    });
  });

  group('преобразование v1 → v2', () {
    test('валидные записи преобразуются все', () {
      final sources = [
        _codec.encode(_record()),
        _codec.encode(
          _record(
            dateTime: DateTime(2026, 7, 1),
            players: [
              _player('Аня', 10, 'Гномы'),
              _player('Боря', 8, 'Эльфы'),
              _player('Витя', 6, 'Орки'),
            ],
          ),
        ),
      ];

      final records = _codec.decodeAll(sources);

      expect(records, hasLength(2));
      expect(records[0].playerScores, hasLength(1));
      expect(records[1].playerScores, hasLength(3));
      expect(records[1].dateTime, DateTime(2026, 7, 1));
    });

    test('битые записи пропускаются, валидные и v1-терпимые сохраняются', () {
      final valid = _codec.encode(_record());
      final broken = [
        'не json',
        '[1, 2, 3]',
        'null',
        '{"dateTime": "2026-08-12T18:30:00.000"}',
        '{"playerScores": []}',
        '{"dateTime": "не-дата", "playerScores": [{"playerName": "Иван", "score": 5, "faction": "Майя"}]}',
        '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": [{"playerName": "Иван", "score": "пять", "faction": "Майя"}]}',
        '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": [{"playerName": "Иван", "score": 5, "faction": "Майя"}, {"playerName": "Пётр", "score": 5, "faction": "Наги"}, {"playerName": "Аня", "score": 5, "faction": "Гномы"}, {"playerName": "Боря", "score": 5, "faction": "Эльфы"}, {"playerName": "Витя", "score": 5, "faction": "Орки"}]}',
        '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": 42}',
      ];
      // Записи, которые читала v1 (пустое имя, отсутствующая фракция),
      // сохраняются со значениями по умолчанию.
      final v1Tolerant = [
        '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": [{"playerName": "", "score": 5, "faction": "Майя"}]}',
        '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": [{"playerName": "Иван", "score": 5}]}',
      ];

      final records = _codec.decodeAll([valid, ...broken, ...v1Tolerant]);

      expect(records, hasLength(3));
      expect(records[0].toJson(), _codec.decode(valid).toJson());
      expect(records[1].playerScores.single.playerName, '');
      expect(records[2].playerScores.single.faction, '');
    });

    test('отсутствующие поля игрока подставляются как в v1', () {
      const sources = [
        '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": [{"playerName": "Иван", "score": 5}]}',
        '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": [{"score": 7, "faction": "Гномы"}]}',
        '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": [{"playerName": "Пётр"}]}',
      ];

      final records = _codec.decodeAll(sources);

      expect(records, hasLength(3));
      expect(records[0].playerScores.single.faction, '');
      expect(records[1].playerScores.single.playerName, '');
      expect(records[1].playerScores.single.score, 7);
      expect(records[2].playerScores.single.score, 0);
      expect(records[2].playerScores.single.faction, '');
    });

    test('нулевые значения полей подставляются как в v1', () {
      const source =
          '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": '
          '[{"playerName": null, "score": null, "faction": null}]}';

      final record = _codec.decodeAll([source]).single;

      expect(record.playerScores.single.playerName, '');
      expect(record.playerScores.single.score, 0);
      expect(record.playerScores.single.faction, '');
    });

    test('строгий decode по-прежнему требует все поля', () {
      const v1TolerantOnly =
          '{"dateTime": "2026-08-12T18:30:00.000", "playerScores": '
          '[{"playerName": "Иван", "score": 5}]}';

      expect(
        () => _codec.decode(v1TolerantOnly),
        throwsA(isA<GameRecordParseException>()),
      );
      expect(
        _codec.decodeAll([v1TolerantOnly])
            .single
            .playerScores
            .single
            .faction,
        '',
      );
    });

    test('пустые данные → пустой список, без ошибок', () {
      expect(_codec.decodeAll(const []), isEmpty);
    });

    test('декодирование не падает на пустой строке JSON', () {
      expect(_codec.decodeAll(['']), isEmpty);
    });
  });

  group('идемпотентность преобразования', () {
    final sources = [
      _codec.encode(_record()),
      'не json',
      _codec.encode(
        _record(
          dateTime: DateTime(2026, 7, 1),
          players: [_player('Аня', 10, 'Гномы'), _player('Боря', 8, 'Эльфы')],
        ),
      ),
    ];

    test('повторный прогон по исходным данным не меняет результат', () {
      final once = _codec.decodeAll(sources);
      final twice = _codec.decodeAll(sources);

      expect(
        twice.map((record) => record.toJson()).toList(),
        once.map((record) => record.toJson()).toList(),
      );
      expect(twice, hasLength(once.length));
    });

    test('преобразование уже преобразованных данных не дублирует записи', () {
      final once = _codec.decodeAll(sources);

      final again = _codec.decodeAll(_codec.encodeAll(once));

      expect(
        again.map((record) => record.toJson()).toList(),
        once.map((record) => record.toJson()).toList(),
      );
      expect(again, hasLength(once.length));
    });

    test('пересохранение валидных данных v1 — байт-в-байт нормализация', () {
      final validSources = sources
          .where((source) => source != 'не json')
          .toList();

      expect(_codec.encodeAll(_codec.decodeAll(validSources)), validSources);
    });
  });
}
