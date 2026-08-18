import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/color_hex.dart';
import '../../../domain/faction.dart';
import '../../factions/data/faction_providers.dart';
import 'faction_choose_screen.dart';

/// Окно фракции (тикет 19): полноэкранная страница с фоном фракции
/// (как плитка), именем с обводкой краёв букв, кратким описанием и
/// кнопкой «Начать игру». Верхнего бара нет (стиль тикетов 17/18):
/// «назад» — системное и возвращает на экран выбора фракции.
class FactionPreviewScreen extends ConsumerWidget {
  const FactionPreviewScreen({super.key, required this.factionName});

  final String factionName;

  /// Размер имени фракции в окне (крупнее, чем на плитке выбора).
  static const nameFontSize = 42.0;

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
        data: (data) {
          final faction = data.byName(factionName);
          if (faction == null) {
            return const Center(
              child: Text('Фракция не найдена в каталоге'),
            );
          }
          return _FactionPreview(faction: faction);
        },
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
            const Text('Не удалось загрузить данные фракции'),
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

/// Содержимое окна: фон на всю страницу, поверх — имя, скроллируемое
/// описание и кнопка «Начать игру».
class _FactionPreview extends StatelessWidget {
  const _FactionPreview({required this.faction});

  final Faction faction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = colorFromHex(faction.color);
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            faction.backgroundPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                ColoredBox(color: background),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  faction.name,
                  style: FactionChooseScreen.strokedTextStyle(
                    fontSize: FactionPreviewScreen.nameFontSize,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.circular(12),
                    ),
                    child: Text(
                      faction.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.pushReplacement(
                      '/faction/${faction.name}',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: background,
                      foregroundColor: contrastingForeground(background),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Начать игру'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}