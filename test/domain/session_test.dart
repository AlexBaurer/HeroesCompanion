import 'package:flutter_test/flutter_test.dart';
import 'package:heroescompanion/domain/action_order.dart';
import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/session.dart';
import 'package:heroescompanion/domain/strength_modifier.dart';

const _regularUnits = [
  Unit(id: 'soldier', name: 'Солдат', basePower: 2),
  Unit(id: 'latnik', name: 'Латник', basePower: 5),
];

Faction _faction({
  List<Unit>? units,
  List<String>? resources,
  List<StrengthModifier> modifiers = const [],
  ArmyPowerFormula armyPower = ArmyPowerFormula.perUnit,
}) {
  return Faction(
    name: 'Тестовая',
    gamePart: 1,
    color: '#000000',
    backgroundPath: 'assets/faction_background/test.png',
    resources: resources ?? const ['Дерево', 'Железо', 'Золото'],
    units: units ?? _regularUnits,
    modifiers: modifiers,
    armyPowerFormula: armyPower,
  );
}

Faction _mayaFaction() {
  return _faction(
    units: const [Unit(id: 'maya', name: 'Майя', basePower: 7)],
    modifiers: const [
      ToggleModifier(unitId: 'maya', bonusPower: 10),
      ToggleModifier(unitId: 'maya', bonusPower: 14),
    ],
  );
}

Faction _nagaFaction() {
  return _faction(
    units: const [Unit(id: 'kraken', name: 'Краки', basePower: 1)],
    modifiers: const [],
    armyPower: ArmyPowerFormula.nSquared,
  );
}

