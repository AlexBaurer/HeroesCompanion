import 'dart:convert';

import 'game_record.dart';

sealed class GameRecordParseException implements Exception {
  const GameRecordParseException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Строка не является валидным JSON-объектом записи.
final class GameRecordSyntaxException extends GameRecordParseException {
  const GameRecordSyntaxException(super.message);
}

/// Поле записи отсутствует, имеет неверный тип или недопустимое значение.
final class GameRecordInvalidValueException extends GameRecordParseException {
  GameRecordInvalidValueException({
    required this.field,
    required this.path,
    required String reason,
    this.value,
  }) : super('поле "$field" (путь: $path): $reason; получено: $value');

  final String field;
  final String path;
  final Object? value;
}

/// Кодек записей игр в формате v1 (ADR-0002): строгий разбор одиночных
/// записей и пакетное преобразование списка строк из `shared_preferences`
/// (`score_records`) с толерантностью v1.
///
/// Разбор намеренно шире сериализации: неизвестные поля игнорируются,
/// дата принимается в любом формате, который понимает `DateTime.parse`.
/// Миграция ([decodeAll]) читает записи так же, как это делала v1:
/// отсутствующие поля игроков подставляются значениями по умолчанию,
/// пропускаются только записи, нечитаемые даже v1.
class GameRecordCodec {
  const GameRecordCodec();

  /// JSON-строка записи в формате v1.
  String encode(GameRecord record) => jsonEncode(record.toJson());

  /// JSON-строки записей в формате v1 — представление `score_records`.
  List<String> encodeAll(List<GameRecord> records) => [
    for (final record in records) encode(record),
  ];

  /// Разбирает одну JSON-строку в запись.
  /// Бросает [GameRecordParseException], если строка битая.
  GameRecord decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw GameRecordSyntaxException('некорректный JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const GameRecordSyntaxException('запись должна быть JSON-объектом');
    }
    return decodeMap(decoded);
  }

  /// Разбирает запись из JSON-объекта. Бросает [GameRecordParseException],
  /// если объект не описывает валидную запись.
  GameRecord decodeMap(Map<String, dynamic> json) {
    final dateTime = _readDateTime(json);
    final playerScores = _readPlayerScores(json);
    return GameRecord(dateTime: dateTime, playerScores: playerScores);
  }

  /// Преобразование v1 → v2: разбирает список JSON-строк формата v1
  /// (ключ `score_records`) в записи. Пропускаются только записи,
  /// нечитаемые даже v1; отсутствующие поля игроков подставляются
  /// значениями по умолчанию (как читала их v1), а не отбрасываются.
  /// Чистое преобразование: повторный прогон по уже преобразованным
  /// данным не дублирует записи.
  List<GameRecord> decodeAll(List<String> sources) {
    final records = <GameRecord>[];
    for (final source in sources) {
      try {
        records.add(decodeTolerant(source));
      } on GameRecordParseException {
        // Запись нечитаема даже v1 — пропускается.
      }
    }
    return records;
  }

  /// Разбирает запись так, как читала её v1: отсутствующие или нулевые
  /// значения полей игрока заменяются значениями по умолчанию
  /// (пустая строка, 0), а не считаются ошибкой. Бросает
  /// [GameRecordParseException], только если запись нечитаема даже v1.
  GameRecord decodeTolerant(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw GameRecordSyntaxException('некорректный JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const GameRecordSyntaxException('запись должна быть JSON-объектом');
    }
    return decodeMapTolerant(decoded);
  }

  /// Разбирает запись из JSON-объекта в режиме v1.
  GameRecord decodeMapTolerant(Map<String, dynamic> json) {
    final dateTime = _readDateTime(json);
    final raw = json['playerScores'];
    if (raw == null) {
      // v1: `as List? ?? []` — запись без игроков; представить её
      // в v2 нельзя (запись должна содержать 1–4 игроков) — пропуск.
      throw const GameRecordInvalidValueException(
        field: 'playerScores',
        path: 'запись',
        reason: 'должно быть от 1 до 4 игроков',
      );
    }
    if (raw is! List) {
      throw GameRecordInvalidValueException(
        field: 'playerScores',
        path: 'запись',
        reason: 'должно быть списком результатов игроков',
        value: raw,
      );
    }
    if (raw.isEmpty || raw.length > GameRecord.maxPlayers) {
      throw GameRecordInvalidValueException(
        field: 'playerScores',
        path: 'запись',
        reason:
            'должно быть от ${GameRecord.minPlayers} до '
            '${GameRecord.maxPlayers} игроков',
        value: raw,
      );
    }
    final players = [
      for (var i = 0; i < raw.length; i++)
        _readPlayerScoreTolerant(raw[i], 'запись.playerScores[$i]'),
    ];
    return GameRecord(dateTime: dateTime, playerScores: players);
  }

