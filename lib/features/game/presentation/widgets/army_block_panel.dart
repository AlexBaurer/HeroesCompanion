import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heroescompanion/app/color_hex.dart';
import 'package:heroescompanion/domain/faction.dart';

import '../../data/game_session_provider.dart';
import 'resource_counter_wheel.dart';

/// Панель армии: сила армии и сила «в бой» (сверху) и горизонтальная
/// лента юнитов — изображение, счётчик «всего» и счётчик «в бой».
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
    return Container(
      height: 210,
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
            child: ListView(
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
                    Image.asset(
                      'assets/units/${unit.id}.PNG',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color.fromARGB(60, 226, 226, 226),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          unit.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        children: [
                          ResourceCounterWheel(
                            value: session.armyTotal(unit.id),
                            onValueChanged: (value) =>
                                notifier.setArmyTotal(unit.id, value),
                            heightOfWheel: 82,
                            fontSize: 38,
                          ),
                          ResourceCounterWheel(
                            value: session.armyDeployed(unit.id),
                            onValueChanged: (value) =>
                                notifier.setArmyDeployed(unit.id, value),
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
