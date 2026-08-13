import 'dart:io';

import 'package:heroescompanion/features/factions/data/faction_repository.dart';

/// Прогоняет FactionRepository + FactionCatalog по реальным JSON-файлам
/// фракций (тикет 06): 18 фракций, по 6 на часть, имена в порядке каталога.
///
/// Запуск без Flutter SDK: `dart run tool/verify_faction_catalog.dart`.
/// Полная проверка — в test/ (flutter test на машине со SDK).
Future<void> main() async {
  final repository = FactionRepository(
    load: (path) async => File(path).readAsStringSync(),
  );
  final catalog = await repository.loadCatalog();

  final failures = <String>[];

  void check(bool condition, String message) {
    if (!condition) failures.add(message);
  }

  final factions = catalog.factions;
  check(factions.length == 18, 'ожидалось 18 фракций, получено ${factions.length}');

  for (var part = 1; part <= 3; part++) {
    final ofPart = catalog.factionsOf(part);
    check(
      ofPart.length == 6,
      'часть $part — ожидалось 6 фракций, получено ${ofPart.length}',
    );
    stdout.writeln('часть $part: ${ofPart.map((f) => f.name).join(', ')}');
  }

  check(
    catalog.gameParts.join(',') == '1,2,3',
    'части игры: ожидались 1,2,3, получены ${catalog.gameParts}',
  );

  for (final faction in factions) {
    stdout.writeln(
      'ok   ${faction.name} → ${faction.color} '
      '(${faction.units.length} юнитов, ${faction.modifiers.length} модификаторов)',
    );
    final found = catalog.byName(faction.name);
    check(found != null, 'не найден по имени: ${faction.name}');
    check(
      found?.color == faction.color,
      'поиск вернул другую фракцию: ${faction.name}',
    );
  }

  check(
    catalog.byName('Драконы') == null,
    'поиск несуществующей фракции должен возвращать null',
  );

  if (failures.isEmpty) {
    stdout.writeln('OK: каталог 18 фракций корректен');
  } else {
    for (final failure in failures) {
      stderr.writeln('FAIL: $failure');
    }
    exit(1);
  }
}
