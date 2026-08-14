import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'app/orientation_lock.dart';
import 'features/scores/data/game_record_migration.dart';
import 'features/scores/data/game_record_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Тикет 15: фиксация портретной ориентации до стартовой загрузки;
  // на уровне системы дублируется в AndroidManifest.xml.
  await lockPortraitOrientation();
  // Первая партия (тикет 10): перенос записей v1 из `score_records`
  // до старта приложения; при сбое приложение всё равно запускается,
  // миграция повторится при следующем запуске (флаг не установлен).
  try {
    final prefs = await SharedPreferences.getInstance();
    await GameRecordMigration(
      preferences: SharedPreferencesAdapter(instance: prefs),
    ).migrateIfNeeded();
  } catch (error) {
    debugPrint('Не удалось мигрировать записи v1: $error');
  }
  runApp(const ProviderScope(child: HeroesCompanionApp()));
}

class HeroesCompanionApp extends StatelessWidget {
  const HeroesCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Герои — Помощник',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
