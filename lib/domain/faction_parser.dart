import 'dart:convert';

import 'faction.dart';
import 'strength_modifier.dart';

sealed class FactionParseException implements Exception {
  const FactionParseException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class FactionSyntaxException extends FactionParseException {
  const FactionSyntaxException(super.message);
}

final class FactionUnknownFieldException extends FactionParseException {
  FactionUnknownFieldException({required this.field, required this.path})
      : super('неизвестное поле "$field" (путь: $path)');

  final String field;
  final String path;
}

final class FactionMissingFieldException extends FactionParseException {
  FactionMissingFieldException({required this.field, required this.path})
      : super('отсутствует обязательное поле "$field" (путь: $path)');

  final String field;
  final String path;
}

final class FactionInvalidValueException extends FactionParseException {
  FactionInvalidValueException({
    required this.field,
    required this.path,
    required String reason,
    this.value,
  }) : super('поле "$field" (путь: $path): $reason; получено: $value');

  final String field;
  final String path;
  final Object? value;
}

final class FactionDuplicateUnitIdException extends FactionParseException {
  const FactionDuplicateUnitIdException(this.unitId)
      : super('дублируется id юнита "$unitId"');

  final String unitId;
}

final class FactionUnknownUnitException extends FactionParseException {
  const FactionUnknownUnitException(this.unitId)
      : super('ссылается на неизвестного юнита "$unitId"');

  final String unitId;
}

final class FactionUnknownModifierTypeException extends FactionParseException {
  const FactionUnknownModifierTypeException(this.type)
      : super(
          'неизвестный тип модификатора "$type" (ожидаются toggle или counter)',
        );

  final String type;
}

class FactionParser {
  const FactionParser();

  static const _factionFields = {
    'name',
    'gamePart',
    'color',
    'background',
    'description',
    'resources',
    'units',
    'modifiers',
    'armyPower',
    'battleUpgrade',
  };
  static const _unitFields = {'id', 'name', 'power'};
  static const _modifierFields = {
    'unit',
    'type',
    'bonusPower',
    'step',
    'maxCount',
  };
  static const _battleUpgradeFields = {'resource', 'limit', 'powers'};

