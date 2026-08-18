import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:heroescompanion/domain/faction.dart';
import 'package:heroescompanion/domain/faction_catalog.dart';
import 'package:heroescompanion/domain/game_record.dart';

import '../../factions/data/faction_providers.dart';
import '../data/game_record_providers.dart';
import 'signed_int_input_formatter.dart';
import 'widgets/load_error.dart';

/// Экран результатов партии: игрок 1 (фракция из партии) вводит 5 ячеек
/// подсчёта с автоматической суммой; игроки 2–4 — одну ячейку «Итог»
/// с прямым вводом суммы (как в v1). Тикет 21: изначально на экране две
/// секции (Игрок 1 и Игрок 2), «Добавить игрока» внизу списка добавляет
/// секции до 4 игроков (дальше кнопки нет); «Сохранить результаты»
/// закреплена сверху, вне прокрутки. Ячейки — картинки-карточки 100×100
/// из `assets/score_screen/` (без ассета — подпись с полем). Сохраняет
/// запись в формате v1 и переходит к истории. Верхнего бара нет (тикет
/// 18): заголовок «Ввод очков» — в теле экрана, системное «назад»
/// выбрасывает на главное меню.
class ScoreEntryScreen extends ConsumerStatefulWidget {
  const ScoreEntryScreen({super.key, this.factionName});

  /// Фракция игрока 1 — из партии (тикет 07 передаёт через query).
  final String? factionName;

  @override
  ConsumerState<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

/// Категории подсчёта игрока 1: 5 вводимых ячеек, сумма считается
/// автоматически.
const _categoryLabels = [
  'Здания',
  'Фундаменты',
  'Ресурсы',
  'Победы в сражениях',
  'Артефакты',
];

/// Картинки ячеек подсчёта из v1 (каталог `assets/score_screen/`
/// наполняет пользователь; без файла ячейка рисует подпись).
const _categoryAssets = [
  'assets/score_screen/buildings.PNG',
  'assets/score_screen/fundaments.PNG',
  'assets/score_screen/resources.PNG',
  'assets/score_screen/fights.PNG',
  'assets/score_screen/artifacts.PNG',
];

/// Картинка «Итог»: сумма игрока 1 и единственная ячейка игроков 2–4.
const _generalAsset = 'assets/score_screen/general.PNG';

/// Вводимые данные одного игрока: имя, ячейки подсчёта и фракция
/// (для игроков 2–4; у игрока 1 она приходит из партии).
class _PlayerEntry {
  _PlayerEntry({required this.faction, required int cellCount})
    : cells = [for (var i = 0; i < cellCount; i++) TextEditingController()];

  final TextEditingController name = TextEditingController();
  final List<TextEditingController> cells;
  String faction;

  /// Сумма ячеек игрока: у игрока 1 — автосумма пяти категорий;
  /// у игроков 2–4 — значение их единственной ячейки «Итог»
  /// (пустые считаются нулями).
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
  /// Максимум игроков на экране (тикет 21): Игрок 1 + 3 добавленных.
  static const _maxPlayers = 4;

  late final _PlayerEntry _player1;
  final List<_PlayerEntry> _others = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _player1 = _PlayerEntry(
      faction: widget.factionName ?? '',
      cellCount: _categoryLabels.length,
    );
    // Тикет 21: изначально две секции — Игрок 1 и Игрок 2; Игроки 3–4
    // добавляются кнопкой «Добавить игрока».
    _others.add(_PlayerEntry(faction: '', cellCount: 1));
  }

  @override
  void dispose() {
    _player1.dispose();
    for (final entry in _others) {
      entry.dispose();
    }
    super.dispose();
  }

  /// Можно ли добавить ещё одного игрока: секций меньше максимальных.
  bool get _canAddPlayer => _others.length < _maxPlayers - 1;

