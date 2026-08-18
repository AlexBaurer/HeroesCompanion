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

    // Плитка (InkWell) растянута на всю ширину, высота фиксирована.
    final tile = find.ancestor(
      of: find.text('Люди'),
      matching: find.byType(InkWell),
    );
    final box = tester.renderObject<RenderBox>(tile);
    expect(box.size.width, 1200);
    expect(box.size.height, FactionChooseScreen.tileHeight);

    // Соседние плитки без зазора: текст центрирован по вертикали в плитке,
    // поэтому расстояние между верхними краями строк равно высоте плитки.
    final topLeft = tester.getTopLeft(find.text('Люди'));
    final nextTopLeft = tester.getTopLeft(find.text('Нежить'));
    expect(nextTopLeft.dy - topLeft.dy, FactionChooseScreen.tileHeight);
  });

  testWidgets(
    'нет верхнего бара: AppBar, «назад» и заголовок убраны; плитки от верха',
    (tester) async {
      await _openFactionChoose(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.text('Выбери фракцию'), findsNothing);

      final firstTile = find.ancestor(
        of: find.text('Люди'),
        matching: find.byType(InkWell),
      );
      expect(tester.getTopLeft(firstTile).dy, 0);
    },
  );

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

  testWidgets('тап по плитке раскрывает под ней описание и «Выбрать»', (
    tester,
  ) async {
    await _openFactionChoose(tester);

    await tester.tap(find.text('Тёмные эльфы'));
    await tester.pumpAndSettle();

    expect(find.text(fakeDescriptions[16]), findsOneWidget);
    expect(find.text('Выбрать'), findsOneWidget);
    expect(find.text('Начать игру'), findsNothing);
    expect(find.textContaining('Партия:'), findsNothing);
  });

  testWidgets('картинка гаснет в белый за 10px на всю ширину плитки', (
    tester,
  ) async {
    await _openFactionChoose(tester);

    await tester.tap(find.text('Люди'));
    await tester.pumpAndSettle();

    // Полоса перехода между плиткой и панелью: на всю ширину плитки,
    // высота 10px, градиент от прозрачного (картинка видна — без шва
    // с плиткой) к полностью белому (без просвечивания и отделения).
    final fade = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final gradient =
        (fade.decoration as BoxDecoration).gradient as LinearGradient;
    expect(gradient.colors.first, Colors.transparent);
    expect(gradient.colors.last.a, 1.0);

    final box = tester.renderObject<RenderBox>(find.byType(DecoratedBox));
    expect(box.size.width, 1200);
    expect(box.size.height, 10);
  });

  testWidgets(
    'раскрытие идёт сверху вниз: в середине анимации ширина уже полная',
    (tester) async {
      await _openFactionChoose(tester);

      await tester.tap(find.text('Люди'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));

      // На середине анимации бокс AnimatedSize уже на всю ширину, растёт
      // только высота — картинка и полоса не расползаются из центра.
      final anim = tester.renderObject<RenderBox>(find.byType(AnimatedSize));
      expect(anim.size.width, 1200);
      expect(anim.size.height, greaterThan(0));

      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'раскрыта одна плитка: тап по другой переключает, повторный сворачивает',
    (tester) async {
      await _openFactionChoose(tester);

      await tester.tap(find.text('Люди'));
      await tester.pumpAndSettle();
      expect(find.text(fakeDescriptions[0]), findsOneWidget);
      expect(find.text(fakeDescriptions[16]), findsNothing);

      // Тап по другой плитке: раскрытая сворачивается, новая раскрывается.
      await tester.tap(find.text('Тёмные эльфы'));
      await tester.pumpAndSettle();
      expect(find.text(fakeDescriptions[16]), findsOneWidget);
      expect(find.text(fakeDescriptions[0]), findsNothing);
      expect(find.text('Выбрать'), findsOneWidget);

      // Повторный тап по раскрытой плитке сворачивает её.
      await tester.tap(find.text('Тёмные эльфы'));
      await tester.pumpAndSettle();
      expect(find.text(fakeDescriptions[16]), findsNothing);
      expect(find.text('Выбрать'), findsNothing);
    },
  );

  testWidgets('«Выбрать» ведёт на экран партии с выбранной фракцией', (
    tester,
  ) async {
    await _openFactionChoose(tester);

    await tester.tap(find.text('Люди'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать'));
    await tester.pumpAndSettle();

    expect(find.text('Партия: Люди'), findsOneWidget);
    expect(find.text('Текущий раунд: 1'), findsOneWidget);
    expect(find.text(fakeDescriptions[0]), findsNothing);
  });
}
