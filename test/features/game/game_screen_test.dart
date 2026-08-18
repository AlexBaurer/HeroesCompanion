import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/app/app_router.dart';
import 'package:heroescompanion/domain/strength_modifier.dart';
import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/features/factions/data/faction_repository.dart';
import 'package:heroescompanion/features/game/data/game_session_provider.dart';
import 'package:heroescompanion/features/game/presentation/widgets/resource_counter_wheel.dart';
import 'package:heroescompanion/main.dart';

import '../../helpers/simulate_system_back.dart';

/// Богатая фракция: 2 юнита (toggle и counter модификаторы), 3 ресурса.
const _richFactionJson = '''
{
  "name": "Тестовая",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "description": "Тестовая фракция с богатыми юнитами.",
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

/// Фракция с «Лавкой бронника» (эльфы): без модификаторов, с апгрейдом.
const _elfFactionJson = '''
{
  "name": "Лавка",
  "gamePart": 1,
  "color": "#732EB4",
  "background": "assets/faction_background/elfs_low.PNG",
  "description": "Фракция с лавкой бронника.",
  "resources": ["Дерево", "Железо", "Золото"],
  "units": [
    {"id": "pixi", "name": "Пикси", "power": 1},
    {"id": "grifon", "name": "Грифон", "power": 3},
    {"id": "ent", "name": "Энт", "power": 6}
  ],
  "battleUpgrade": {
    "resource": "Дерево",
    "limit": 2,
    "powers": {"pixi": 2, "grifon": 5, "ent": 10}
  }
}
''';

String _factionJson(int index) {
  if (index == 0) return _richFactionJson;
  if (index == 1) return _elfFactionJson;
  return '''
{
  "name": "Тестовая $index",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "description": "Тестовая фракция номер $index.",
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

Future<ProviderContainer> _openGameScreen(
  WidgetTester tester, {
  String factionName = 'Тестовая',
}) async {
  final container = ProviderContainer(
    overrides: [factionRepositoryProvider.overrideWithValue(_fakeRepository())],
  );
  addTearDown(container.dispose);

  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // appRouter глобальный: состояние навигации переживает тесты, поэтому
  // сбрасываем его на главное меню перед новым деревом.
  appRouter.go('/');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const HeroesCompanionApp(),
    ),
  );
  await tester.tap(find.text('Начать игру'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(factionName));
  await tester.pumpAndSettle();
  // Тикет 19: тап по плитке открывает окно фракции, «Начать игру» —
  // экран партии.
  await tester.tap(find.text('Начать игру'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('элементы партии отображаются и читаются из сессии', (
    tester,
  ) async {
    await _openGameScreen(tester);

    expect(find.byType(AppBar), findsNothing);
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

  testWidgets('«Следующий раунд» обнуляет «в бой» и вычитает из армии', (
    tester,
  ) async {
    final container = await _openGameScreen(tester);
    final notifier = container.read(gameSessionProvider('Тестовая').notifier);
    notifier.setArmyTotal('soldier', 3);
    notifier.setArmyDeployed('soldier', 2);
    await tester.pump();

    expect(find.text('Сила в бой: 4'), findsOneWidget);
    expect(find.text('Сила армии: 6'), findsOneWidget);

    await tester.tap(find.text('Следующий раунд'));
    await tester.pump();

    expect(find.text('Текущий раунд: 2'), findsOneWidget);
    expect(find.text('Сила в бой: 0'), findsOneWidget);
    expect(find.text('Сила армии: 2'), findsOneWidget);
  });

  testWidgets('колёсико «в бой» не может превысить общее число юнита', (
    tester,
  ) async {
    final container = await _openGameScreen(tester);
    final notifier = container.read(gameSessionProvider('Тестовая').notifier);
    notifier.setArmyTotal('soldier', 3);
    await tester.pump();

    final totalWheel = tester.widget<ResourceCounterWheel>(
      find.byKey(const ValueKey('army-total-soldier')),
    );
    final deployedWheel = tester.widget<ResourceCounterWheel>(
      find.byKey(const ValueKey('army-deployed-soldier')),
    );
    expect(totalWheel.maxValue, 99);
    // «В бой» ограничено общим числом: колёсико содержит ровно 0..total,
    // а значение не изменилось от роста общего числа.
    expect(deployedWheel.maxValue, 3);
    expect(deployedWheel.value, 0);
  });

  testWidgets('уменьшение общего числа тянет колёсико «в бой» вниз', (
    tester,
  ) async {
    final container = await _openGameScreen(tester);
    final notifier = container.read(gameSessionProvider('Тестовая').notifier);
    notifier.setArmyTotal('soldier', 5);
    notifier.setArmyDeployed('soldier', 4);
    await tester.pump();

    // Общее число падает ниже «в бой»: сессия клампит «в бой» до нового
    // общего числа, колёсико перескакивает на новую границу.
    notifier.setArmyTotal('soldier', 3);
    await tester.pump();

    final deployedWheel = tester.widget<ResourceCounterWheel>(
      find.byKey(const ValueKey('army-deployed-soldier')),
    );
    expect(deployedWheel.maxValue, 3);
    expect(deployedWheel.value, 3);
    expect(
      container.read(gameSessionProvider('Тестовая')).armyDeployed('soldier'),
      3,
    );
  });

  testWidgets('увеличение общего числа не двигает колёсико «в бой»', (
    tester,
  ) async {
    final container = await _openGameScreen(tester);
    final notifier = container.read(gameSessionProvider('Тестовая').notifier);

    // Общее число растёт с 0 до 3: «в бой» остаётся на 0 — игрок сам
    // крутит своё колёсико, оно лишь не может превысить общее число.
    notifier.setArmyTotal('soldier', 3);
    await tester.pump();

    // Колёсико «в бой» показывает значение 0 (индекс 3 при maxValue 3),
    // а не maxValue (индекс 0): позиция — 3 × 75px.
    final deployedWheel = tester.widget<ListWheelScrollView>(
      find.descendant(
        of: find.byKey(const ValueKey('army-deployed-soldier')),
        matching: find.byType(ListWheelScrollView),
      ),
    );
    expect(deployedWheel.controller!.offset, 3 * 75);

    final session = container.read(gameSessionProvider('Тестовая'));
    expect(session.armyDeployed('soldier'), 0);
    expect(find.text('Сила в бой: 0'), findsOneWidget);
  });

  testWidgets(
    '«Закончить игру» ведёт на ввод очков; «назад» оттуда — на главное меню',
    (tester) async {
      await _openGameScreen(tester);

      for (var i = 0; i < 15; i++) {
        await tester.tap(find.text('Следующий раунд'));
        await tester.pump();
      }
      await tester.tap(find.text('Закончить игру'));
      await tester.pumpAndSettle();

      expect(find.text('Ввод очков'), findsOneWidget);
      expect(find.text('Фракция: Тестовая'), findsOneWidget);

      // Тикет 18: партия уходит из стека (pushReplacement), ввод очков
      // без верхнего бара; одно системное «назад» — на главное меню,
      // вернуться в партию невозможно.
      expect(find.byType(AppBar), findsNothing);
      await simulateSystemBack();
      await tester.pumpAndSettle();

      expect(find.text('Начать игру'), findsOneWidget);
      expect(find.text('Текущий раунд: 16'), findsNothing);
      expect(find.text('Ввод очков'), findsNothing);
    },
  );

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

  testWidgets('модалка: секции «Лавка бронника» нет у фракции без апгрейда', (
    tester,
  ) async {
    await _openGameScreen(tester);

    await tester.tap(find.text('МОДИФИКАТОРЫ СИЛЫ'));
    await tester.pumpAndSettle();

    expect(find.text('Лавка бронника'), findsNothing);
  });

  testWidgets(
    '«Лавка бронника»: применение списывает дерево и меняет силу в бой',
    (tester) async {
      final container = await _openGameScreen(tester, factionName: 'Лавка');
      final notifier = container.read(gameSessionProvider('Лавка').notifier);
      notifier.setResource('Дерево', 5);
      notifier.setArmyTotal('ent', 2);
      notifier.setArmyDeployed('ent', 2);
      notifier.setArmyTotal('grifon', 1);
      notifier.setArmyDeployed('grifon', 1);
      notifier.setArmyTotal('pixi', 1);
      notifier.setArmyDeployed('pixi', 1);
      await tester.pump();

      await tester.tap(find.text('МОДИФИКАТОРЫ СИЛЫ'));
      await tester.pumpAndSettle();

      expect(find.text('Лавка бронника'), findsOneWidget);
      expect(find.text('Пикси: 1 → 2'), findsOneWidget);
      expect(find.text('Грифон: 3 → 5'), findsOneWidget);
      expect(find.text('Энт: 6 → 10'), findsOneWidget);
      expect(find.text('Эффект не применён'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('battle-upgrade-wood-add')));
      await tester.tap(find.byKey(const ValueKey('battle-upgrade-wood-add')));
      await tester.tap(find.text('Энт: 6 → 10'));
      await tester.tap(find.text('Грифон: 3 → 5'));
      await tester.pump();
      await tester.tap(find.text('Применить эффект'));
      await tester.pumpAndSettle();

      final session = container.read(gameSessionProvider('Лавка'));
      expect(session.resource('Дерево'), 3);
      expect(session.battleUpgradeActive, isTrue);
      expect(session.battleUpgradePaidWood, 2);
      expect(session.battleUpgradeSelectedUnits, ['grifon', 'ent']);
      expect(session.deployedArmyStrength, 26);
      expect(
        find.text('Эффект применён: оплачено 2 Дерево'),
        findsOneWidget,
      );

      // Живой пересчёт: сила в бой видна и за модалкой, и в секции.
      expect(find.text('Сила в бой: 26'), findsWidgets);

      // Закрытие и повторное открытие показывают применённый эффект.
      await tester.tapAt(const Offset(600, 30));
      await tester.pumpAndSettle();
      expect(find.text('Сила в бой: 26'), findsOneWidget);

      await tester.tap(find.text('МОДИФИКАТОРЫ СИЛЫ'));
      await tester.pumpAndSettle();
      expect(
        find.text('Эффект применён: оплачено 2 Дерево'),
        findsOneWidget,
      );

      // Новый раунд сбрасывает эффект и «в бой» без возврата дерева.
      await tester.tapAt(const Offset(600, 30));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Следующий раунд'));
      await tester.pump();

      final afterRound = container.read(gameSessionProvider('Лавка'));
      expect(afterRound.battleUpgradeActive, isFalse);
      expect(afterRound.battleUpgradeSelectedUnits, isEmpty);
      expect(afterRound.armyDeployed('ent'), 0);
      expect(afterRound.resource('Дерево'), 3);
      expect(find.text('Сила в бой: 0'), findsOneWidget);
      expect(find.text('Сила армии: 0'), findsOneWidget);
    },
  );

  testWidgets('«Лавка бронника»: юниты вне «в бой» недоступны для выбора', (
    tester,
  ) async {
    final container = await _openGameScreen(tester, factionName: 'Лавка');
    final notifier = container.read(gameSessionProvider('Лавка').notifier);
    notifier.setResource('Дерево', 3);
    notifier.setArmyTotal('ent', 1);
    notifier.setArmyDeployed('ent', 1);
    await tester.pump();

    await tester.tap(find.text('МОДИФИКАТОРЫ СИЛЫ'));
    await tester.pumpAndSettle();

    final pixiTile = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Пикси: 1 → 2'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(pixiTile.onChanged, isNull);

    await tester.tap(find.text('Энт: 6 → 10'));
    await tester.pump();
    expect(find.text('Применить эффект'), findsOneWidget);
  });

  testWidgets('«Лавка бронника»: лимит ограничивает выбор юнитов', (
    tester,
  ) async {
    final container = await _openGameScreen(tester, factionName: 'Лавка');
    final notifier = container.read(gameSessionProvider('Лавка').notifier);
    notifier.setResource('Дерево', 3);
    for (final unitId in ['ent', 'grifon', 'pixi']) {
      notifier.setArmyTotal(unitId, 1);
      notifier.setArmyDeployed(unitId, 1);
    }
    await tester.pump();

    await tester.tap(find.text('МОДИФИКАТОРЫ СИЛЫ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Энт: 6 → 10'));
    await tester.tap(find.text('Грифон: 3 → 5'));
    await tester.pump();

    final pixiTile = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('Пикси: 1 → 2'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(pixiTile.onChanged, isNull);
  });

  testWidgets('выход — только двойным «назад»', (tester) async {
    await _openGameScreen(tester);

    await simulateSystemBack();
    await tester.pump();

    expect(find.text('Нажмите «назад» ещё раз, чтобы выйти'), findsOneWidget);
    expect(find.text('Текущий раунд: 1'), findsOneWidget);

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('Тестовая'), findsOneWidget);
    expect(find.text('Текущий раунд: 1'), findsNothing);
  });
}
