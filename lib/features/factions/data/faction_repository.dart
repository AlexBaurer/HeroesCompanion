import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/faction_catalog.dart';
import 'package:heroescompanion/domain/faction_parser.dart';

/// Загрузчик содержимого ассета: путь → текст JSON.
typedef FactionAssetLoader = Future<String> Function(String path);

/// Читает JSON-файлы фракций из ассетов и собирает каталог.
///
/// Загрузчик инжектируется, чтобы код оставался чистым Dart:
/// в приложении — [rootBundle], в тестах и tool-скриптах — файлы диска.
class FactionRepository {
  const FactionRepository({required this.load});

  final FactionAssetLoader load;

  static const factionFiles = [
    // Часть 1 (коробка 1)
    'humans.json',
    'necros.json',
    'gnomes.json',
    'orcs.json',
    'elfs.json',
    'nags.json',
    // Часть 2 (коробка 2)
    'gremlins.json',
    'mechanisms.json',
    'elementals.json',
    'demons.json',
    'halflings.json',
    'cultists.json',
    // Часть 3 (коробка 3)
    'mushroomers.json',
    'werewolves.json',
    'archons.json',
    'lizardmen.json',
    'darkelfs.json',
    'cyclops.json',
  ];

  static const assetPrefix = 'assets/factions/';

  /// Загружает все 18 фракций в порядке каталога (по частям игры).
  Future<FactionCatalog> loadCatalog() async {
    const parser = FactionParser();
    final factions = <Faction>[];
    for (final file in factionFiles) {
      final source = await load('$assetPrefix$file');
      factions.add(parser.parse(source));
    }
    return FactionCatalog(factions);
  }
}
