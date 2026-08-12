import 'strength_modifier.dart';

/// Формула силы армии фракции.
enum ArmyPowerFormula {
  /// Σ(количество × сила юнита) — стандартный расчёт.
  perUnit,

  /// Σ(количество²) — «Наги»: краки по n².
  nSquared,
}

class Unit {
  const Unit({required this.id, required this.name, required this.basePower});

  final String id;
  final String name;
  final int basePower;
}

class Faction {
  const Faction({
    required this.name,
    required this.gamePart,
    required this.color,
    required this.backgroundPath,
    required this.resources,
    required this.units,
    this.modifiers = const [],
    this.armyPowerFormula = ArmyPowerFormula.perUnit,
  });

  final String name;
  final int gamePart;
  final String color;
  final String backgroundPath;
  final List<String> resources;
  final List<Unit> units;
  final List<StrengthModifier> modifiers;
  final ArmyPowerFormula armyPowerFormula;

  Unit? unitById(String id) {
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  List<StrengthModifier> modifiersFor(String unitId) =>
      modifiers.where((modifier) => modifier.unitId == unitId).toList();
}
