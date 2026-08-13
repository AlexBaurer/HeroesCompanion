import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heroescompanion/domain/faction_catalog.dart';

import 'faction_repository.dart';

/// Репозиторий фракций: читает JSON-ассеты из бандла приложения.
final factionRepositoryProvider = Provider<FactionRepository>((ref) {
  return FactionRepository(load: (path) => rootBundle.loadString(path));
});

/// Каталог всех 18 фракций: будущее с загрузкой из ассетов.
final factionCatalogProvider = FutureProvider<FactionCatalog>((ref) {
  return ref.watch(factionRepositoryProvider).loadCatalog();
});
