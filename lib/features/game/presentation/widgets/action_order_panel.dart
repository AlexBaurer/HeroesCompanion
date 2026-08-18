import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heroescompanion/domain/action_order.dart';
import 'package:heroescompanion/domain/session.dart';

import '../../data/game_session_provider.dart';

/// Иконка действия (пути ассетов как в v1). Пользователь готовит
/// изображения сам; при отсутствии показывается иконка действия.
const actionIconPaths = <GameAction, String>{
  GameAction.wood: 'assets/wood.PNG',
  GameAction.iron: 'assets/iron.PNG',
  GameAction.gold: 'assets/gold.PNG',
  GameAction.move: 'assets/move.PNG',
  GameAction.build: 'assets/build.PNG',
};

/// Порядок действий раунда в стиле v1: 5 ячеек-карточек только с картинкой
/// действия, номера уровней 1–4 фиксированным слоем поверх списка слева
/// (пятая ячейка — невыбранное действие, без номера). Перетаскивание
/// применяет новый порядок к сессии; при зажатии ячейка подсвечивается
/// зелёным свечением.
class ActionOrderPanel extends ConsumerWidget {
  const ActionOrderPanel({super.key, required this.factionName});

  final String factionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider(factionName));
    final slots = _slotsFor(session);
    return Stack(
      children: [
        ReorderableListView(
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
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? child) {
                    final animValue = Curves.easeInOut.transform(
                      animation.value,
                    );
                    return Transform.scale(
                      scale: 1.0 + animValue * 0.05,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4CAF50,
                              ).withValues(alpha: 0.7),
                              blurRadius: 8.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
          children: [
            for (final action in slots)
              _ActionSlot(key: ValueKey(action), action: action),
          ],
        ),
        // Номера уровней 1–4 поверх списка, как в v1 (карточка 55px +
        // вертикальные отступы 6px = шаг 67px); пятая ячейка номера
        // не получает.
        for (var i = 0; i < slots.length - 1; i++)
          Positioned(
            left: 20,
            top: 10.0 + i * 67.0,
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset.zero,
                    blurRadius: 20,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
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

/// Ячейка порядка действий в стиле v1: карточка с картинкой действия
/// по центру плитки (~32px); при отсутствии ассета — иконка действия.
class _ActionSlot extends StatelessWidget {
  const _ActionSlot({super.key, required this.action});

  final GameAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      borderOnForeground: false,
      child: SizedBox(
        height: 55,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              actionIconPaths[action]!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                _actionIconFallback(action),
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ),
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
