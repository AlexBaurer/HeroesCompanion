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
/// от верха безопасной зоны (тикет 17: верхнего бара нет).
class _FactionList extends StatelessWidget {
  const _FactionList({required this.factions});

  final List<Faction> factions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: ListView.builder(
        itemCount: factions.length,
        itemBuilder: (context, index) =>
            _FactionTile(faction: factions[index]),
      ),
    );
  }
}

/// Плитка на всю ширину экрана: фон — изображение фракции (cover),
/// без ассета — сплошной цвет фракции; имя — слева по вертикали по
/// центру с обводкой краёв букв. Тап — сразу на экран партии.
class _FactionTile extends StatelessWidget {
  const _FactionTile({required this.faction});

  final Faction faction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FactionChooseScreen.tileHeight,
      width: double.infinity,
      child: InkWell(
        onTap: () => context.push('/faction/${faction.name}'),
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
    );
  }
}
