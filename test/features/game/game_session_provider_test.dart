import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/domain/action_order.dart';
import 'package:heroescompanion/domain/session.dart';
import 'package:heroescompanion/domain/strength_modifier.dart';
import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/features/factions/data/faction_repository.dart';
import 'package:heroescompanion/features/game/data/game_session_provider.dart';

const _factionJson = '''
{
  "name": "Тестовая",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "description": "Тестовая фракция.",
  "resources": ["Дерево", "Железо"],
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

FactionRepository _fakeRepository() {
  // loadCatalog читает все 18 файлов каталога: для любого пути отдаём
  // одну и ту же фракцию «Тестовая».
  return FactionRepository(load: (path) async => _factionJson);
}

Future<ProviderContainer> _container() async {
  final container = ProviderContainer(
    overrides: [factionRepositoryProvider.overrideWithValue(_fakeRepository())],
  );
  addTearDown(container.dispose);
  await container.read(factionCatalogProvider.future);
  return container;
}

void main() {
  group('gameSessionProvider', () {
    test('создаёт сессию по имени фракции из каталога', () async {
      final container = await _container();

      final session = container.read(gameSessionProvider('Тестовая'));

      expect(session, isA<GameSession>());
      expect(session.faction.name, 'Тестовая');
      expect(session.round, 1);
      expect(session.resource('Дерево'), 0);
      expect(session.resource('Железо'), 0);
      expect(session.armyTotal('soldier'), 0);
      expect(session.armyDeployed('latnik'), 0);
    });

    test('неизвестная фракция → ошибка провайдера', () async {
      final container = await _container();

      expect(
        () => container.read(gameSessionProvider('Несуществующая')),
        throwsStateError,
      );
    });

    test('изменения сессии уведомляют слушателей', () async {
      final container = await _container();
      var notifications = 0;
      container.listen(gameSessionProvider('Тестовая'), (_, __) {
        notifications++;
      });

      final notifier = container.read(gameSessionProvider('Тестовая').notifier);
      notifier.setResource('Дерево', 5);
      notifier.setArmyTotal('soldier', 2);
      notifier.advanceRound();

      expect(notifications, 3);
      final session = container.read(gameSessionProvider('Тестовая'));
      expect(session.resource('Дерево'), 5);
      expect(session.armyTotal('soldier'), 2);
      expect(session.round, 2);
    });

    test(
      '«в бой» клампится при уменьшении общего числа через провайдер',
      () async {
        final container = await _container();
        final notifier = container.read(
          gameSessionProvider('Тестовая').notifier,
        );

        notifier.setArmyTotal('soldier', 5);
        notifier.setArmyDeployed('soldier', 4);
        notifier.setArmyTotal('soldier', 2);

        final session = container.read(gameSessionProvider('Тестовая'));
        expect(session.armyTotal('soldier'), 2);
        expect(session.armyDeployed('soldier'), 2);
      },
    );

    test('toggle и counter модификаторы меняют силу армии', () async {
      final container = await _container();
      final notifier = container.read(gameSessionProvider('Тестовая').notifier);

      notifier.setArmyTotal('soldier', 2);
      notifier.setArmyTotal('latnik', 1);
      var session = container.read(gameSessionProvider('Тестовая'));
      expect(session.totalArmyStrength, 9);

      notifier.setToggleEnabled(0, true);
      notifier.setCounterCount(1, 2);
      session = container.read(gameSessionProvider('Тестовая'));
      // 2 солдата × 3 (toggle) + 1 латник × (5 + 2) = 6 + 7.
      expect(session.totalArmyStrength, 13);
    });

    test(
      'applyActionOrder: первые 4 ячейки — уровни 1–4, пятая пустая',
      () async {
        final container = await _container();
        final notifier = container.read(
          gameSessionProvider('Тестовая').notifier,
        );

        notifier.applyActionOrder(const [
          GameAction.wood,
          GameAction.iron,
          GameAction.gold,
          GameAction.move,
          GameAction.build,
        ]);

        final order = container
            .read(gameSessionProvider('Тестовая'))
            .actionOrder;
        expect(order.isComplete, isTrue);
        expect(order.levelOf(GameAction.wood), 1);
        expect(order.levelOf(GameAction.iron), 2);
        expect(order.levelOf(GameAction.gold), 3);
        expect(order.levelOf(GameAction.move), 4);
        expect(order.levelOf(GameAction.build), 0);
      },
    );

    test('applyActionOrder: действие в пятой ячейке не выбрано', () async {
      final container = await _container();
      final notifier = container.read(gameSessionProvider('Тестовая').notifier);

      notifier.applyActionOrder(const [
        GameAction.iron,
        GameAction.gold,
        GameAction.move,
        GameAction.build,
        GameAction.wood,
      ]);

      final order = container.read(gameSessionProvider('Тестовая')).actionOrder;
      expect(order.levelOf(GameAction.iron), 1);
      expect(order.levelOf(GameAction.wood), 0);
      expect(order.isChosen(GameAction.wood), isFalse);
      expect(order.chosenActions, [
        GameAction.iron,
        GameAction.gold,
        GameAction.move,
        GameAction.build,
      ]);
    });

    test('после 16-го раунда advanceRound завершает партию', () async {
      final container = await _container();
      final notifier = container.read(gameSessionProvider('Тестовая').notifier);

      for (var i = 0; i < 14; i++) {
        notifier.advanceRound();
      }
      expect(notifier.advanceRound(), isFalse); // 15 → 16
      expect(container.read(gameSessionProvider('Тестовая')).round, 16);
      expect(
        container.read(gameSessionProvider('Тестовая')).isFinished,
        isFalse,
      );

      expect(notifier.advanceRound(), isTrue);
      expect(
        container.read(gameSessionProvider('Тестовая')).isFinished,
        isTrue,
      );
    });

    test('модификаторы в сессии — единый источник истины', () async {
      final container = await _container();
      final notifier = container.read(gameSessionProvider('Тестовая').notifier);

      notifier.setToggleEnabled(0, true);

      final modifiers = container
          .read(gameSessionProvider('Тестовая'))
          .modifiers;
      expect(modifiers, hasLength(2));
      expect((modifiers[0] as ToggleModifier).isEnabled, isTrue);
      expect((modifiers[1] as CounterModifier).count, 0);
    });

    test('setToggleEnabled по индексу counter → StateError', () async {
      final container = await _container();
      final notifier = container.read(gameSessionProvider('Тестовая').notifier);

      expect(() => notifier.setToggleEnabled(1, true), throwsStateError);
    });
  });
}
