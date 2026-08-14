import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/faction_catalog.dart';
import 'package:heroescompanion/domain/game_record.dart';

import '../../factions/data/faction_providers.dart';
import '../data/game_record_providers.dart';

/// Экран результатов партии: игрок 1 с фракцией из партии, опциональные
/// игроки 2–4 (имя + фракция), 6 ячеек подсчёта (здания, фундаменты,
/// ресурсы, победы в сражениях, артефакты, сумма) с автоматической суммой.
/// Сохраняет запись в формате v1 и переходит к истории.
class ScoreEntryScreen extends ConsumerStatefulWidget {
  const ScoreEntryScreen({super.key, this.factionName});

  /// Фракция игрока 1 — из партии (тикет 07 передаёт через query).
  final String? factionName;

  @override
  ConsumerState<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

/// Категории подсчёта: 5 вводимых ячеек, сумма считается автоматически.
const _categoryLabels = [
  'Здания',
  'Фундаменты',
  'Ресурсы',
  'Победы в сражениях',
  'Артефакты',
];

/// Вводимые данные одного игрока: имя, 5 ячеек подсчёта и фракция
/// (для игроков 2–4; у игрока 1 она приходит из партии).
class _PlayerEntry {
  _PlayerEntry({required this.faction});

  final TextEditingController name = TextEditingController();
  final List<TextEditingController> cells = [
    for (var i = 0; i < _categoryLabels.length; i++) TextEditingController(),
  ];
  String faction;

  /// Сумма из пяти ячеек (пустые считаются нулями).
  int get total {
    var sum = 0;
    for (final cell in cells) {
      sum += int.tryParse(cell.text) ?? 0;
    }
    return sum;
  }

  void dispose() {
    name.dispose();
    for (final cell in cells) {
      cell.dispose();
    }
  }
}

class _ScoreEntryScreenState extends ConsumerState<ScoreEntryScreen> {
  late final _PlayerEntry _player1;
  late final List<_PlayerEntry> _others;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _player1 = _PlayerEntry(faction: widget.factionName ?? '');
    _others = [for (var i = 0; i < 3; i++) _PlayerEntry(faction: '')];
  }

  @override
  void dispose() {
    _player1.dispose();
    for (final entry in _others) {
      entry.dispose();
    }
    super.dispose();
  }

  /// Фракция игрока: выбранная, либо первая из каталога, если ещё не
  /// выбрана (как в v1 — `Faction.all[0]`).
  String _factionOf(_PlayerEntry entry, FactionCatalog catalog) {
    return entry.faction.isEmpty ? catalog.factions.first.name : entry.faction;
  }

