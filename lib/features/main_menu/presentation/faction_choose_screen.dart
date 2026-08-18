import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/color_hex.dart';
import '../../../domain/faction.dart';
import '../../factions/data/faction_providers.dart';

/// Экран выбора фракции: все 18 фракций одним бесшовным списком на всю
/// ширину экрана. Плитка — фон-изображение фракции из данных
/// ([Faction.backgroundPath]); без неё — сплошной цвет фракции. Имя —
/// слева по центру с обводкой краёв букв. Верхнего бара нет (тикет 17):
/// навигация назад — системная, плитки начинаются от верха безопасной
/// зоны статус-бара.
class FactionChooseScreen extends ConsumerWidget {
  const FactionChooseScreen({super.key});

  /// Высота плитки фракции (~120dp; пользователь может скорректировать).
  static const tileHeight = 120.0;

  /// Размер имени фракции на плитке (20sp × 2 по запросу пользователя).
  static const tileNameFontSize = 50.0;

  /// Сдвиг фоновой картинки плитки по вертикали в пикселях (положительный —
  /// вниз, отрицательный — вверх). Картинка-подложка рисуется с запасом по
  /// высоте, поэтому сдвиг не открывает края плитки.
  static const backgroundShiftY = 60.0;

  /// Запас высоты фоновой картинки выше и ниже плитки, чтобы сдвиг
  /// [backgroundShiftY] не открывал край плитки.
  static const _backgroundOverflow = 80.0;

  /// Обводка краёв букв: у TextStyle нет нативного stroke, поэтому
  /// рисуются 4 тени по сторонам (тикет 12).
  static TextStyle strokedTextStyle({double fontSize = 20}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: const [
        Shadow(color: Colors.black, offset: Offset(2, 0)),
        Shadow(color: Colors.black, offset: Offset(-2, 0)),
        Shadow(color: Colors.black, offset: Offset(0, 2)),
        Shadow(color: Colors.black, offset: Offset(0, -2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(factionCatalogProvider);
    return Scaffold(
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(
          error: error,
          onRetry: () => ref.invalidate(factionCatalogProvider),
        ),
        data: (data) => _FactionList(factions: data.factions),
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

/// Один скролл, все 18 фракций подряд в порядке каталога (части 1→3),
/// без заголовков секций, отступов и разделителей. Плитки начинаются
/// от верха безопасной зоны (тикет 17: верхнего бара нет). Раскрыта
/// может быть одна плитка (тикет 22): тап по плитке раскрывает под ней
/// описание и «Выбрать», тап по другой — переключает, повторный —
/// сворачивает.
class _FactionList extends StatefulWidget {
  const _FactionList({required this.factions});

  final List<Faction> factions;

  @override
  State<_FactionList> createState() => _FactionListState();
}

class _FactionListState extends State<_FactionList> {
  /// Имя раскрытой фракции; null — все плитки свёрнуты.
  String? _expandedFaction;

  void _toggle(String name) {
    setState(() {
      _expandedFaction = _expandedFaction == name ? null : name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: ListView.builder(
        itemCount: widget.factions.length,
        itemBuilder: (context, index) {
          final faction = widget.factions[index];
          return _FactionTile(
            faction: faction,
            expanded: _expandedFaction == faction.name,
            onTap: () => _toggle(faction.name),
          );
        },
      ),
    );
  }
}

/// Плитка на всю ширину экрана: фон — изображение фракции (cover),
/// без ассета — сплошной цвет фракции; имя — слева по вертикали по
/// центру с обводкой краёв букв. Тап раскрывает под плиткой панель
/// с описанием и «Выбрать» (тикет 22); раскрытая плитка раздвигает
/// следующие за ней вниз.
class _FactionTile extends StatelessWidget {
  const _FactionTile({
    required this.faction,
    required this.expanded,
    required this.onTap,
  });

  final Faction faction;

  /// Плитка раскрыта: под ней показана панель с описанием.
  final bool expanded;

  /// Тап по плитке: раскрыть (если свёрнута) или свернуть (если раскрыта).
  final VoidCallback onTap;

  /// Продолжительность анимации раздвижения плитки.
  static const _expandDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: FactionChooseScreen.tileHeight,
          width: double.infinity,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Фон с запасом по вертикали: сдвиг картинки (backgroundShiftY)
                // не открывает края плитки — край уходит за пределы клипа.
                Positioned(
                  top:
                      FactionChooseScreen.backgroundShiftY -
                      FactionChooseScreen._backgroundOverflow,
                  left: 0,
                  right: 0,
                  height:
                      FactionChooseScreen.tileHeight +
                      2 * FactionChooseScreen._backgroundOverflow,
                  child: Image.asset(
                    faction.backgroundPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: colorFromHex(faction.color)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      faction.name,
                      style: FactionChooseScreen.strokedTextStyle(
                        fontSize: FactionChooseScreen.tileNameFontSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Панель описания раскрывается под плиткой с анимацией высоты:
        // свернутая плитка не занимает места (SizedBox.shrink), раскрытая
        // раздвигает следующие за ней плитки вниз. AnimatedSize растянут
        // на всю ширину: иначе колонка даёт ему свободную ширину и он
        // анимирует и её (0 → ширина) — картинка росла бы из центра
        // в стороны, а не сверху вниз.
        SizedBox(
          width: double.infinity,
          child: AnimatedSize(
            duration: _expandDuration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? _ExpandedPanel(faction: faction)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Панель раскрытой плитки: под плиткой — полноширинная полоса, где
/// продолжение фоновой картинки плитки резко (за [_fadeHeight] пикселей)
/// гаснет в белый, затем — белая поверхность с описанием фракции и
/// кнопкой «Выбрать» (цвет фракции, контрастный текст). Стиль кнопки —
/// как у окна фракции (тикет 19), подпись «Начать игру» заменена на
/// «Выбрать» (тикет 22).
class _ExpandedPanel extends StatelessWidget {
  const _ExpandedPanel({required this.faction});

  final Faction faction;

  /// Высота полосы перехода: картинка гаснет в белый очень резко.
  static const _fadeHeight = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = colorFromHex(faction.color);
    // Белый, в который уходит картинка: непрозрачная поверхность, чтобы
    // сквозь панель ничего не просвечивало (без видимого отделения).
    final white = theme.colorScheme.surface;
    return Column(
      children: [
        // Полноширинная полоса перехода: тот же кадр картинки, что и на
        // плитке (тот же сдвиг и запас), сдвинутый вниз на высоту плитки;
        // градиент гасит её в белый за [_fadeHeight] пикселей.
        SizedBox(
          height: _fadeHeight,
          child: Stack(
            children: [
              Positioned(
                top:
                    FactionChooseScreen.backgroundShiftY -
                    FactionChooseScreen._backgroundOverflow -
                    FactionChooseScreen.tileHeight,
                left: 0,
                right: 0,
                height:
                    FactionChooseScreen.tileHeight +
                    2 * FactionChooseScreen._backgroundOverflow,
                child: Image.asset(
                  faction.backgroundPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      ColoredBox(color: background),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  // Ключ — для виджет-тестов: полоса перехода одна,
                  // остальные DecoratedBox'ы (кнопки) — из Material.
                  key: const ValueKey('faction-fade'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, white],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faction.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/faction/${faction.name}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: background,
                    foregroundColor: contrastingForeground(background),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Выбрать'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
