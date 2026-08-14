import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/session.dart';

import '../../data/game_session_provider.dart';

/// Секция «Лавка бронника» (эльфы) в модалке модификаторов: выбор
/// количества дерева и модифицируемых юнитов из «в бой», применение
/// эффекта и живой пересчёт силы в бою.
class BattleUpgradeSection extends ConsumerStatefulWidget {
  const BattleUpgradeSection({super.key, required this.factionName});

  final String factionName;

  @override
  ConsumerState<BattleUpgradeSection> createState() =>
      _BattleUpgradeSectionState();
}

class _BattleUpgradeSectionState extends ConsumerState<BattleUpgradeSection> {
  /// Локальное состояние до применения: количество дерева и выбор
  /// юнитов. Инициализируется из сессии, чтобы повторное открытие
  /// модалки не теряло уже применённый эффект.
  int _wood = 0;
  final Set<String> _selection = {};

  @override
  void initState() {
    super.initState();
    final session = ref.read(gameSessionProvider(widget.factionName));
    _wood = session.battleUpgradePaidWood;
    _selection.addAll(session.battleUpgradeSelectedUnits);
  }

  /// Сила в бой с учётом локального выбора — живой пересчёт до применения.
  int _previewBattleStrength(GameSession session, BattleUpgrade upgrade) {
    var strength = 0;
    for (final unit in session.faction.units) {
      final count = session.armyDeployed(unit.id);
      if (session.faction.armyPowerFormula == ArmyPowerFormula.nSquared) {
        strength += count * count;
        continue;
      }
      final target = upgrade.targetPowerOf(unit.id);
      final power = target != null && _selection.contains(unit.id)
          ? target
          : session.unitPower(unit.id);
      strength += count * power;
    }
    return strength;
  }

  /// Обработчик чекбокса юнита: вне «в бой» или при заполненном лимите
  /// выбор недоступен.
  ValueChanged<bool>? _unitToggleHandler(
    GameSession session,
    Unit unit,
    BattleUpgrade upgrade,
  ) {
    if (session.armyDeployed(unit.id) < 1) return null;
    if (_selection.contains(unit.id)) {
      return (_) => setState(() => _selection.remove(unit.id));
    }
    if (_selection.length >= upgrade.limit) return null;
    return (_) => setState(() => _selection.add(unit.id));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider(widget.factionName));
    final notifier = ref.read(gameSessionProvider(widget.factionName).notifier);
    final upgrade = session.faction.battleUpgrade!;
    final theme = Theme.of(context);

    final woodOnHand = session.resource(upgrade.resource);
    final paidNow = _wood - session.battleUpgradePaidWood;
    final canApply =
        _wood >= 1 && _selection.isNotEmpty && paidNow <= woodOnHand;
    final selectedUnitIds = [
      for (final unit in session.faction.units)
        if (_selection.contains(unit.id)) unit.id,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text('Лавка бронника', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Перед сражением оплатите дерево и выберите до ${upgrade.limit} '
          'боевых единиц «в бой»: их сила станет целевой на это сражение',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('${upgrade.resource}:'),
            IconButton(
              key: const ValueKey('battle-upgrade-wood-remove'),
              icon: const Icon(Icons.remove),
              onPressed: _wood <= 0 ? null : () => setState(() => _wood--),
            ),
            Text('$_wood', style: const TextStyle(fontSize: 22)),
            IconButton(
              key: const ValueKey('battle-upgrade-wood-add'),
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _wood++),
            ),
          ],
        ),
        for (final unit in session.faction.units)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${unit.name}: ${session.unitPower(unit.id)} → '
              '${upgrade.targetPowerOf(unit.id)}',
            ),
            subtitle: Text('В бою: ${session.armyDeployed(unit.id)}'),
            value: _selection.contains(unit.id),
            onChanged: _unitToggleHandler(session, unit, upgrade),
          ),
        const SizedBox(height: 8),
        Text(
          session.battleUpgradeActive
              ? 'Эффект применён: оплачено ${session.battleUpgradePaidWood} '
                    '${upgrade.resource}'
              : 'Эффект не применён',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Сила в бой: ${_previewBattleStrength(session, upgrade)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            FilledButton(
              onPressed: canApply
                  ? () => notifier.applyBattleUpgrade(
                        wood: _wood,
                        unitIds: selectedUnitIds,
                      )
                  : null,
              child: const Text('Применить эффект'),
            ),
          ],
        ),
      ],
    );
  }
}
