import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:heroescompanion/domain/game_record.dart';

import '../data/game_record_providers.dart';
import 'widgets/load_error.dart';

/// Экран истории игр (тикет 09): записи из хранилища, новые сверху,
/// карточки-раскрытия с игроками и очками, очистка истории с диалогом
/// подтверждения, системное «назад» ведёт в главное меню (как в v1).
class ScoreHistoryScreen extends ConsumerStatefulWidget {
  const ScoreHistoryScreen({super.key});

  @override
  ConsumerState<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends ConsumerState<ScoreHistoryScreen> {
  /// Диалог подтверждения очистки: «Отмена» не трогает историю,
  /// «Удалить» стирает все записи.
  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text(
          'Вы уверены, что хотите удалить всю историю результатов?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Удалить',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final storage = await ref.read(gameRecordStorageProvider.future);
    await storage.clear();
    ref.invalidate(scoreHistoryProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('История очищена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(scoreHistoryProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // «Назад» всегда возвращает в главное меню, как в v1.
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('История игр'),
          actions: [
            history.when(
              data: (records) => records.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Очистить историю',
                      onPressed: _confirmClear,
                    ),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
        body: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => LoadError(
            message: 'Не удалось загрузить историю игр',
            error: error,
            onRetry: () => ref.invalidate(scoreHistoryProvider),
          ),
          data: (records) => records.isEmpty
              ? const _EmptyHistory()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) =>
                      _RecordCard(record: records[index]),
                ),
        ),
      ),
    );
  }
}

/// Пустое состояние: значок и подсказка, как в v1.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: hintColor),
            const SizedBox(height: 16),
            Text(
              'История пуста',
              style: theme.textTheme.titleLarge?.copyWith(color: hintColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Сохраните результаты игры, чтобы они появились здесь',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка-раскрытие записи: дата игры и число игроков; при раскрытии —
/// игроки с фракциями и очками.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final GameRecord record;

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  /// «дд.мм.гггг чч:мм», как в v1.
  String get _dateLabel {
    final date = record.dateTime;
    return '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year} '
        '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  static String _playersCountLabel(int count) {
    // В записи всегда 1–4 игрока (GameRecord.maxPlayers).
    return count == 1 ? '1 игрок' : '$count игрока';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          'Игра от $_dateLabel',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(_playersCountLabel(record.playerScores.length)),
        children: [
          for (final player in record.playerScores)
            ListTile(
              title: Text(
                '${player.playerName} (${player.faction})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '${player.score}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
