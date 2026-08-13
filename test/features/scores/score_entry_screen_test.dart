import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/app/app_router.dart';
import 'package:heroescompanion/domain/game_record.dart';
import 'package:heroescompanion/features/factions/data/faction_providers.dart';
import 'package:heroescompanion/features/factions/data/faction_repository.dart';
import 'package:heroescompanion/features/scores/data/game_record_providers.dart';
import 'package:heroescompanion/features/scores/data/game_record_storage.dart';
import 'package:heroescompanion/features/scores/presentation/score_history_screen.dart';
import 'package:heroescompanion/main.dart';

import '../../helpers/fake_string_list_preferences.dart';

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

Future<ProviderContainer> _openScoreScreen(
  WidgetTester tester, {
  String? faction = 'Тестовая',
}) async {
  final container = ProviderContainer(
    overrides: [
      factionRepositoryProvider.overrideWithValue(_fakeRepository()),
      gameRecordStorageProvider.overrideWith(
        (ref) => GameRecordStorage(preferences: FakeStringListPreferences()),
      ),
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
  final path = faction == null
      ? '/score'
      : '/score?faction=${Uri.encodeQueryComponent(faction)}';
  appRouter.go(path);
  await tester.pumpAndSettle();
  return container;
}

/// Записи, сохранённые экраном, через публичный API хранилища.
Future<List<GameRecord>> _savedRecords(ProviderContainer container) async {
  final storage = await container.read(gameRecordStorageProvider.future);
  return storage.loadAll();
}

void main() {
  testWidgets('экран: игрок 1 с фракцией из партии, 4 игрока, 6 ячеек', (
    tester,
  ) async {
    await _openScoreScreen(tester);

    expect(find.text('Ввод очков'), findsOneWidget);
    expect(find.text('Фракция: Тестовая'), findsOneWidget);
    for (var player = 1; player <= 4; player++) {
      expect(find.text('Игрок $player'), findsOneWidget);
      expect(find.byKey(ValueKey('p$player-name')), findsOneWidget);
    }
    for (final label in ['Здания', 'Фундаменты', 'Ресурсы', 'Сумма']) {
      expect(find.text(label), findsNWidgets(4));
    }
    expect(find.text('Победы в сражениях'), findsNWidgets(4));
    expect(find.text('Артефакты'), findsNWidgets(4));
    expect(find.text('Сохранить результаты'), findsOneWidget);
  });

  testWidgets('автосумма считается из пяти ячеек и меняется при вводе', (
    tester,
  ) async {
    await _openScoreScreen(tester);

    expect(find.text('0'), findsNWidgets(4));

    await tester.enterText(find.byKey(const ValueKey('p1-cell-0')), '2');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-1')), '3');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-2')), '0');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-3')), '4');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-4')), '6');
    await tester.pump();

    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('сохранение одного игрока пишет запись v1 и ведёт к истории', (
    tester,
  ) async {
    final container = await _openScoreScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('p1-name')), 'Иван');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-0')), '10');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-2')), '5');
    await tester.tap(find.text('Сохранить результаты'));
    await tester.pumpAndSettle();

    expect(find.text('Результаты успешно сохранены'), findsOneWidget);
    expect(find.byType(ScoreHistoryScreen), findsOneWidget);

    final records = await _savedRecords(container);
    expect(records, hasLength(1));
    expect(records.single.playerScores, hasLength(1));
    expect(records.single.playerScores.single.playerName, 'Иван');
    expect(records.single.playerScores.single.score, 15);
    expect(records.single.playerScores.single.faction, 'Тестовая');
  });

  testWidgets('сохраняются только заполненные игроки', (tester) async {
    final container = await _openScoreScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('p1-name')), 'Иван');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-0')), '7');
    await tester.enterText(find.byKey(const ValueKey('p2-name')), 'Пётр');
    await tester.enterText(find.byKey(const ValueKey('p2-cell-0')), '10');
    await tester.tap(find.text('Сохранить результаты'));
    await tester.pumpAndSettle();

    final records = await _savedRecords(container);
    expect(records.single.playerScores, hasLength(2));
    expect(records.single.playerScores[0].playerName, 'Иван');
    expect(records.single.playerScores[0].score, 7);
    expect(records.single.playerScores[1].playerName, 'Пётр');
    expect(records.single.playerScores[1].score, 10);
    // Фракция игрока 2 — первая из каталога (как в v1 — Faction.all[0]).
    expect(records.single.playerScores[1].faction, 'Тестовая');
  });

  testWidgets('выбор фракции игрока 2 из каталога попадает в запись', (
    tester,
  ) async {
    final container = await _openScoreScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('p1-name')), 'Иван');
    await tester.enterText(find.byKey(const ValueKey('p2-name')), 'Пётр');

    await tester.tap(find.byKey(const ValueKey('p2-faction')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тестовая 1').last);
    await tester.pumpAndSettle();
    expect(find.text('Тестовая 1'), findsOneWidget);

    await tester.tap(find.text('Сохранить результаты'));
    await tester.pumpAndSettle();

    final records = await _savedRecords(container);
    expect(records.single.playerScores[1].faction, 'Тестовая 1');
  });

  testWidgets('без имён — подсказка, запись не создаётся и перехода нет', (
    tester,
  ) async {
    final container = await _openScoreScreen(tester);

    await tester.tap(find.text('Сохранить результаты'));
    await tester.pump();

    expect(find.text('Введите имя хотя бы одного игрока'), findsOneWidget);
    expect(find.text('Ввод очков'), findsOneWidget);
    expect(find.byType(ScoreHistoryScreen), findsNothing);
    expect(await _savedRecords(container), isEmpty);
  });
}
