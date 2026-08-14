import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/main.dart';

import 'helpers/fake_faction_repository.dart';

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
    // Высокий вьюпорт: все 18 плиток (по 120dp) строятся без прокрутки.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(overrides: [
        factionRepositoryProvider.overrideWithValue(fakeFactionRepository()),
      ]),
    );

    await tester.tap(find.text('Начать игру'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    for (final name in factionNames) {
      expect(find.text(name), findsOneWidget);
    }

    await tester.tap(find.text('Тёмные эльфы'));
    await tester.pumpAndSettle();

    expect(find.text('Партия: Тёмные эльфы'), findsOneWidget);
  });
}
