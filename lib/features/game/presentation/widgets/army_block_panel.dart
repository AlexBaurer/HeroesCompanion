import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heroescompanion/app/color_hex.dart';
import 'package:heroescompanion/domain/faction.dart';

import '../../data/game_session_provider.dart';
import 'resource_counter_wheel.dart';

/// Панель армии: сила армии и сила «в бой» (сверху) и лента юнитов —
/// изображение, счётчик «всего» и счётчик «в бой».
///
/// У фракций с [Faction.uniqueUnits] (Гриболюды) счётчиков нет: вместо
/// ленты — сетка 4 ряда × 3 колонки, тап по карточке заявляет юнита
/// «в бой» (0/1) и подсвечивает его; бейдж «Сила армии» не показывается.
///
/// Все значения читаются из сессии (единый источник истины); сила
/// пересчитывается при каждом изменении счётчиков или модификаторов.
class ArmyBlockPanel extends ConsumerWidget {
  const ArmyBlockPanel({super.key, required this.factionName});

  final String factionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider(factionName));
    final faction = session.faction;
    final uniqueUnits = faction.uniqueUnits;
    return Container(
      height: uniqueUnits ? 380 : 210,
      decoration: BoxDecoration(
        color: colorFromHex(faction.color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!uniqueUnits)
                  _StrengthBadge(
                    label: 'Сила армии: ${session.totalArmyStrength}',
                    faction: faction,
                  ),
                _StrengthBadge(
                  label: 'Сила в бой: ${session.deployedArmyStrength}',
                  faction: faction,
                ),
              ],
            ),
          ),
          Expanded(
            child: uniqueUnits
                ? _UniqueUnitsGrid(factionName: factionName)
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final unit in faction.units)
                        _UnitCard(factionName: factionName, unit: unit),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Сетка 4 ряда × 3 колонки уникальных юнитов (Гриболюды): карточки в
/// порядке данных фракции, тап заявляет юнита «в бой» и подсвечивает его,
/// повторный тап снимает заявку. Счётчиков «всего»/«в бой» нет.
class _UniqueUnitsGrid extends ConsumerWidget {
  const _UniqueUnitsGrid({required this.factionName});

  final String factionName;

  static const _spacing = 8.0;
  static const _cellHeight = 76.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faction = ref.watch(gameSessionProvider(factionName)).faction;
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - _spacing * 2) / 3;
          return Wrap(
            key: const ValueKey('unique-units-grid'),
            spacing: _spacing,
            runSpacing: _spacing,
            children: [
              for (final unit in faction.units)
                SizedBox(
                  width: cellWidth,
                  height: _cellHeight,
                  child: _UniqueUnitCard(factionName: factionName, unit: unit),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Карточка уникального юнита: картинка (или серая плашка с именем) и
/// подпись. Выбранный юнит обводится цветом фракции и получает галочку.
class _UniqueUnitCard extends ConsumerWidget {
  const _UniqueUnitCard({required this.factionName, required this.unit});

  final String factionName;
  final Unit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider(factionName));
    final notifier = ref.read(gameSessionProvider(factionName).notifier);
    final selected = session.armyDeployed(unit.id) == 1;
    final accent = colorFromHex(session.faction.color);
    return GestureDetector(
      key: ValueKey('unique-unit-${unit.id}'),
      onTap: () => notifier.toggleDeployed(unit.id),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _UnitImage(unit: unit, fontSize: 11),
                    if (selected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          Icons.check_circle,
                          color: accent,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            unit.name,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Картинка юнита из ассета `assets/units/<id>.PNG`; при отсутствии
/// ассета (или в тестах) — серая плашка с именем юнита.
class _UnitImage extends StatelessWidget {
  const _UnitImage({required this.unit, this.fontSize = 12});

  final Unit unit;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/units/${unit.id}.PNG',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color.fromARGB(60, 226, 226, 226),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Text(
          unit.name,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}

class _StrengthBadge extends StatelessWidget {
  const _StrengthBadge({required this.label, required this.faction});

  final String label;
  final Faction faction;

  @override
  Widget build(BuildContext context) {
    final background = colorFromHex(faction.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: contrastingForeground(background),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _UnitCard extends ConsumerWidget {
  const _UnitCard({required this.factionName, required this.unit});

  final String factionName;
  final Unit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider(factionName));
    final notifier = ref.read(gameSessionProvider(factionName).notifier);
    return SizedBox(
      width: 118,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _UnitImage(unit: unit),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        children: [
                          ResourceCounterWheel(
                            key: ValueKey('army-total-${unit.id}'),
                            value: session.armyTotal(unit.id),
                            onValueChanged: (value) =>
                                notifier.setArmyTotal(unit.id, value),
                            heightOfWheel: 82,
                            fontSize: 38,
                          ),
                          ResourceCounterWheel(
                            key: ValueKey('army-deployed-${unit.id}'),
                            value: session.armyDeployed(unit.id),
                            onValueChanged: (value) =>
                                notifier.setArmyDeployed(unit.id, value),
                            // «В бой» не может превысить общее число юнита:
                            // колёсико содержит только значения 0..total.
                            maxValue: session.armyTotal(unit.id),
                            heightOfWheel: 48,
                            fontSize: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              unit.name,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
