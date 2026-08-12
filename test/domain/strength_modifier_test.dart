import 'package:flutter_test/flutter_test.dart';
import 'package:heroescompanion/domain/strength_modifier.dart';

void main() {
  group('ToggleModifier', () {
    test('выключен — сила не меняется', () {
      const modifier = ToggleModifier(unitId: 'soldier', bonusPower: 3);

      expect(modifier.applyTo(2), 2);
      expect(modifier.isEnabled, isFalse);
    });

    test('включён — сила заменяется на бонусную', () {
      const modifier = ToggleModifier(unitId: 'soldier', bonusPower: 3);

      expect(modifier.withEnabled(true).applyTo(2), 3);
      expect(modifier.withEnabled(true).isEnabled, isTrue);
    });

    test('withEnabled не меняет исходный модификатор', () {
      const modifier = ToggleModifier(unitId: 'soldier', bonusPower: 3);

      modifier.withEnabled(true);

      expect(modifier.isEnabled, isFalse);
    });
  });

  group('CounterModifier', () {
    test('счёт 0 — сила не меняется', () {
      const modifier = CounterModifier(unitId: 'palach');

      expect(modifier.applyTo(0), 0);
    });

    test('сила = базовая + счёт × шаг', () {
      const modifier = CounterModifier(unitId: 'dzazir', step: 3, count: 2);

      expect(modifier.applyTo(0), 6);
    });

    test('шаг по умолчанию 1', () {
      const modifier = CounterModifier(unitId: 'palach', count: 3);

      expect(modifier.applyTo(0), 3);
    });

    test('withCount ограничивает счёт сверху maxCount', () {
      const modifier = CounterModifier(unitId: 'palach', maxCount: 5);

      expect(modifier.withCount(9).count, 5);
    });

    test('withCount не опускает счёт ниже 0', () {
      const modifier = CounterModifier(unitId: 'palach');

      expect(modifier.withCount(-2).count, 0);
    });

    test('withCount не меняет исходный модификатор', () {
      const modifier = CounterModifier(unitId: 'palach', count: 1);

      modifier.withCount(4);

      expect(modifier.count, 1);
    });
  });

  group('цепочки модификаторов одного юнита', () {
    test('Майя 7 → 10 → 14: включение по очереди', () {
      const first = ToggleModifier(unitId: 'maya', bonusPower: 10);
      const second = ToggleModifier(unitId: 'maya', bonusPower: 14);

      final power = [first, first.withEnabled(true), second.withEnabled(true)]
          .fold<int>(7, (current, modifier) => modifier.applyTo(current));

      expect(power, 14);
    });

    test('Майя 7 → 14 при включённой второй ступени без первой', () {
      const first = ToggleModifier(unitId: 'maya', bonusPower: 10);
      const second = ToggleModifier(unitId: 'maya', bonusPower: 14);

      final power = [first, second.withEnabled(true)]
          .fold<int>(7, (current, modifier) => modifier.applyTo(current));

      expect(power, 14);
    });

    test('Майя 7 → 10 при включённой только первой ступени', () {
      const first = ToggleModifier(unitId: 'maya', bonusPower: 10);
      const second = ToggleModifier(unitId: 'maya', bonusPower: 14);

      final power = [first.withEnabled(true), second]
          .fold<int>(7, (current, modifier) => modifier.applyTo(current));

      expect(power, 10);
    });
  });
}
