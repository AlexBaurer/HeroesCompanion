import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/app/app_router.dart';
import 'package:heroescompanion/app/color_hex.dart';
import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/features/main_menu/presentation/faction_choose_screen.dart';
import 'package:heroescompanion/main.dart';

import '../../helpers/fake_faction_repository.dart';

/// Высокий вьюпорт: все 18 плиток (по 120dp) строятся без прокрутки.
Future<void> _openFactionChoose(WidgetTester tester) async {
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
}

void main() {
  testWidgets('все 18 фракций одним списком, без заголовков частей', (
    tester,
  ) async {
    await _openFactionChoose(tester);

    for (final name in factionNames) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.textContaining('Часть'), findsNothing);
  });

  testWidgets('плитки на всю ширину, высота 120dp, без зазоров и отступов', (
    tester,
  ) async {
    await _openFactionChoose(tester);

    // Fallback-цвет (errorBuilder) заполняет плитку: его размер равен
    // размеру плитки — на всю ширину, высота фиксирована.
    final colorBox = find.descendant(
      of: find.ancestor(of: find.text('Люди'), matching: find.byType(InkWell)),
      matching: find.byType(ColoredBox),
    );
    final box = tester.renderObject<RenderBox>(colorBox);
    expect(box.size.width, 1200);
    expect(box.size.height, FactionChooseScreen.tileHeight);

    // Соседние плитки без зазора: текст центрирован по вертикали в плитке,
    // поэтому расстояние между верхними краями строк равно высоте плитки.
    final topLeft = tester.getTopLeft(find.text('Люди'));
    final nextTopLeft = tester.getTopLeft(find.text('Нежить'));
    expect(nextTopLeft.dy - topLeft.dy, FactionChooseScreen.tileHeight);
  });

  testWidgets('без ассета фона — сплошной цвет фракции и имя плитки', (
    tester,
  ) async {
    await _openFactionChoose(tester);

    // errorBuilder заменяет изображение на цвет фракции: под именем
    // каждой плитки лежит ColoredBox цвета фракции.
    final colorBox = find.descendant(
      of: find.ancestor(of: find.text('Люди'), matching: find.byType(InkWell)),
      matching: find.byType(ColoredBox),
    );
    expect(colorBox, findsOneWidget);
    final box = tester.widget<ColoredBox>(colorBox);
    expect(box.color, colorFromHex('#BE5737'));
    expect(find.text('Люди'), findsOneWidget);
  });

  testWidgets('тап по плитке открывает экран партии с выбранной фракцией', (
    tester,
  ) async {
    await _openFactionChoose(tester);

    await tester.tap(find.text('Тёмные эльфы'));
    await tester.pumpAndSettle();

    expect(find.text('Партия: Тёмные эльфы'), findsOneWidget);
  });
}
