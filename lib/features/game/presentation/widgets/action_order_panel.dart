import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heroescompanion/domain/action_order.dart';
import 'package:heroescompanion/domain/session.dart';

import '../../data/game_session_provider.dart';

/// Иконка действия (пути ассетов как в v1). Пользователь готовит
/// изображения сам; при отсутствии показывается название действия.
const actionIconPaths = <GameAction, String>{
  GameAction.wood: 'assets/wood.PNG',
  GameAction.iron: 'assets/iron.PNG',
  GameAction.gold: 'assets/gold.PNG',
  GameAction.move: 'assets/move.PNG',
  GameAction.build: 'assets/build.PNG',
};

const actionNames = <GameAction, String>{
  GameAction.wood: 'Дерево',
  GameAction.iron: 'Железо',
  GameAction.gold: 'Золото',
  GameAction.move: 'Перемещение',
  GameAction.build: 'Строительство',
};

/// Порядок действий раунда: 5 ячеек-перестановка, первые 4 получают
/// уровни 1–4, пятая — невыбранное действие. Перетаскивание применяет
/// новый порядок к сессии.
class ActionOrderPanel extends ConsumerWidget {
  const ActionOrderPanel({super.key, required this.factionName});

  final String factionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider(factionName));
    final slots = _slotsFor(session);
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex--;
        }
        final next = List<GameAction>.of(slots);
        final item = next.removeAt(oldIndex);
        next.insert(newIndex, item);
        ref
            .read(gameSessionProvider(factionName).notifier)
            .applyActionOrder(next);
      },
      children: [
        for (var i = 0; i < slots.length; i++)
          _ActionSlot(
            key: ValueKey(slots[i]),
            level: i < GameAction.values.length - 1 ? i + 1 : null,
            action: slots[i],
          ),
      ],
    );
  }

  /// Ячейки перестановки из сессии: выбранные действия по возрастанию
  /// уровня, затем невыбранные в естественном порядке. Пока порядок не
  /// задан — все 5 действий в естественном порядке (пятое — в «невыбранной»
  /// ячейке); отображаемый порядок применяется к сессии первым
  /// перетаскиванием.
  List<GameAction> _slotsFor(GameSession session) {
    final order = session.actionOrder;
    final chosen = order.chosenActions;
    final unchosen = [
      for (final action in GameAction.values)
        if (!order.isChosen(action)) action,
    ];
    return [...chosen, ...unchosen];
  }
}

class _ActionSlot extends StatelessWidget {
  const _ActionSlot({super.key, required this.level, required this.action});

  /// Уровень 1–4 или null для «невыбранной» ячейки.
  final int? level;
  final GameAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: level == null
                ? null
                : Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black)],
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.7,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Image.asset(
                      actionIconPaths[action]!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          _actionIconFallback(action),
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actionNames[action]!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _actionIconFallback(GameAction action) {
    switch (action) {
      case GameAction.wood:
        return Icons.park;
      case GameAction.iron:
        return Icons.hardware;
      case GameAction.gold:
        return Icons.monetization_on;
      case GameAction.move:
        return Icons.directions_walk;
      case GameAction.build:
        return Icons.house;
    }
  }
}
