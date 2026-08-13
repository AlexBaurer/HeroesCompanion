import 'package:flutter_test/flutter_test.dart';
import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/faction_catalog.dart';

Faction _faction(String name, int gamePart) {
  return Faction(
    name: name,
    gamePart: gamePart,
    color: '#BE5737',
    backgroundPath: 'assets/faction_background/humans_low.PNG',
    resources: const ['Дерево'],
    units: const [Unit(id: 'u', name: 'Юнит', basePower: 1)],
  );
}

void main() {
  group('FactionCatalog', () {
    test('пустой каталог: частей нет, поиск пуст', () {
      final catalog = FactionCatalog(const []);

      expect(catalog.factions, isEmpty);
      expect(catalog.gameParts, isEmpty);
      expect(catalog.factionsOf(1), isEmpty);
      expect(catalog.byName('Люди'), isNull);
    });

    test('сохраняет порядок фракций из данных', () {
      final catalog = FactionCatalog([
        _faction('Люди', 1),
        _faction('Наги', 1),
        _faction('Гриболюды', 3),
      ]);

      expect(catalog.factions.map((f) => f.name), ['Люди', 'Наги', 'Гриболюды']);
    });

    test('группирует фракции по частям игры в порядке данных', () {
      final catalog = FactionCatalog([
        _faction('Гриболюды', 3),
        _faction('Люди', 1),
        _faction('Гремлины', 2),
        _faction('Наги', 1),
        _faction('Оборотни', 3),
        _faction('Элементали', 2),
      ]);

      expect(catalog.gameParts, [1, 2, 3]);
      expect(
        catalog.factionsOf(1).map((f) => f.name),
        ['Люди', 'Наги'],
      );
      expect(
        catalog.factionsOf(2).map((f) => f.name),
        ['Гремлины', 'Элементали'],
      );
      expect(
        catalog.factionsOf(3).map((f) => f.name),
        ['Гриболюды', 'Оборотни'],
      );
      expect(catalog.factionsOf(4), isEmpty);
    });

    test('поиск фракции по имени', () {
      final catalog = FactionCatalog([
        _faction('Люди', 1),
        _faction('Тёмные эльфы', 3),
      ]);

      expect(catalog.byName('Люди')?.gamePart, 1);
      expect(catalog.byName('Тёмные эльфы')?.gamePart, 3);
      expect(catalog.byName('Драконы'), isNull);
    });
  });
}