  /// «Добавить игрока»: следующая секция (Игрок 3, затем Игрок 4);
  /// при максимуме игроков кнопка не показывается.
  void _addPlayer() {
    if (!_canAddPlayer) return;
    setState(() {
      _others.add(_PlayerEntry(faction: '', cellCount: 1));
    });
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
      players.add(
        PlayerScore(playerName: name, score: entry.total, faction: faction),
      );
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
    await storage.add(
      GameRecord(dateTime: DateTime.now(), playerScores: players),
    );
    // История на экране записи кэшируется: после сохранения сбрасываем,
    // чтобы новая запись появилась при открытии истории.
    ref.invalidate(scoreHistoryProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Результаты успешно сохранены')),
    );
    context.pushReplacement('/score_history');
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(factionCatalogProvider);
    // Тикет 18: «назад» с ввода очков не ведёт на экран партии (партия
    // завершена) — одно системное нажатие отправляет на главное меню.
    // Видимой стрелки нет: верхний бар убран.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        body: SafeArea(
          child: catalog.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => LoadError(
              message: 'Не удалось загрузить фракции',
              error: error,
              onRetry: () => ref.invalidate(factionCatalogProvider),
            ),
            data: (data) => _buildBody(data),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FactionCatalog catalog) {
    // Тикет 21: заголовок и «Сохранить результаты» закреплены сверху
    // (вне прокрутки); под ними скроллится список секций игроков.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Ввод очков',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: FilledButton(
              onPressed: _saving ? null : () => _save(catalog),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Сохранить результаты'),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _PlayerSection(
                title: 'Игрок 1',
                factionLabel: _factionOf(_player1, catalog),
                lockedFaction: true,
                entry: _player1,
                nameKey: const ValueKey('p1-name'),
                cellsKeys: [for (var i = 0; i < 5; i++) ValueKey('p1-cell-$i')],
                assets: _categoryAssets,
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
                  cellsKeys: [ValueKey('p${i + 2}-cell-0')],
                  assets: const [_generalAsset],
                  factionKey: ValueKey('p${i + 2}-faction'),
                ),
                const SizedBox(height: 12),
              ],
              if (_canAddPlayer)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _addPlayer,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить игрока'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Карточка игрока: имя, фракция (выбор или подпись из партии)
/// и ячейки подсчёта.
class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.title,
    required this.factionLabel,
    required this.entry,
    required this.nameKey,
    required this.cellsKeys,
    required this.assets,
    this.sumKey,
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
  final List<String> assets;
  final Key? sumKey;
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
                  onChanged: onFactionChanged == null
                      ? null
                      : (value) {
                          if (value != null) onFactionChanged!(value);
                        },
                ),
              ),
            const SizedBox(height: 8),
            _ScoreCells(
              entry: entry,
              cellsKeys: cellsKeys,
              assets: assets,
              sumKey: sumKey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ячейки подсчёта игрока: у игрока 1 — 5 полей на картинках-карточках
/// и автоматическая сумма (две строки по 3 ячейки 100×100); у игроков
/// 2–4 — одна ячейка «Итог» с прямым вводом суммы (как в v1). Слушает
/// ввод, чтобы сумма пересчитывалась.
class _ScoreCells extends StatefulWidget {
  const _ScoreCells({
    required this.entry,
    required this.cellsKeys,
    required this.assets,
    this.sumKey,
  });

  final _PlayerEntry entry;
  final List<Key> cellsKeys;
  final List<String> assets;
  final Key? sumKey;

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
    final assets = widget.assets;
    if (assets.length == 1) {
      // Игроки 2–4: одна ячейка «Итог» вместо пяти категорий и автосуммы.
      return Center(
        child: _ScoreCell(
          key: widget.cellsKeys.single,
          label: 'Итог',
          assetPath: assets.single,
          controller: entry.cells.single,
        ),
      );
    }
    return Column(
      children: [
        _cellRow([
          for (var i = 0; i < 3; i++)
            _ScoreCell(
              key: widget.cellsKeys[i],
              label: _categoryLabels[i],
              assetPath: assets[i],
              controller: entry.cells[i],
            ),
        ]),
        const SizedBox(height: 16),
        _cellRow([
          for (var i = 3; i < 5; i++)
            _ScoreCell(
              key: widget.cellsKeys[i],
              label: _categoryLabels[i],
              assetPath: assets[i],
              controller: entry.cells[i],
            ),
          _ScoreCell(
            key: widget.sumKey,
            label: 'Сумма',
            assetPath: _generalAsset,
            value: entry.total,
          ),
        ]),
      ],
    );
  }

  /// Строка ячеек 100×100 с равными отступами: при недостатке ширины
  /// вся строка пропорционально уменьшается (FittedBox), а не ломается.
  Widget _cellRow(List<Widget> cells) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              cells[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ячейка подсчёта 100×100: картинка из `assets/score_screen/` (как в v1)
/// с полем ввода или суммой поверх нижней половины. Без файла-ассета —
/// fallback: подпись категории на фоне (errorBuilder, как у фонов фракций).
/// Поле ввода принимает только цифры и минус в начале. Внутренний [Key]
/// на ячейке — для ввода в тестах.
class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    super.key,
    required this.label,
    required this.assetPath,
    this.controller,
    this.value,
  }) : assert(
         controller != null || value != null,
         'ячейка должна быть либо полем ввода, либо суммой',
       );

  final String label;
  final String assetPath;
  final TextEditingController? controller;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 45,
            child: controller != null
                ? TextField(
                    controller: controller,
                    inputFormatters: [signedIntInputFormatter],
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                      isDense: true,
                    ),
                  )
                : Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
