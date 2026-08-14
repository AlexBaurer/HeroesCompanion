import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:heroescompanion/app/color_hex.dart';
import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/session.dart';

import '../../factions/data/faction_providers.dart';
import '../data/game_session_provider.dart';
import 'widgets/action_order_panel.dart';
import 'widgets/army_block_panel.dart';
import 'widgets/resource_counter_wheel.dart';
import 'widgets/strength_modifiers_sheet.dart';

/// Экран партии: фон фракции, панель армии, ресурсы, порядок действий,
/// модификаторы силы и раунд (1–16). Верхнего бара нет (тикет 17): имя
/// фракции — в теле экрана над строкой раунда. Выход — только двойным
/// «назад».
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.factionName});

  final String factionName;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  static const _backThreshold = Duration(seconds: 2);

  DateTime? _lastBackPressed;

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;
    final now = DateTime.now();
    final last = _lastBackPressed;
    if (last != null && now.difference(last) <= _backThreshold) {
      // Navigator.pop (не maybePop) — принудительный выход: PopScope
      // с canPop: false блокирует системное «назад», но не нажатия
      // из кода.
      Navigator.of(context).pop();
      return;
    }
    _lastBackPressed = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Нажмите «назад» ещё раз, чтобы выйти'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(factionCatalogProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        body: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _LoadError(
            error: error,
            onRetry: () => ref.invalidate(factionCatalogProvider),
          ),
          data: (data) {
            final faction = data.byName(widget.factionName);
            if (faction == null) {
              return const _UnknownFaction();
            }
            return _GameView(factionName: widget.factionName);
          },
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить данные фракции'),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

/// Неизвестная фракция (например, ручной переход по ссылке): сообщение
/// вместо краша (исправление бага v1).
class _UnknownFaction extends StatelessWidget {
  const _UnknownFaction();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Фракция не найдена в каталоге'),
      ),
    );
  }
}

class _GameView extends ConsumerWidget {
  const _GameView({required this.factionName});

  final String factionName;

  void _openModifiers(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StrengthModifiersSheet(factionName: factionName),
    );
  }

  void _finishGame(BuildContext context, WidgetRef ref) {
    // Партия завершена: модель фиксирует завершение (advanceRound на
    // 16-м раунде), затем переход к вводу очков.
    ref.read(gameSessionProvider(factionName).notifier).advanceRound();
    context.push('/score?faction=${Uri.encodeQueryComponent(factionName)}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider(factionName));
    final faction = session.faction;
    final theme = Theme.of(context);
    final finished = session.round >= GameSession.maxRound;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                faction.backgroundPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Партия: $factionName',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Текущий раунд: ${session.round}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 200,
                      child: _RoundButton(
                        faction: faction,
                        finished: finished,
                        onPressed: finished
                            ? () => _finishGame(context, ref)
                            : () => ref
                                  .read(
                                    gameSessionProvider(factionName).notifier,
                                  )
                                  .advanceRound(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ArmyBlockPanel(factionName: factionName),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: FilledButton(
                      onPressed: () => _openModifiers(context),
                      child: const Text('МОДИФИКАТОРЫ СИЛЫ'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(
                      'Ресурсы',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Порядок действий',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            for (final resource in faction.resources)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: [
                                    ResourceCounterWheel(
                                      value: session.resource(resource),
                                      onValueChanged: (value) => ref
                                          .read(
                                            gameSessionProvider(
                                              factionName,
                                            ).notifier,
                                          )
                                          .setResource(resource, value),
                                      iconPath: resourceIconPaths[resource],
                                    ),
                                    // Ресурсы без иконки подписываются
                                    // названием, чтобы их можно было отличить.
                                    if (resourceIconPaths[resource] == null)
                                      Text(
                                        resource,
                                        style: theme.textTheme.labelSmall,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ActionOrderPanel(factionName: factionName),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.faction,
    required this.finished,
    required this.onPressed,
  });

  final Faction faction;
  final bool finished;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = colorFromHex(faction.color);
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: finished
            ? Theme.of(context).colorScheme.error
            : background,
        foregroundColor: finished
            ? Theme.of(context).colorScheme.onError
            : contrastingForeground(background),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      child: Text(finished ? 'Закончить игру' : 'Следующий раунд'),
    );
  }
}