  Faction parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw FactionSyntaxException('некорректный JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FactionSyntaxException(
        'корневой элемент должен быть объектом с данными фракции',
      );
    }
    return parseMap(decoded);
  }

  Faction parseMap(Map<String, dynamic> json) {
    _rejectUnknownFields(json, _factionFields, 'фракция');

    final name = _readNonEmptyString(json, 'name', 'фракция');
    final gamePart = _readGamePart(json);
    final color = _readNonEmptyString(json, 'color', 'фракция');
    final background = _readNonEmptyString(json, 'background', 'фракция');
    final description = _readNonEmptyString(json, 'description', 'фракция');
    final resources = _readResources(json);
    final units = _readUnits(json);
    final modifiers = _readModifiers(json, units);
    final armyPower = _readArmyPower(json);
    final battleUpgrade = _readBattleUpgrade(json, units, resources);

    return Faction(
      name: name,
      gamePart: gamePart,
      color: color,
      backgroundPath: background,
      description: description,
      resources: resources,
      units: units,
      modifiers: modifiers,
      armyPowerFormula: armyPower,
      battleUpgrade: battleUpgrade,
    );
  }

  void _rejectUnknownFields(
    Map<String, dynamic> json,
    Set<String> allowed,
    String path,
  ) {
    for (final field in json.keys) {
      if (!allowed.contains(field)) {
        throw FactionUnknownFieldException(field: field, path: path);
      }
    }
  }

  void _requireField(Map<String, dynamic> json, String field, String path) {
    if (!json.containsKey(field)) {
      throw FactionMissingFieldException(field: field, path: path);
    }
  }

  String _readNonEmptyString(
    Map<String, dynamic> json,
    String field,
    String path,
  ) {
    _requireField(json, field, path);
    final value = json[field];
    if (value is! String || value.isEmpty) {
      throw FactionInvalidValueException(
        field: field,
        path: path,
        reason: 'должно быть непустой строкой',
        value: value,
      );
    }
    return value;
  }

  int _readGamePart(Map<String, dynamic> json) {
    _requireField(json, 'gamePart', 'фракция');
    final value = json['gamePart'];
    if (value is! int || value < 1 || value > 3) {
      throw FactionInvalidValueException(
        field: 'gamePart',
        path: 'фракция',
        reason: 'должно быть целым числом от 1 до 3',
        value: value,
      );
    }
    return value;
  }

  List<String> _readResources(Map<String, dynamic> json) {
    _requireField(json, 'resources', 'фракция');
    final raw = json['resources'];
    if (raw is! List) {
      throw FactionInvalidValueException(
        field: 'resources',
        path: 'фракция',
        reason: 'должен быть списком строк',
        value: raw,
      );
    }
    final resources = <String>[];
    for (var i = 0; i < raw.length; i++) {
      final value = raw[i];
      if (value is! String || value.isEmpty) {
        throw FactionInvalidValueException(
          field: 'resources',
          path: 'фракция.resources[$i]',
          reason: 'элемент должен быть непустой строкой',
          value: value,
        );
      }
      resources.add(value);
    }
    return resources;
  }

  List<Unit> _readUnits(Map<String, dynamic> json) {
    _requireField(json, 'units', 'фракция');
    final raw = json['units'];
    if (raw is! List || raw.isEmpty) {
      throw FactionInvalidValueException(
        field: 'units',
        path: 'фракция',
        reason: 'должен быть непустым списком юнитов',
        value: raw,
      );
    }
    final units = <Unit>[];
    final ids = <String>{};
    for (var i = 0; i < raw.length; i++) {
      final path = 'фракция.units[$i]';
      final rawUnit = raw[i];
      if (rawUnit is! Map<String, dynamic>) {
        throw FactionInvalidValueException(
          field: 'units',
          path: 'фракция',
          reason: 'элемент должен быть объектом юнита',
          value: rawUnit,
        );
      }
      _rejectUnknownFields(rawUnit, _unitFields, path);

      final id = _readNonEmptyString(rawUnit, 'id', path);
      if (!ids.add(id)) {
        throw FactionDuplicateUnitIdException(id);
      }
      final unitName = _readNonEmptyString(rawUnit, 'name', path);
      final power = _readNonNegativeInt(rawUnit, 'power', path);

      units.add(Unit(id: id, name: unitName, basePower: power));
    }
    return units;
  }

  List<StrengthModifier> _readModifiers(
    Map<String, dynamic> json,
    List<Unit> units,
  ) {
    final raw = json['modifiers'];
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw FactionInvalidValueException(
        field: 'modifiers',
        path: 'фракция',
        reason: 'должен быть списком модификаторов',
        value: raw,
      );
    }
    final unitIds = {for (final unit in units) unit.id};
    final modifiers = <StrengthModifier>[];
    for (var i = 0; i < raw.length; i++) {
      final path = 'фракция.modifiers[$i]';
      final rawModifier = raw[i];
      if (rawModifier is! Map<String, dynamic>) {
        throw FactionInvalidValueException(
          field: 'modifiers',
          path: 'фракция',
          reason: 'элемент должен быть объектом модификатора',
          value: rawModifier,
        );
      }
      _rejectUnknownFields(rawModifier, _modifierFields, path);

      final unitId = _readNonEmptyString(rawModifier, 'unit', path);
      if (!unitIds.contains(unitId)) {
        throw FactionUnknownUnitException(unitId);
      }
      final type = _readNonEmptyString(rawModifier, 'type', path);
      switch (type) {
        case 'toggle':
          modifiers.add(ToggleModifier(
            unitId: unitId,
            bonusPower: _readNonNegativeInt(rawModifier, 'bonusPower', path),
          ));
        case 'counter':
          modifiers.add(CounterModifier(
            unitId: unitId,
            step: _readOptionalInt(rawModifier, 'step', path, fallback: 1),
            maxCount: _readOptionalNonNegativeInt(
              rawModifier,
              'maxCount',
              path,
              fallback: 99,
            ),
          ));
        default:
          throw FactionUnknownModifierTypeException(type);
      }
    }
    return modifiers;
  }

  ArmyPowerFormula _readArmyPower(Map<String, dynamic> json) {
    if (!json.containsKey('armyPower')) {
      return ArmyPowerFormula.perUnit;
    }
    final value = json['armyPower'];
    switch (value) {
      case 'perUnit':
        return ArmyPowerFormula.perUnit;
      case 'nSquared':
        return ArmyPowerFormula.nSquared;
      default:
        throw FactionInvalidValueException(
          field: 'armyPower',
          path: 'фракция',
          reason: 'должно быть "perUnit" или "nSquared"',
          value: value,
        );
    }
  }

  /// Секция «Лавка бронника»: цена-ресурс из ресурсов фракции,
  /// лимит ≥ 1, целевые силы только у существующих юнитов.
  BattleUpgrade? _readBattleUpgrade(
    Map<String, dynamic> json,
    List<Unit> units,
    List<String> resources,
  ) {
    final raw = json['battleUpgrade'];
    if (raw == null) {
      return null;
    }
    if (raw is! Map<String, dynamic>) {
      throw FactionInvalidValueException(
        field: 'battleUpgrade',
        path: 'фракция',
        reason: 'должен быть объектом',
        value: raw,
      );
    }
    const path = 'фракция.battleUpgrade';
    _rejectUnknownFields(raw, _battleUpgradeFields, path);

    final resource = _readNonEmptyString(raw, 'resource', path);
    if (!resources.contains(resource)) {
      throw FactionInvalidValueException(
        field: 'resource',
        path: path,
        reason: 'должен быть одним из ресурсов фракции',
        value: resource,
      );
    }

    final limit = _readInt(raw, 'limit', path);
    if (limit < 1) {
      throw FactionInvalidValueException(
        field: 'limit',
        path: path,
        reason: 'должно быть целым числом не меньше 1',
        value: limit,
      );
    }

    final rawPowers = raw['powers'];
    if (rawPowers is! Map<String, dynamic> || rawPowers.isEmpty) {
      throw FactionInvalidValueException(
        field: 'powers',
        path: path,
        reason: 'должен быть объектом «id юнита → целевая сила»',
        value: rawPowers,
      );
    }
    final unitIds = {for (final unit in units) unit.id};
    final powers = <String, int>{};
    rawPowers.forEach((unitId, power) {
      if (!unitIds.contains(unitId)) {
        throw FactionUnknownUnitException(unitId);
      }
      if (power is! int || power < 0) {
        throw FactionInvalidValueException(
          field: unitId,
          path: '$path.powers',
          reason: 'целевая сила должна быть целым числом не меньше 0',
          value: power,
        );
      }
      powers[unitId] = power;
    });

    return BattleUpgrade(resource: resource, limit: limit, powers: powers);
  }

  /// Шаг счётчика — произвольное целое: положительный усиливает силу
  /// (счётчик улучшений), отрицательный уменьшает (счётчик урона).
  int _readOptionalInt(
    Map<String, dynamic> json,
    String field,
    String path, {
    required int fallback,
  }) {
    if (!json.containsKey(field)) {
      return fallback;
    }
    return _readInt(json, field, path);
  }

  int _readInt(Map<String, dynamic> json, String field, String path) {
    _requireField(json, field, path);
    final value = json[field];
    if (value is! int) {
      throw FactionInvalidValueException(
        field: field,
        path: path,
        reason: 'должно быть целым числом',
        value: value,
      );
    }
    return value;
  }

  int _readNonNegativeInt(
    Map<String, dynamic> json,
    String field,
    String path,
  ) {
    final value = _readInt(json, field, path);
    if (value < 0) {
      throw FactionInvalidValueException(
        field: field,
        path: path,
        reason: 'должно быть целым числом не меньше 0',
        value: value,
      );
    }
    return value;
  }

  int _readOptionalNonNegativeInt(
    Map<String, dynamic> json,
    String field,
    String path, {
    required int fallback,
  }) {
    if (!json.containsKey(field)) {
      return fallback;
    }
    return _readNonNegativeInt(json, field, path);
  }
}