void main() {
  group('создание сессии', () {
    test('ресурсы и армия инициализируются нулями по данным фракции', () {
      final session = GameSession(faction: _faction());

      expect(session.round, 1);
      expect(session.resource('Дерево'), 0);
      expect(session.resource('Железо'), 0);
      expect(session.resource('Золото'), 0);
      expect(session.armyTotal('soldier'), 0);
      expect(session.armyTotal('latnik'), 0);
      expect(session.armyDeployed('soldier'), 0);
      expect(session.armyDeployed('latnik'), 0);
    });

    test('порядок действий пуст, модификаторы — копия данных фракции', () {
      final faction = _mayaFaction();
      final session = GameSession(faction: faction);

      expect(session.actionOrder.chosenCount, 0);
      expect(session.modifiers, hasLength(2));
      expect(session.modifiers[0], isA<ToggleModifier>());
      expect((session.modifiers[0] as ToggleModifier).isEnabled, isFalse);
      expect(session.modifiersFor('maya'), hasLength(2));
    });

    test('стартовый раунд ограничен диапазоном 1–16', () {
      expect(GameSession(faction: _faction(), round: 0).round, 1);
      expect(GameSession(faction: _faction(), round: 99).round, 16);
    });
  });

  group('ресурсы', () {
    test('setResource меняет значение', () {
      final session = GameSession(faction: _faction());

      session.setResource('Дерево', 7);

      expect(session.resource('Дерево'), 7);
    });

    test('setResource не опускает значение ниже 0', () {
      final session = GameSession(faction: _faction());

      session.setResource('Золото', -3);

      expect(session.resource('Золото'), 0);
    });
  });

  group('армия: всего и «в бой»', () {
    test('«в бой» не превышает общее число', () {
      final session = GameSession(faction: _faction());

      session.setArmyTotal('soldier', 5);
      session.setArmyDeployed('soldier', 9);

      expect(session.armyDeployed('soldier'), 5);
    });

    test('«в бой» клампится при уменьшении общего числа', () {
      final session = GameSession(faction: _faction());

      session.setArmyTotal('soldier', 5);
      session.setArmyDeployed('soldier', 4);
      session.setArmyTotal('soldier', 2);

      expect(session.armyTotal('soldier'), 2);
      expect(session.armyDeployed('soldier'), 2);
    });

    test('числа юнитов не опускаются ниже 0', () {
      final session = GameSession(faction: _faction());

      session.setArmyTotal('soldier', -2);
      session.setArmyDeployed('soldier', -1);

      expect(session.armyTotal('soldier'), 0);
      expect(session.armyDeployed('soldier'), 0);
    });
  });

  group('сила юнита', () {
    test('без модификаторов равна базовой', () {
      final session = GameSession(faction: _faction());

      expect(session.unitPower('soldier'), 2);
      expect(session.unitPower('latnik'), 5);
    });

    test('toggle: включённая ступень заменяет силу', () {
      final faction = _faction(
        modifiers: const [ToggleModifier(unitId: 'soldier', bonusPower: 3)],
      );
      final session = GameSession(faction: faction);

      expect(session.unitPower('soldier'), 2);
      session.setToggleEnabled(0, true);
      expect(session.unitPower('soldier'), 3);
      session.setToggleEnabled(0, false);
      expect(session.unitPower('soldier'), 2);
    });

    test('counter: сила = базовая + счёт × шаг', () {
      final faction = _faction(
        modifiers: const [CounterModifier(unitId: 'latnik', step: 3)],
      );
      final session = GameSession(faction: faction);

      session.setCounterCount(0, 2);

      expect(session.unitPower('latnik'), 11);
    });

    test('Майя 7 → 10 → 14: включение первой и второй ступени', () {
      final session = GameSession(faction: _mayaFaction());

      session.setToggleEnabled(0, true);
      expect(session.unitPower('maya'), 10);

      session.setToggleEnabled(1, true);
      expect(session.unitPower('maya'), 14);
    });

    test('Майя 7 → 14 при включённой только второй ступени', () {
      final session = GameSession(faction: _mayaFaction());

      session.setToggleEnabled(1, true);

      expect(session.unitPower('maya'), 14);
    });

    test('неизвестный юнит → ArgumentError', () {
      final session = GameSession(faction: _faction());

      expect(() => session.unitPower('dragon'), throwsArgumentError);
    });
  });

  group('сила армии', () {
    test('обычная фракция: Σ(количество × сила юнита)', () {
      final session = GameSession(faction: _faction());

      session.setArmyTotal('soldier', 2);
      session.setArmyTotal('latnik', 1);

      expect(session.totalArmyStrength, 9);
    });

    test('обычная фракция: сила с учётом включённых модификаторов', () {
      final faction = _faction(
        modifiers: const [ToggleModifier(unitId: 'soldier', bonusPower: 3)],
      );
      final session = GameSession(faction: faction);

      session.setArmyTotal('soldier', 2);
      expect(session.totalArmyStrength, 4);

      session.setToggleEnabled(0, true);
      expect(session.totalArmyStrength, 6);
    });

    test('сила «в бой» считает только заявленных юнитов', () {
      final session = GameSession(faction: _faction());

      session.setArmyTotal('soldier', 3);
      session.setArmyDeployed('soldier', 2);

      expect(session.deployedArmyStrength, 4);
      expect(session.totalArmyStrength, 6);
    });

    test('Наги: краки по n²', () {
      final session = GameSession(faction: _nagaFaction());

      session.setArmyTotal('kraken', 3);
      session.setArmyDeployed('kraken', 2);

      expect(session.totalArmyStrength, 9);
      expect(session.deployedArmyStrength, 4);
    });
  });

  group('раунд', () {
    test('раунд идёт 1 → 16', () {
      final session = GameSession(faction: _faction());

      for (var expected = 2; expected <= 16; expected++) {
        expect(session.advanceRound(), isFalse);
        expect(session.round, expected);
      }
      expect(session.isFinished, isFalse);
    });

    test('после 16-го раунда партия завершается', () {
      final session = GameSession(faction: _faction(), round: 16);

      expect(session.isFinished, isFalse);
      expect(session.advanceRound(), isTrue);
      expect(session.round, 16);
      expect(session.isFinished, isTrue);
    });
  });

  group('модификаторы: единый источник истины', () {
    test('изменение через сессию не меняет данные фракции', () {
      final faction = _faction(
        modifiers: const [ToggleModifier(unitId: 'soldier', bonusPower: 3)],
      );
      final session = GameSession(faction: faction);

      session.setToggleEnabled(0, true);

      expect((faction.modifiers[0] as ToggleModifier).isEnabled, isFalse);
      expect((session.modifiers[0] as ToggleModifier).isEnabled, isTrue);
      expect(session.modifiers[0], isNot(same(faction.modifiers[0])));
    });

    test('состояние сохраняется между обращениями', () {
      final faction = _faction(
        modifiers: const [CounterModifier(unitId: 'latnik', step: 1)],
      );
      final session = GameSession(faction: faction);

      session.setCounterCount(0, 4);
      expect(
        (session.modifiersFor('latnik').single as CounterModifier).count,
        4,
      );

      session.setCounterCount(0, 1);
      expect(
        (session.modifiersFor('latnik').single as CounterModifier).count,
        1,
      );
    });

    test('setToggleEnabled по индексу counter → StateError', () {
      final faction = _faction(
        modifiers: const [CounterModifier(unitId: 'latnik')],
      );
      final session = GameSession(faction: faction);

      expect(() => session.setToggleEnabled(0, true), throwsStateError);
    });
  });

  group('порядок действий', () {
    test('4 из 5 действий с уровнями 1–4, пятое пустое', () {
      final session = GameSession(faction: _faction());

      session.setActionLevel(GameAction.wood, 1);
      session.setActionLevel(GameAction.iron, 3);
      session.setActionLevel(GameAction.gold, 2);
      session.setActionLevel(GameAction.move, 4);

      expect(session.actionOrder.isComplete, isTrue);
      expect(session.actionOrder.chosenCount, 4);
      expect(session.actionOrder.levelOf(GameAction.wood), 1);
      expect(session.actionOrder.levelOf(GameAction.iron), 3);
      expect(session.actionOrder.levelOf(GameAction.gold), 2);
      expect(session.actionOrder.levelOf(GameAction.move), 4);
      expect(session.actionOrder.levelOf(GameAction.build), 0);
      expect(session.actionOrder.isChosen(GameAction.build), isFalse);
      expect(
        session.actionOrder.chosenActions,
        [GameAction.wood, GameAction.gold, GameAction.iron, GameAction.move],
      );
    });

    test('уровни выбранных действий уникальны', () {
      final order = ActionOrder.empty()
          .withLevel(GameAction.wood, 2)
          .withLevel(GameAction.iron, 3);

      expect(() => order.withLevel(GameAction.gold, 2), throwsArgumentError);
    });

    test('уровень вне 1–4 → ArgumentError', () {
      final order = ActionOrder.empty();

      expect(() => order.withLevel(GameAction.wood, 0), throwsArgumentError);
      expect(() => order.withLevel(GameAction.wood, 5), throwsArgumentError);
    });

    test('clearAction освобождает действие, уровни можно переиспользовать', () {
      final session = GameSession(faction: _faction());

      session.setActionLevel(GameAction.wood, 1);
      session.setActionLevel(GameAction.iron, 2);
      session.clearAction(GameAction.wood);

      expect(session.actionOrder.levelOf(GameAction.wood), 0);
      expect(session.actionOrder.chosenCount, 1);
      expect(session.actionOrder.isComplete, isFalse);

      session.setActionLevel(GameAction.wood, 3);
      session.setActionLevel(GameAction.gold, 1);
      session.setActionLevel(GameAction.move, 4);
      expect(session.actionOrder.isComplete, isTrue);
    });

    test('невыбранное действие пустое (уровень 0)', () {
      final order = ActionOrder.empty();

      expect(order.levelOf(GameAction.build), 0);
      expect(order.isChosen(GameAction.build), isFalse);
      expect(order.chosenActions, isEmpty);
    });
  });
}
