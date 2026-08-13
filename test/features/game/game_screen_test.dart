import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/domain/strength_modifier.dart';
import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/features/factions/data/faction_repository.dart';
import 'package:heroescompanion/features/game/data/game_session_provider.dart';
import 'package:heroescompanion/main.dart';

/// Богатая фракция: 2 юнита (toggle и counter модификаторы), 3 ресурса.
const _richFactionJson = '''
{
  "name": "Тестовая",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "resources": ["Дерево", "Железо", "Золото"],
  "units": [
    {"id": "soldier", "name": "Солдат", "power": 2},
    {"id": "latnik", "name": "Латник", "power": 5}
  ],
  "modifiers": [
    {"unit": "soldier", "type": "toggle", "bonusPower": 3},
    {"unit": "latnik", "type": "counter", "step": 1}
  ]
}
''';

String _factionJson(int index) {
  if (index == 0) return _richFactionJson;
  return '''
{
  "name": "Тестовая $index",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "resources": ["Дерево"],
  "units": [{"id": "u$index", "name": "Юнит", "power": 1}]
}
''';
}

FactionRepository _fakeRepository() {
  final byPath = {
    for (var i = 0; i < FactionRepository.factionFiles.length; i++)
      '${FactionRepository.assetPrefix}${FactionRepository.factionFiles[i]}':
          _factionJson(i),
  };
  return FactionRepository(load: (path) async => byPath[path]!);
}

Future<ProviderContainer> _openGameScreen(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [factionRepositoryProvider.overrideWithValue(_fakeRepository())],
  );
  addTearDown(container.dispose);

  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const HeroesCompanionApp(),
    ),
  );
  await tester.tap(find.text('Начать игру'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Тестовая'));
  await tester.pumpAndSettle();
  return container;
}

/// Симулирует системное «назад» (как в тестах Flutter framework):
/// платформенное сообщение popRoute по каналу навигации — полный путь
/// через RootBackButtonDispatcher (go_router) → RouterDelegate.popRoute →
/// maybePop → PopScope.
Future<void> _simulateSystemBack() {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.navigation.name,
        const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'method': 'popRoute',
        }),
        (ByteData? _) {},
      );
}

void main() {
  testWidgets('элементы партии отображаются и читаются из сессии', (
    tester,
  ) async {
    await _openGameScreen(tester);

    expect(find.text('Партия: Тестовая'), findsOneWidget);
    expect(find.text('Текущий раунд: 1'), findsOneWidget);
    expect(find.text('Сила армии: 0'), findsOneWidget);
    expect(find.text('Сила в бой: 0'), findsOneWidget);
    expect(find.text('Ресурсы'), findsOneWidget);
    expect(find.text('Порядок действий'), findsOneWidget);
    expect(find.text('Следующий раунд'), findsOneWidget);
    expect(find.text('МОДИФИКАТОРЫ СИЛЫ'), findsOneWidget);
    expect(find.text('Солдат'), findsWidgets);
    expect(find.text('Латник'), findsWidgets);
  });

  testWidgets('сила армии пересчитывается при изменении счётчиков', (
    tester,
  ) async {
    final container = await _openGameScreen(tester);
    final notifier = container.read(gameSessionProvider('Тестовая').notifier);

    notifier.setArmyTotal('soldier', 2);
    await tester.pump();

    expect(find.text('Сила армии: 4'), findsOneWidget);

    notifier.setArmyDeployed('soldier', 1);
    await tester.pump();

    expect(find.text('Сила в бой: 2'), findsOneWidget);
  });

  testWidgets(
    '«Следующий раунд» увеличивает раунд; на 16-м — «Закончить игру»',
    (tester) async {
      await _openGameScreen(tester);

      for (var round = 2; round <= 15; round++) {
        await tester.tap(find.text('Следующий раунд'));
        await tester.pump();
        expect(find.text('Текущий раунд: $round'), findsOneWidget);
      }
      await tester.tap(find.text('Следующий раунд'));
      await tester.pump();

      expect(find.text('Текущий раунд: 16'), findsOneWidget);
      expect(find.text('Закончить игру'), findsOneWidget);
      expect(find.text('Следующий раунд'), findsNothing);
    },
  );

  testWidgets('«Закончить игру» ведёт на ввод очков с фракцией игрока', (
    tester,
  ) async {
    await _openGameScreen(tester);

    for (var i = 0; i < 15; i++) {
      await tester.tap(find.text('Следующий раунд'));
      await tester.pump();
    }
    await tester.tap(find.text('Закончить игру'));
    await tester.pumpAndSettle();

    expect(find.text('Заглушка: ввод очков (Тестовая)'), findsOneWidget);
  });

  testWidgets('модалка модификаторов читает сессию и не теряет состояние', (
    tester,
  ) async {
    final container = await _openGameScreen(tester);

    await tester.tap(find.text('МОДИФИКАТОРЫ СИЛЫ'));
    await tester.pumpAndSettle();

    expect(find.text('Увеличить силу юнита (Солдат): 2 → 3'), findsOneWidget);
    expect(find.text('Увеличить силу юнита (Латник)'), findsOneWidget);

    // Включение toggle меняет силу армии в сессии.
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    final session = container.read(gameSessionProvider('Тестовая'));
    expect((session.modifiers[0] as ToggleModifier).isEnabled, isTrue);

    // Закрытие и повторное открытие не теряют состояние.
    await tester.tapAt(const Offset(600, 30));
    await tester.pumpAndSettle();
    await tester.tap(find.text('МОДИФИКАТОРЫ СИЛЫ'));
    await tester.pumpAndSettle();

    final reopened = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(reopened.value, isTrue);
  });

  testWidgets('выход — только двойным «назад»', (tester) async {
    await _openGameScreen(tester);

    await _simulateSystemBack();
    await tester.pump();

    expect(find.text('Нажмите «назад» ещё раз, чтобы выйти'), findsOneWidget);
    expect(find.text('Текущий раунд: 1'), findsOneWidget);

    await _simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('Выбери фракцию'), findsOneWidget);
    expect(find.text('Текущий раунд: 1'), findsNothing);
  });
}
