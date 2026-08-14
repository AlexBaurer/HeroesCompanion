import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/app/app_router.dart';
import 'package:heroescompanion/domain/game_record.dart';
import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/features/factions/data/faction_repository.dart';
import 'package:heroescompanion/features/scores/data/game_record_migration.dart';
import 'package:heroescompanion/features/scores/data/game_record_providers.dart';
import 'package:heroescompanion/features/scores/data/game_record_storage.dart';
import 'package:heroescompanion/features/scores/presentation/score_history_screen.dart';
import 'package:heroescompanion/main.dart';

import '../../helpers/fake_preferences.dart';
import '../../helpers/v1_records.dart';

String _factionJson(int index) {
  return '''
{
  "name": "${index == 0 ? 'Тестовая' : 'Тестовая $index'}",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "resources": ["Дерево"],
  "units": [{"id": "u$index", "name": "Юнит", "power": 1}]
}
''';
}

FactionRepository _fakeRepository() {
  final byPath = {
    for (var i = 0; i < FactionRepository.factionFiles.length; i++)
      '${FactionRepository.assetPrefix}${FactionRepository.factionFiles[i]}':
          _factionJson(i),
  };
  return FactionRepository(load: (path) async => byPath[path]!);
}

PlayerScore _player(String name, int score, String faction) =>
    PlayerScore(playerName: name, score: score, faction: faction);

GameRecord _record({DateTime? dateTime, List<PlayerScore>? players}) {
  return GameRecord(
    dateTime: dateTime ?? DateTime(2026, 8, 12, 18, 30),
    playerScores: players ?? [_player('Иван', 42, 'Майя')],
  );
}

Future<ProviderContainer> _openHistoryScreen(
  WidgetTester tester, {
  required GameRecordStorage storage,
}) async {
  final container = ProviderContainer(
    overrides: [
      factionRepositoryProvider.overrideWithValue(_fakeRepository()),
      gameRecordStorageProvider.overrideWith((ref) => storage),
    ],
  );
  addTearDown(container.dispose);

  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // appRouter глобальный: сбрасываем на главное меню перед новым деревом.
  appRouter.go('/');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const HeroesCompanionApp(),
    ),
  );
  appRouter.go('/score_history');
  await tester.pumpAndSettle();
  return container;
}

/// Симулирует системное «назад» (как в тестах Flutter framework):
/// платформенное сообщение popRoute по каналу навигации — полный путь
/// через RootBackButtonDispatcher (go_router) → RouterDelegate.popRoute →
/// maybePop → PopScope.
Future<void> _simulateSystemBack() {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.navigation.name,
        const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'method': 'popRoute',
        }),
        (ByteData? _) {},
      );
}