  Future<void> _save(FactionCatalog catalog) async {
    if (_saving) return;
    final players = <PlayerScore>[];

    void addPlayer(_PlayerEntry entry, String faction) {
      final name = entry.name.text.trim();
      if (name.isEmpty) return;
      players.add(PlayerScore(playerName: name, score: entry.total, faction: faction));
    }

    addPlayer(_player1, _factionOf(_player1, catalog));
    for (final entry in _others) {
      addPlayer(entry, _factionOf(entry, catalog));
    }
    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя хотя бы одного игрока')),
      );
      return;
    }

    setState(() => _saving = true);
    final storage = await ref.read(gameRecordStorageProvider.future);
    await storage.add(GameRecord(dateTime: DateTime.now(), playerScores: players));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Результаты успешно сохранены')),
    );
    context.pushReplacement('/score_history');
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(factionCatalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ввод очков')),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(
          error: error,
          onRetry: () => ref.invalidate(factionCatalogProvider),
        ),
        data: (data) => _buildBody(data),
      ),
    );
  }

  Widget _buildBody(FactionCatalog catalog) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PlayerSection(
          title: 'Игрок 1',
          factionLabel: _factionOf(_player1, catalog),
          lockedFaction: true,
          entry: _player1,
          nameKey: const ValueKey('p1-name'),
          cellsKeys: [
            for (var i = 0; i < 5; i++) ValueKey('p1-cell-$i'),
          ],
          sumKey: const ValueKey('p1-sum'),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _others.length; i++) ...[
          _PlayerSection(
            title: 'Игрок ${i + 2}',
            factionLabel: _factionOf(_others[i], catalog),
            factions: catalog.factions,
            onFactionChanged: (value) {
              setState(() => _others[i].faction = value);
            },
            entry: _others[i],
            nameKey: ValueKey('p${i + 2}-name'),
            cellsKeys: [for (var j = 0; j < 5; j++) ValueKey('p${i + 2}-cell-$j')],
            sumKey: ValueKey('p${i + 2}-sum'),
            factionKey: ValueKey('p${i + 2}-faction'),
          ),
          const SizedBox(height: 12),
        ],
        Center(
          child: FilledButton(
            onPressed: _saving ? null : () => _save(catalog),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('Сохранить результаты'),
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить фракции'),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

/// Карточка игрока: имя, фракция (выбор или подпись из партии)
/// и 6 ячеек подсчёта (5 вводимых + автосумма).
class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.title,
    required this.factionLabel,
    required this.entry,
    required this.nameKey,
    required this.cellsKeys,
    required this.sumKey,
    this.lockedFaction = false,
    this.factions = const [],
    this.onFactionChanged,
    this.factionKey,
  });

  final String title;
  final String factionLabel;
  final bool lockedFaction;
  final List<Faction> factions;
  final ValueChanged<String>? onFactionChanged;
  final _PlayerEntry entry;
  final Key nameKey;
  final List<Key> cellsKeys;
  final Key sumKey;
  final Key? factionKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: nameKey,
              controller: entry.name,
              decoration: const InputDecoration(
                hintText: 'Имя игрока',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            if (lockedFaction)
              Text('Фракция: $factionLabel')
            else
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: factionKey,
                  value: factionLabel,
                  isExpanded: true,
                  items: [
                    for (final faction in factions)
                      DropdownMenuItem(
                        value: faction.name,
                        child: Text(faction.name),
                      ),
                  ],
                  onChanged: onFactionChanged == null ? null : (value) {
                    if (value != null) onFactionChanged!(value);
                  },
                ),
              ),
            const SizedBox(height: 8),
            _ScoreCells(entry: entry, cellsKeys: cellsKeys, sumKey: sumKey),
          ],
        ),
      ),
    );
  }
}

/// 6 ячеек подсчёта игрока: 5 полей ввода и автоматическая сумма —
/// две строки по 3 ячейки (здания, фундаменты, ресурсы; победы,
/// артефакты, сумма). Слушает ввод, чтобы сумма пересчитывалась.
class _ScoreCells extends StatefulWidget {
  const _ScoreCells({
    required this.entry,
    required this.cellsKeys,
    required this.sumKey,
  });

  final _PlayerEntry entry;
  final List<Key> cellsKeys;
  final Key sumKey;

  @override
  State<_ScoreCells> createState() => _ScoreCellsState();
}

class _ScoreCellsState extends State<_ScoreCells> {
  @override
  void initState() {
    super.initState();
    for (final cell in widget.entry.cells) {
      cell.addListener(_onCellChanged);
    }
  }

  @override
  void dispose() {
    for (final cell in widget.entry.cells) {
      cell.removeListener(_onCellChanged);
    }
    super.dispose();
  }

  void _onCellChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: _ScoreCell(
                  label: _categoryLabels[i],
                  controller: entry.cells[i],
                  key: widget.cellsKeys[i],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 3; i < 5; i++)
              Expanded(
                child: _ScoreCell(
                  label: _categoryLabels[i],
                  controller: entry.cells[i],
                  key: widget.cellsKeys[i],
                ),
              ),
            Expanded(
              child: _ScoreCell(
                label: 'Сумма',
                value: entry.total,
                key: widget.sumKey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ячейка подсчёта: подпись категории и поле числа, либо сумма (только
/// для чтения). Внутренний [Key] на поле — для ввода в тестах.
class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    super.key,
    required this.label,
    this.controller,
    this.value,
  }) : assert(controller != null || value != null,
            'ячейка должна быть либо полем ввода, либо суммой');

  final String label;
  final TextEditingController? controller;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (controller != null)
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
