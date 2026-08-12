import 'strength_modifier.dart';

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
  });

  final String name;
  final int gamePart;
  final String color;
  final String backgroundPath;
  final List<String> resources;
  final List<Unit> units;
  final List<StrengthModifier> modifiers;

  Unit? unitById(String id) {
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  List<StrengthModifier> modifiersFor(String unitId) =>
      modifiers.where((modifier) => modifier.unitId == unitId).toList();
}