void main() {
  testWidgets('пустая история: подсказка и нет кнопки очистки', (
    tester,
  ) async {
    await _openHistoryScreen(
      tester,
      storage: GameRecordStorage(preferences: FakePreferences()),
    );

    expect(find.text('История пуста'), findsOneWidget);
    expect(
      find.text('Сохраните результаты игры, чтобы они появились здесь'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('записи читаются и сортируются по дате, новые сверху', (
    tester,
  ) async {
    final storage = GameRecordStorage(preferences: FakePreferences());
    await storage.add(_record(dateTime: DateTime(2026, 8, 1)));
    await storage.add(_record(dateTime: DateTime(2026, 9, 1)));
    await storage.add(_record(dateTime: DateTime(2026, 7, 1)));
    await _openHistoryScreen(tester, storage: storage);

    final titles = find.textContaining('Игра от');
    expect(titles, findsNWidgets(3));
    final titlesInOrder = [
      for (var i = 0; i < 3; i++) tester.widget<Text>(titles.at(i)).data,
    ];
    expect(titlesInOrder, [
      'Игра от 01.09.2026 00:00',
      'Игра от 01.08.2026 00:00',
      'Игра от 01.07.2026 00:00',
    ]);
  });

  testWidgets('раскрытие карточки показывает игроков, фракции и очки', (
    tester,
  ) async {
    final storage = GameRecordStorage(preferences: FakePreferences());
    await storage.add(
      _record(
        dateTime: DateTime(2026, 8, 1, 18, 30),
        players: [_player('Иван', 42, 'Майя'), _player('Пётр', 35, 'Наги')],
      ),
    );
    await _openHistoryScreen(tester, storage: storage);

    expect(find.text('Игра от 01.08.2026 18:30'), findsOneWidget);
    expect(find.text('2 игрока'), findsOneWidget);
    expect(find.text('Иван (Майя)'), findsNothing);
    expect(find.text('42'), findsNothing);

    await tester.tap(find.text('Игра от 01.08.2026 18:30'));
    await tester.pumpAndSettle();

    expect(find.text('Иван (Майя)'), findsOneWidget);
    expect(find.text('Пётр (Наги)'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('35'), findsOneWidget);
  });

  testWidgets('очистка с подтверждением удаляет записи и показывает пустое', (
    tester,
  ) async {
    final prefs = FakePreferences();
    final storage = GameRecordStorage(preferences: prefs);
    await storage.add(_record());
    await _openHistoryScreen(tester, storage: storage);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    expect(find.text('Очистить историю'), findsOneWidget);
    expect(
      find.text('Вы уверены, что хотите удалить всю историю результатов?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('История очищена'), findsOneWidget);
    expect(find.text('История пуста'), findsOneWidget);
    expect(await storage.loadAll(), isEmpty);
  });

  testWidgets('отмена диалога не очищает историю', (tester) async {
    final prefs = FakePreferences();
    final storage = GameRecordStorage(preferences: prefs);
    await storage.add(_record(dateTime: DateTime(2026, 8, 1, 18, 30)));
    await _openHistoryScreen(tester, storage: storage);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Игра от 01.08.2026 18:30'), findsOneWidget);
    expect(await storage.loadAll(), hasLength(1));
  });

  testWidgets('системное «назад» ведёт в главное меню', (tester) async {
    final storage = GameRecordStorage(preferences: FakePreferences());
    await storage.add(_record());
    await _openHistoryScreen(tester, storage: storage);

    await _simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('Начать игру'), findsOneWidget);
    expect(find.text('История игр'), findsNothing);
  });

  testWidgets('новая запись появляется в уже открывавшейся истории', (
    tester,
  ) async {
    final storage = GameRecordStorage(preferences: FakePreferences());
    await storage.add(_record(dateTime: DateTime(2026, 8, 1, 18, 30)));
    await _openHistoryScreen(tester, storage: storage);
    expect(find.text('Игра от 01.08.2026 18:30'), findsOneWidget);

    // Кэш истории уже создан; сохраняем новую партию через экран очков
    // (та же сессия приложения — тот же ProviderContainer).
    appRouter.go('/score');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('p1-name')), 'Аня');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-0')), '7');
    await tester.tap(find.text('Сохранить результаты'));
    await tester.pumpAndSettle();

    expect(find.byType(ScoreHistoryScreen), findsOneWidget);
    expect(await storage.loadAll(), hasLength(2));
    // Новая партия (самая свежая) — первая карточка; раскрываем её.
    await tester.tap(find.textContaining('Игра от').first);
    await tester.pumpAndSettle();
    expect(find.text('Аня (Тестовая)'), findsOneWidget);
  });

  testWidgets('записи v1 после миграции первой партии видны в истории', (
    tester,
  ) async {
    final prefs = FakePreferences();
    prefs.strings[GameRecordStorage.recordsKey] = [v1RecordSource];
    // Первый запуск v2: миграция до старта приложения (как в main()).
    await GameRecordMigration(preferences: prefs).migrateIfNeeded();
    await _openHistoryScreen(
      tester,
      storage: GameRecordStorage(preferences: prefs),
    );

    expect(find.text('Игра от 12.08.2026 18:30'), findsOneWidget);
    await tester.tap(find.text('Игра от 12.08.2026 18:30'));
    await tester.pumpAndSettle();

    expect(find.text('Иван (Майя)'), findsOneWidget);
    expect(find.text('Пётр (Наги)'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('35'), findsOneWidget);
  });
}
