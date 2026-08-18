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

/// Здание «Лавка бронника» (эльфы): перед сражением игрок платит
/// любое количество [resource] и модифицирует силу до [limit] боевых
/// единиц «в бой» до целевой на текущее сражение. Эффект временный —
/// в следующем сражении платится снова.
class BattleUpgrade {
  const BattleUpgrade({
    required this.resource,
    required this.limit,
    required this.powers,
  });

  /// Ресурс-цена (у эльфов — Дерево).
  final String resource;

  /// Максимум боевых единиц, модифицируемых за одно сражение.
  final int limit;

  /// Целевая сила по id юнита (`pixi` → 2, `grifon` → 5, `ent` → 10).
  final Map<String, int> powers;

  int? targetPowerOf(String unitId) => powers[unitId];
}

class Faction {
  const Faction({
    required this.name,
    required this.gamePart,
    required this.color,
    required this.backgroundPath,
    required this.description,
    required this.resources,
    required this.units,
    this.modifiers = const [],
    this.armyPowerFormula = ArmyPowerFormula.perUnit,
    this.battleUpgrade,
  });

  final String name;
  final int gamePart;
  final String color;
  final String backgroundPath;

  /// Краткое описание фракции (2–3 предложения) — показывается в окне
  /// фракции перед переходом в партию.
  final String description;
  final List<String> resources;
  final List<Unit> units;
  final List<StrengthModifier> modifiers;
  final ArmyPowerFormula armyPowerFormula;

  /// Здание «Лавка бронника» — признак особой механики (как `armyPower`);
  /// есть только у эльфов.
  final BattleUpgrade? battleUpgrade;

  Unit? unitById(String id) {
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  List<StrengthModifier> modifiersFor(String unitId) =>
      modifiers.where((modifier) => modifier.unitId == unitId).toList();
}
