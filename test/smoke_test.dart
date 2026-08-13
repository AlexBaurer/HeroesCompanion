import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/features/factions/data/faction_repository.dart';
import 'package:heroescompanion/main.dart';

const _factionNames = [
  'Люди', 'Нежить', 'Гномы', 'Орки', 'Эльфы', 'Наги',
  'Гремлины', 'Механизмы', 'Элементали', 'Демоны', 'Полурослики', 'Культисты',
  'Гриболюды', 'Оборотни', 'Архонты', 'Ящеры', 'Тёмные эльфы', 'Циклопы',
];

/// Заглушка данных фракций: без реального чтения ассетов в тесте.
FactionRepository _fakeRepository() {
  final byPath = {
    for (var i = 0; i < _factionNames.length; i++)
      '${FactionRepository.assetPrefix}${FactionRepository.factionFiles[i]}':
          _fakeFactionJson(i),
  };
  return FactionRepository(load: (path) async => byPath[path]!);
}

String _fakeFactionJson(int index) {
  final name = _factionNames[index];
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

Widget _app({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const HeroesCompanionApp(),
  );
}

void main() {
  testWidgets('приложение открывается на главном меню', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('Герои — Помощник'), findsOneWidget);
    expect(find.text('Начать игру'), findsOneWidget);
    expect(find.text('Записи игр'), findsOneWidget);
  });

  testWidgets('главное меню → выбор фракции → экран партии', (tester) async {
    // Высокий вьюпорт: секции 1–3 и все 18 кнопок строятся сразу
    // (ListView ленивый, за пределами экрана виджеты не существуют).
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(overrides: [
        factionRepositoryProvider.overrideWithValue(_fakeRepository()),
      ]),
    );

    await tester.tap(find.text('Начать игру'));
    await tester.pumpAndSettle();

    expect(find.text('Выбери фракцию'), findsOneWidget);
    expect(find.text('Часть 1'), findsOneWidget);
    expect(find.text('Часть 2'), findsOneWidget);
    expect(find.text('Часть 3'), findsOneWidget);
    for (final name in _factionNames) {
      expect(find.text(name), findsOneWidget);
    }

    await tester.tap(find.text('Тёмные эльфы'));
    await tester.pumpAndSettle();

    expect(find.text('Партия: Тёмные эльфы'), findsOneWidget);
  });
}
