import 'package:heroescompanion/features/factions/data/faction_repository.dart';

/// Имена всех 18 фракций в порядке каталога (части 1→3) — общий фикстур
/// для тестов UI (выбор фракции, экран партии).
const factionNames = [
  'Люди',
  'Нежить',
  'Гномы',
  'Орки',
  'Эльфы',
  'Наги',
  'Гремлины',
  'Механизмы',
  'Элементали',
  'Демоны',
  'Полурослики',
  'Культисты',
  'Гриболюды',
  'Оборотни',
  'Архонты',
  'Ящеры',
  'Тёмные эльфы',
  'Циклопы',
];

/// Каталог 18 фракций без реального чтения ассетов (для тестов UI).
///
/// Фон всегда указывает на несуществующий ассет, чтобы тесты шли по пути
/// errorBuilder (fallback на цвет фракции) — как в приложении без
/// подготовленных пользователем изображений.
FactionRepository fakeFactionRepository() {
  final byPath = {
    for (var i = 0; i < factionNames.length; i++)
      '${FactionRepository.assetPrefix}${FactionRepository.factionFiles[i]}':
          fakeFactionJson(i),
  };
  return FactionRepository(load: (path) async => byPath[path]!);
}

String fakeFactionJson(int index) {
  final name = factionNames[index];
  final part = index ~/ 6 + 1;
  return '''
{
  "name": "$name",
  "gamePart": $part,
  "color": "#BE5737",
  "background": "assets/faction_background/missing_$index.PNG",
  "resources": ["Дерево"],
  "units": [{"id": "u$index", "name": "Юнит", "power": 1}]
}
''';
}
