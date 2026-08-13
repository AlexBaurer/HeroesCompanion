import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heroescompanion/domain/strength_modifier.dart';

import '../../data/game_session_provider.dart';

/// Модальное окно модификаторов силы: читает и меняет модификаторы прямо
/// в сессии (единый источник истины) — закрытие окна ничего не теряет,
/// повторное открытие показывает то же состояние.
class StrengthModifiersSheet extends ConsumerWidget {
  const StrengthModifiersSheet({super.key, required this.factionName});

  final String factionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider(factionName));
    final notifier = ref.read(gameSessionProvider(factionName).notifier);
    final modifiers = session.modifiers;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Модификаторы силы (${session.faction.name})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (modifiers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('У фракции нет модификаторов')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: modifiers.length,
                    itemBuilder: (context, index) {
                      final modifier = modifiers[index];
                      final unit = session.faction.unitById(modifier.unitId);
                      return switch (modifier) {
                        ToggleModifier() => CheckboxListTile(
                          title: Text(
                            'Увеличить силу юнита (${unit?.name}): '
                            '${unit?.basePower} → ${modifier.bonusPower}',
                          ),
                          value: modifier.isEnabled,
                          onChanged: (value) =>
                              notifier.setToggleEnabled(index, value ?? false),
                        ),
                        CounterModifier() => ListTile(
                          title: Text('Увеличить силу юнита (${unit?.name})'),
                          subtitle: Text(
                            'Базовая сила: ${unit?.basePower}, '
                            'текущая: ${modifier.applyTo(unit?.basePower ?? 0)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: modifier.count <= 0
                                    ? null
                                    : () => notifier.setCounterCount(
                                        index,
                                        modifier.count - 1,
                                      ),
                              ),
                              Text(
                                '${modifier.count}',
                                style: const TextStyle(fontSize: 22),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: modifier.count >= modifier.maxCount
                                    ? null
                                    : () => notifier.setCounterCount(
                                        index,
                                        modifier.count + 1,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      };
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
