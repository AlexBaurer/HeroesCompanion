import 'action_order.dart';
import 'faction.dart';
import 'strength_modifier.dart';

/// Партия как единый источник истины: раунд (1–16), ресурсы, армия
/// (общее число и «в бой»), состояния модификаторов и порядок действий.
class GameSession {
  GameSession({required this.faction, int round = 1})
      : round = _clampRound(round),
        _resources = {for (final resource in faction.resources) resource: 0},
        _armyTotal = {for (final unit in faction.units) unit.id: 0},
        _armyDeployed = {for (final unit in faction.units) unit.id: 0},
        _modifiers = List<StrengthModifier>.of(faction.modifiers);

  static const int minRound = 1;
  static const int maxRound = 16;

  static int _clampRound(int value) =>
      value < minRound ? minRound : (value > maxRound ? maxRound : value);

  final Faction faction;
  int round;

  final Map<String, int> _resources;
  final Map<String, int> _armyTotal;
  final Map<String, int> _armyDeployed;

  /// Живые состояния модификаторов — копия данных фракции, единственный
  /// источник истины состояния партии.
  final List<StrengthModifier> _modifiers;

  /// Состояние «Лавки бронника» (только для фракций с battleUpgrade):
  /// оплаченное дерево (0 — эффект не применён) и выбранные юниты.
  int _battleUpgradeWood = 0;
  final List<String> _battleUpgradeUnits = [];

  bool _finished = false;

  ActionOrder actionOrder = ActionOrder.empty();

  int resource(String name) => _resources[name] ?? 0;

  void setResource(String name, int value) {
    _resources[name] = value < 0 ? 0 : value;
  }

  int armyTotal(String unitId) => _armyTotal[unitId] ?? 0;

  int armyDeployed(String unitId) => _armyDeployed[unitId] ?? 0;

  /// Устанавливает общее число юнитов; «в бой» автоматически не превышает
  /// общего числа (клампится при уменьшении).
  void setArmyTotal(String unitId, int value) {
    final clamped = value < 0 ? 0 : value;
    _armyTotal[unitId] = clamped;
    if (armyDeployed(unitId) > clamped) {
      _armyDeployed[unitId] = clamped;
    }
  }

  /// Устанавливает число юнитов «в бой»; не превышает общего числа.
  /// Если «в бой» опускается до нуля, юнит уходит из выбора «Лавки бронника».
  void setArmyDeployed(String unitId, int value) {
    final maxDeployed = armyTotal(unitId);
    _armyDeployed[unitId] =
        value < 0 ? 0 : (value > maxDeployed ? maxDeployed : value);
    if (_armyDeployed[unitId] == 0) {
      _battleUpgradeUnits.remove(unitId);
    }
  }

  /// Живые состояния модификаторов в порядке данных фракции.
  List<StrengthModifier> get modifiers => List.unmodifiable(_modifiers);

  /// Живые состояния модификаторов юнита [unitId] в порядке данных фракции.
  List<StrengthModifier> modifiersFor(String unitId) {
    final result = <StrengthModifier>[];
    for (var i = 0; i < faction.modifiers.length; i++) {
      if (faction.modifiers[i].unitId == unitId) {
        result.add(_modifiers[i]);
      }
    }
    return result;
  }

  void setToggleEnabled(int index, bool enabled) {
    final modifier = _modifiers[index];
    if (modifier is! ToggleModifier) {
      throw StateError('модификатор по индексу $index — не toggle');
    }
    _modifiers[index] = modifier.withEnabled(enabled);
  }

  void setCounterCount(int index, int count) {
    final modifier = _modifiers[index];
    if (modifier is! CounterModifier) {
      throw StateError('модификатор по индексу $index — не counter');
    }
    _modifiers[index] = modifier.withCount(count);
  }

  /// Сила юнита: базовая с применёнными модификаторами по цепочке.
  int unitPower(String unitId) {
    final unit = faction.unitById(unitId);
    if (unit == null) {
      throw ArgumentError.value(unitId, 'unitId', 'неизвестный юнит фракции');
    }
    var power = unit.basePower;
    for (final modifier in modifiersFor(unitId)) {
      power = modifier.applyTo(power);
    }
    return power;
  }

  /// Эффект «Лавки бронника» применён на текущее сражение.
  bool get battleUpgradeActive =>
      faction.battleUpgrade != null && _battleUpgradeWood > 0;

  /// Оплаченное количество дерева за текущее сражение (0 — не оплачено).
  int get battleUpgradePaidWood => _battleUpgradeWood;

