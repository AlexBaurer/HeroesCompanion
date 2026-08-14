import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:heroescompanion/domain/history_sort.dart';

import '../data/game_record_providers.dart';
import '../data/game_record_storage.dart';
import 'widgets/load_error.dart';

/// Экран истории игр (тикет 09, доработка — тикет 14): записи из хранилища
/// с выбором сортировки (по дате или сумме очков, оба направления),
/// карточки-раскрытия с игроками и очками, удаление отдельной записи
/// по кнопке внутри раскрытой карточки с диалогом подтверждения, очистка
/// истории с диалогом подтверждения, системное «назад» ведёт в главное
/// меню (как в v1).
class ScoreHistoryScreen extends ConsumerStatefulWidget {
  const ScoreHistoryScreen({super.key});

  @override
  ConsumerState<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

/// Подпись варианта сортировки для меню.
String _sortLabel(HistorySort sort) {
  switch (sort) {
    case HistorySort.dateNewestFirst:
      return 'По дате, новые сверху';
    case HistorySort.dateOldestFirst:
      return 'По дате, старые сверху';
    case HistorySort.scoreDescending:
      return 'По сумме очков, больше сверху';
    case HistorySort.scoreAscending:
      return 'По сумме очков, меньше сверху';
  }
}

/// «дд.мм.гггг чч:мм», как в v1.
String _formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
      '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}

class _ScoreHistoryScreenState extends ConsumerState<ScoreHistoryScreen> {
  /// Выбранная сортировка истории: по умолчанию — новые сверху,
  /// как в тикете 09.
  HistorySort _sort = HistorySort.dateNewestFirst;

  /// Диалог подтверждения удаления одной записи: «Отмена» не трогает
  /// историю, «Удалить» стирает запись по её индексу в хранилище.
  Future<void> _confirmDelete(StoredGameRecord entry) async {
    final dateLabel = _formatDate(entry.record.dateTime);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись'),
        content: Text(
          'Вы уверены, что хотите удалить запись от $dateLabel?',
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
    await storage.removeAt(entry.index);
    ref.invalidate(scoreHistoryProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Запись удалена')),
    );
  }

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
              data: (entries) => entries.isEmpty
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<HistorySort>(
                          icon: const Icon(Icons.sort),
                          tooltip: 'Сортировка',
                          onSelected: (sort) => setState(() => _sort = sort),
                          itemBuilder: (context) => [
                            for (final sort in HistorySort.values)
                              CheckedPopupMenuItem(
                                value: sort,
                                checked: sort == _sort,
                                child: Text(_sortLabel(sort)),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Очистить историю',
                          onPressed: _confirmClear,
                        ),
                      ],
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
          data: (entries) {
            final sorted = [...entries];
            sorted.sort(
              (a, b) => historyComparator(_sort)(a.record, b.record),
            );
            if (sorted.isEmpty) return const _EmptyHistory();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final entry = sorted[index];
                return _RecordCard(
                  entry: entry,
                  onDelete: () => _confirmDelete(entry),
                );
              },
            );
          },
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

/// Карточка-раскрытие записи: дата игры и число игроков в заголовке,
/// при раскрытии — игроки с фракциями и очками и кнопка удаления записи
/// (подтверждение — на экране).
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.entry, required this.onDelete});

  final StoredGameRecord entry;
  final VoidCallback onDelete;

  static String _playersCountLabel(int count) {
    // В записи всегда 1–4 игрока (GameRecord.maxPlayers).
    return count == 1 ? '1 игрок' : '$count игрока';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = entry.record;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(
          'Игра от ${_formatDate(record.dateTime)}',
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
          // Кнопка удаления записи — внутри раскрытой карточки.
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить запись',
              color: theme.colorScheme.error,
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
