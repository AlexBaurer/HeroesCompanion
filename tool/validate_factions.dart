import 'dart:io';

import '../lib/domain/faction_parser.dart';

/// Прогоняет FactionParser по всем JSON-файлам фракций (тикет 05).
///
/// Запуск без Flutter SDK: `dart run tool/validate_factions.dart`.
/// Полная проверка данных — в test/domain/faction_data_test.dart (flutter test).
void main() {
  const files = [
    'humans.json', 'necros.json', 'gnomes.json', 'orcs.json', 'elfs.json',
    'nags.json', 'gremlins.json', 'mechanisms.json', 'elementals.json',
    'demons.json', 'halflings.json', 'cultists.json', 'mushroomers.json',
    'werewolves.json', 'archons.json', 'lizardmen.json', 'darkelfs.json',
    'cyclops.json',
  ];
  const names = [
    'Люди', 'Нежить', 'Гномы', 'Орки', 'Эльфы', 'Наги', 'Гремлины',
    'Механизмы', 'Элементали', 'Демоны', 'Полурослики', 'Культисты',
    'Гриболюды', 'Оборотни', 'Архонты', 'Ящеры', 'Тёмные эльфы', 'Циклопы',
  ];

  final parser = const FactionParser();
  final parsed = <String>[];
  var failures = 0;

  void fail(String message) {
    stderr.writeln('FAIL: $message');
    failures++;
  }

  for (final file in files) {
    final source = File('assets/factions/$file').readAsStringSync();
    final faction = parser.parse(source);
    parsed.add(faction.name);
    stdout.writeln(
      'ok   $file → ${faction.name} (часть ${faction.gamePart}, '
      '${faction.units.length} юнитов, ${faction.modifiers.length} модификаторов)',
    );
  }

  if (parsed.length != 18) {
    fail('ожидалось 18 фракций, получено ${parsed.length}');
  }
  if (parsed.join() != names.join()) {
    fail('имена фракций не совпадают: $parsed');
  }
  for (var part = 1; part <= 3; part++) {
    final actual = files
        .map((f) => parser.parse(File('assets/factions/$f').readAsStringSync()))
        .where((f) => f.gamePart == part)
        .length;
    if (actual != 6) {
      fail('часть $part — ожидалось 6 фракций, получено $actual');
    }
  }

  if (failures == 0) {
    stdout.writeln('OK: 18 фракций валидны (по 6 на часть)');
  } else {
    stderr.writeln('$failures ошибок валидации');
    exit(1);
  }
}