  PlayerScore _readPlayerScoreTolerant(Object? raw, String path) {
    if (raw is! Map<String, dynamic>) {
      throw GameRecordInvalidValueException(
        field: 'playerScores',
        path: path,
        reason: 'элемент должен быть объектом с результатами игрока',
        value: raw,
      );
    }
    return PlayerScore(
      playerName: _readStringOrEmpty(raw, 'playerName', path),
      score: _readIntOrZero(raw, 'score', path),
      faction: _readStringOrEmpty(raw, 'faction', path),
    );
  }

  String _readStringOrEmpty(
    Map<String, dynamic> json,
    String field,
    String path,
  ) {
    final value = json[field];
    if (value == null) return '';
    if (value is String) return value;
    throw GameRecordInvalidValueException(
      field: field,
      path: path,
      reason: 'должно быть строкой',
      value: value,
    );
  }

  int _readIntOrZero(Map<String, dynamic> json, String field, String path) {
    final value = json[field];
    if (value == null) return 0;
    if (value is int) return value;
    throw GameRecordInvalidValueException(
      field: field,
      path: path,
      reason: 'должно быть целым числом',
      value: value,
    );
  }

  DateTime _readDateTime(Map<String, dynamic> json) {
    _requireField(json, 'dateTime');
    final value = json['dateTime'];
    if (value is! String) {
      throw GameRecordInvalidValueException(
        field: 'dateTime',
        path: 'запись',
        reason: 'должно быть строкой в формате ISO-8601',
        value: value,
      );
    }
    final dateTime = DateTime.tryParse(value);
    if (dateTime == null) {
      throw GameRecordInvalidValueException(
        field: 'dateTime',
        path: 'запись',
        reason: 'не разбирается как дата',
        value: value,
      );
    }
    return dateTime;
  }

  List<PlayerScore> _readPlayerScores(Map<String, dynamic> json) {
    _requireField(json, 'playerScores');
    final raw = json['playerScores'];
    if (raw is! List) {
      throw GameRecordInvalidValueException(
        field: 'playerScores',
        path: 'запись',
        reason: 'должно быть списком результатов игроков',
        value: raw,
      );
    }
    if (raw.isEmpty || raw.length > GameRecord.maxPlayers) {
      throw GameRecordInvalidValueException(
        field: 'playerScores',
        path: 'запись',
        reason:
            'должно быть от ${GameRecord.minPlayers} до '
            '${GameRecord.maxPlayers} игроков',
        value: raw,
      );
    }
    return [
      for (var i = 0; i < raw.length; i++)
        _readPlayerScore(raw[i], 'запись.playerScores[$i]'),
    ];
  }

  PlayerScore _readPlayerScore(Object? raw, String path) {
    if (raw is! Map<String, dynamic>) {
      throw GameRecordInvalidValueException(
        field: 'playerScores',
        path: path,
        reason: 'элемент должен быть объектом с результатами игрока',
        value: raw,
      );
    }
    return PlayerScore(
      playerName: _readNonEmptyString(raw, 'playerName', path),
      score: _readInt(raw, 'score', path),
      faction: _readNonEmptyString(raw, 'faction', path),
    );
  }

  String _readNonEmptyString(
    Map<String, dynamic> json,
    String field,
    String path,
  ) {
    _requireField(json, field, path: path);
    final value = json[field];
    if (value is! String || value.isEmpty) {
      throw GameRecordInvalidValueException(
        field: field,
        path: path,
        reason: 'должно быть непустой строкой',
        value: value,
      );
    }
    return value;
  }

  int _readInt(Map<String, dynamic> json, String field, String path) {
    _requireField(json, field, path: path);
    final value = json[field];
    if (value is! int) {
      throw GameRecordInvalidValueException(
        field: field,
        path: path,
        reason: 'должно быть целым числом',
        value: value,
      );
    }
    return value;
  }

  void _requireField(Map<String, dynamic> json, String field, {String? path}) {
    if (!json.containsKey(field)) {
      throw GameRecordInvalidValueException(
        field: field,
        path: path ?? 'запись',
        reason: 'отсутствует обязательное поле',
      );
    }
  }
}
