import 'package:flutter_test/flutter_test.dart';
import 'package:heroescompanion/features/factions/data/faction_repository.dart';

String _factionJson(int index) {
  final name = 'Фракция ${index + 1}';
  final part = index ~/ 6 + 1;
  return '''
{
  "name": "$name",
  "gamePart": $part,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "resources": ["Дерево"],
  "units": [{"id": "u$index", "name": "Юнит", "power": 1}]
}
''';
}

void main() {
  group('FactionRepository', () {
    test('загружает все 18 файлов каталога в порядке частей', () async {
      final repository = FactionRepository(
        load: (path) async {
          final file = path.substring(path.lastIndexOf('/') + 1);
          final index = FactionRepository.factionFiles.indexOf(file);
          return _factionJson(index);
        },
      );

      final catalog = await repository.loadCatalog();

      expect(catalog.factions, hasLength(18));
      expect(catalog.gameParts, [1, 2, 3]);
      expect(catalog.factionsOf(1), hasLength(6));
      expect(catalog.factionsOf(2), hasLength(6));
      expect(catalog.factionsOf(3), hasLength(6));
      expect(catalog.factions.first.name, 'Фракция 1');
      expect(catalog.byName('Фракция 7')?.gamePart, 2);
      expect(catalog.byName('Фракция 13')?.gamePart, 3);
      expect(catalog.byName('Несуществующая'), isNull);
    });

    test('файлы каталога — канонический порядок: по 6 на часть', () {
      const expected = [
        'humans.json', 'necros.json', 'gnomes.json', 'orcs.json',
        'elfs.json', 'nags.json',
        'gremlins.json', 'mechanisms.json', 'elementals.json',
        'demons.json', 'halflings.json', 'cultists.json',
        'mushroomers.json', 'werewolves.json', 'archons.json',
        'lizardmen.json', 'darkelfs.json', 'cyclops.json',
      ];

      expect(FactionRepository.factionFiles, expected);
    });

    test('битый JSON одного файла → исключение парсера', () async {
      final repository = FactionRepository(
        load: (path) async =>
            path.endsWith('humans.json') ? '{не json' : _factionJson(0),
      );

      expect(repository.loadCatalog(), throwsA(isA<Exception>()));
    });
  });
}
