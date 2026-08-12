sealed class StrengthModifier {
  const StrengthModifier({required this.unitId});

  final String unitId;

  int applyTo(int power);
}

final class ToggleModifier extends StrengthModifier {
  const ToggleModifier({
    required super.unitId,
    required this.bonusPower,
    this.isEnabled = false,
  });

  final int bonusPower;
  final bool isEnabled;

  @override
  int applyTo(int power) => isEnabled ? bonusPower : power;

  ToggleModifier withEnabled(bool value) => ToggleModifier(
        unitId: unitId,
        bonusPower: bonusPower,
        isEnabled: value,
      );
}

final class CounterModifier extends StrengthModifier {
  const CounterModifier({
    required super.unitId,
    this.step = 1,
    this.maxCount = 99,
    this.count = 0,
  });

  final int step;
  final int maxCount;
  final int count;

  @override
  int applyTo(int power) => power + count * step;

  CounterModifier withCount(int value) => CounterModifier(
        unitId: unitId,
        step: step,
        maxCount: maxCount,
        count: value < 0 ? 0 : (value > maxCount ? maxCount : value),
      );
}
