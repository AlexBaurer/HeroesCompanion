import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/app/app_router.dart';
import 'package:heroescompanion/app/color_hex.dart';
import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/main.dart';

import '../../helpers/fake_faction_repository.dart';
import '../../helpers/simulate_system_back.dart';

/// Открывает окно фракции [faction] через цепочку: главное меню →
/// выбор фракции → тап по плитке.
Future<void> _openPreview(WidgetTester tester, {String faction = 'Люди'}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // appRouter глобальный: состояние навигации переживает тесты, поэтому
  // сбрасываем его на главное меню перед новым деревом.
  appRouter.go('/');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        factionRepositoryProvider.overrideWithValue(fakeFactionRepository()),
      ],
      child: const HeroesCompanionApp(),
    ),
  );

  await tester.tap(find.text('Начать игру'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(faction));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('тап по плитке открывает окно фракции, а не экран партии', (
    tester,
  ) async {
    await _openPreview(tester, faction: 'Люди');

    expect(find.text(fakeDescriptions[0]), findsOneWidget);
    expect(find.text('Начать игру'), findsOneWidget);
    expect(find.text('Люди'), findsOneWidget);
    expect(find.textContaining('Партия:'), findsNothing);
  });

  testWidgets('окно показывает фон, имя и описание выбранной фракции', (
    tester,
  ) async {
    await _openPreview(tester, faction: 'Тёмные эльфы');

    // Фон: errorBuilder подставляет сплошной цвет фракции.
    final colorBox = find.descendant(
      of: find.ancestor(
        of: find.text('Тёмные эльфы'),
        matching: find.byType(Stack),
      ),
      matching: find.byType(ColoredBox),
    );
    expect(colorBox, findsOneWidget);
    expect(
      tester.widget<ColoredBox>(colorBox).color,
      colorFromHex('#BE5737'),
    );

    expect(find.text('Тёмные эльфы'), findsOneWidget);
    expect(find.text(fakeDescriptions[16]), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('окно показывает описание именно выбранной фракции', (
    tester,
  ) async {
    await _openPreview(tester, faction: 'Наги');

    expect(find.text(fakeDescriptions[5]), findsOneWidget);
    expect(find.text(fakeDescriptions[0]), findsNothing);
  });

  testWidgets('«Начать игру» ведёт на экран партии с выбранной фракцией', (
    tester,
  ) async {
    await _openPreview(tester, faction: 'Люди');

    await tester.tap(find.text('Начать игру'));
    await tester.pumpAndSettle();

    expect(find.text('Партия: Люди'), findsOneWidget);
    expect(find.text('Текущий раунд: 1'), findsOneWidget);
    expect(find.text(fakeDescriptions[0]), findsNothing);
  });

  testWidgets('системное «назад» из окна возвращает на выбор фракции', (
    tester,
  ) async {
    await _openPreview(tester, faction: 'Люди');

    await simulateSystemBack();
    await tester.pumpAndSettle();

    // Снова экран выбора: плитки всех фракций, окна фракции нет.
    for (final name in factionNames) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text(fakeDescriptions[0]), findsNothing);
    expect(find.textContaining('Партия:'), findsNothing);
  });
}