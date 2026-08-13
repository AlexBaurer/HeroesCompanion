import 'faction.dart';

/// Каталог всех фракций игры: группировка по частям (коробкам) и поиск
/// по имени. Сохраняет порядок данных.
class FactionCatalog {
  FactionCatalog(Iterable<Faction> factions)
      : _factions = List.unmodifiable(factions);

  final List<Faction> _factions;

  List<Faction> get factions => _factions;

  /// Части игры, присутствующие в каталоге, в порядке возрастания.
  List<int> get gameParts {
    final parts = <int>{};
    for (final faction in _factions) {
      parts.add(faction.gamePart);
    }
    final result = parts.toList()..sort();
    return result;
  }

  /// Фракции части [gamePart] в порядке данных каталога.
  List<Faction> factionsOf(int gamePart) =>
      _factions.where((faction) => faction.gamePart == gamePart).toList();

  /// Фракция по имени или null, если её нет в каталоге.
  Faction? byName(String name) {
    for (final faction in _factions) {
      if (faction.name == name) return faction;
    }
    return null;
  }
}
