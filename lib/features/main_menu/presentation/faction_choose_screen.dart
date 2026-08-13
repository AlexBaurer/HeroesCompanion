import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/color_hex.dart';
import '../../../domain/faction.dart';
import '../../../domain/faction_catalog.dart';
import '../../factions/data/faction_providers.dart';

class FactionChooseScreen extends ConsumerWidget {
  const FactionChooseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(factionCatalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Выбери фракцию')),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(
          error: error,
          onRetry: () => ref.invalidate(factionCatalogProvider),
        ),
        data: (data) => _FactionSections(catalog: data),
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

/// 18 фракций, сгруппированных по частям игры (3 секции по 6).
class _FactionSections extends StatelessWidget {
  const _FactionSections({required this.catalog});

  final FactionCatalog catalog;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final buttonWidth = (constraints.maxWidth - gap) / 2;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final part in catalog.gameParts) ...[
              Text(
                'Часть $part',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final faction in catalog.factionsOf(part))
                    _FactionButton(
                      faction: faction,
                      width: buttonWidth,
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _FactionButton extends StatelessWidget {
  const _FactionButton({required this.faction, required this.width});

  final Faction faction;
  final double width;

  @override
  Widget build(BuildContext context) {
    final background = colorFromHex(faction.color);
    return SizedBox(
      width: width,
      height: 64,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: contrastingForeground(background),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        onPressed: () => context.push('/faction/${faction.name}'),
        child: Text(faction.name, textAlign: TextAlign.center),
      ),
    );
  }
}