  /// Выбранные юниты «Лавки бронника» в порядке юнитов фракции.
  List<String> get battleUpgradeSelectedUnits {
    return [
      for (final unit in faction.units)
        if (_battleUpgradeUnits.contains(unit.id)) unit.id,
    ];
  }

  bool isBattleUpgraded(String unitId) =>
      battleUpgradeActive && _battleUpgradeUnits.contains(unitId);

  /// Применяет эффект «Лавки бронника»: списывает [wood] ресурса-цены
  /// (при повторном применении — разницу с уже оплаченным) и фиксирует
  /// выбор [unitIds] (не больше лимита, только из заявленных «в бой»).
  void applyBattleUpgrade({required int wood, required List<String> unitIds}) {
    final upgrade = faction.battleUpgrade;
    if (upgrade == null) {
      throw StateError('фракция «${faction.name}» без «Лавки бронника»');
    }
    if (wood < 1) {
      throw ArgumentError.value(
        wood,
        'wood',
        'нужно оплатить не меньше 1 ${upgrade.resource}',
      );
    }
    if (unitIds.isEmpty) {
      throw ArgumentError.value(unitIds, 'unitIds', 'выбор пуст');
    }
    if (unitIds.length > upgrade.limit) {
      throw ArgumentError.value(
        unitIds.length,
        'unitIds',
        'выбор больше лимита ${upgrade.limit}',
      );
    }
    final seen = <String>{};
    for (final unitId in unitIds) {
      if (faction.unitById(unitId) == null) {
        throw ArgumentError.value(unitId, 'unitId', 'неизвестный юнит фракции');
      }
      if (upgrade.targetPowerOf(unitId) == null) {
        throw ArgumentError.value(
          unitId,
          'unitId',
          'у юнита нет целевой силы в «Лавке бронника»',
        );
      }
      if (armyDeployed(unitId) < 1) {
        throw ArgumentError.value(unitId, 'unitId', 'юнит не заявлен «в бой»');
      }
      if (!seen.add(unitId)) {
        throw ArgumentError.value(unitId, 'unitId', 'юнит повторяется в выборе');
      }
    }
    final paidNow = wood - _battleUpgradeWood;
    if (paidNow > resource(upgrade.resource)) {
      throw ArgumentError.value(
        wood,
        'wood',
        'недостаточно ${upgrade.resource} на складе',
      );
    }
    _resources[upgrade.resource] = resource(upgrade.resource) - paidNow;
    _battleUpgradeWood = wood;
    _battleUpgradeUnits
      ..clear()
      ..addAll(unitIds);
  }

  /// Сбрасывает эффект «Лавки бронника» (граница сражения): выбор и
  /// оплата очищаются без возврата дерева — в следующем сражении
  /// платится снова.
  void resetBattleUpgrade() {
    _battleUpgradeWood = 0;
    _battleUpgradeUnits.clear();
  }

  /// Сила юнита в бою: целевая сила «Лавки бронника» для выбранных
  /// юнитов, иначе — обычная сила с модификаторами.
  int unitBattlePower(String unitId) {
    final upgrade = faction.battleUpgrade;
    if (upgrade != null && isBattleUpgraded(unitId)) {
      final target = upgrade.targetPowerOf(unitId);
      if (target != null) return target;
    }
    return unitPower(unitId);
  }

  int get totalArmyStrength => _armyStrength(_armyTotal, inBattle: false);

  int get deployedArmyStrength => _armyStrength(_armyDeployed, inBattle: true);

  int _armyStrength(Map<String, int> counts, {required bool inBattle}) {
    var strength = 0;
    for (final unit in faction.units) {
      final count = counts[unit.id] ?? 0;
      strength += faction.armyPowerFormula == ArmyPowerFormula.nSquared
          ? count * count
          : count * (inBattle ? unitBattlePower(unit.id) : unitPower(unit.id));
    }
    return strength;
  }

  /// Партия завершена: 16-й раунд пройден.
  bool get isFinished => _finished;

  /// Переходит к следующему раунду. Возвращает true, если партия завершена —
  /// вызов на 16-м раунде (после него игра окончена); раунд не меняется.
  /// Эффект «Лавки бронника» сбрасывается на границе сражения.
  bool advanceRound() {
    resetBattleUpgrade();
    if (round >= maxRound) {
      _finished = true;
      return true;
    }
    round++;
    return false;
  }

  void setActionLevel(GameAction action, int level) {
    actionOrder = actionOrder.withLevel(action, level);
  }

  void clearAction(GameAction action) {
    actionOrder = actionOrder.without(action);
  }
}
