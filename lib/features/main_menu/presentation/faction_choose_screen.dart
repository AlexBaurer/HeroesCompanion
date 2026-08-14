import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/color_hex.dart';
import '../../../domain/faction.dart';
import '../../factions/data/faction_providers.dart';

/// Экран выбора фракции: все 18 фракций одним бесшовным списком на всю
/// ширину экрана. Плитка — фон-изображение фракции из данных
/// ([Faction.backgroundPath]); без неё — сплошной цвет фракции. Имя —
/// слева по центру с обводкой краёв букв. Иммерсивный AppBar.
class FactionChooseScreen extends ConsumerWidget {
  const FactionChooseScreen({super.key});

  /// Высота плитки фракции (~120dp; пользователь может скорректировать).
  static const tileHeight = 120.0;

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
      extendBodyBehindAppBar: true,
      appBar: const _ImmersiveAppBar(),
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

/// Иммерсивный AppBar: полупрозрачная подложка, заголовок с той же
/// обводкой, что и имена на плитках, «назад» — на полупрозрачном круге.
class _ImmersiveAppBar extends StatelessWidget {
  const _ImmersiveAppBar();

  static const _scrim = Color(0x59000000);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _scrim,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: const Center(
        child: DecoratedBox(
          decoration: BoxDecoration(color: _scrim, shape: BoxShape.circle),
          child: BackButton(color: Colors.white),
        ),
      ),
      title: Text(
        'Выбери фракцию',
        style: FactionChooseScreen.strokedTextStyle(fontSize: 18),
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
/// без заголовков секций, отступов и разделителей.
class _FactionList extends StatelessWidget {
  const _FactionList({required this.factions});

  final List<Faction> factions;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Иммерсивный AppBar перекрывает верх экрана: список начинается
      // под ним, но прокручивается под полупрозрачную подложку.
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + kToolbarHeight,
      ),
      itemCount: factions.length,
      itemBuilder: (context, index) => _FactionTile(faction: factions[index]),
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
            Image.asset(
              faction.backgroundPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  ColoredBox(color: colorFromHex(faction.color)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  faction.name,
                  style: FactionChooseScreen.strokedTextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
