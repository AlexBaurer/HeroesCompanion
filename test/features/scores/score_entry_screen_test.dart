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

import '../../helpers/fake_preferences.dart';
import '../../helpers/simulate_system_back.dart';

String _factionJson(int index) {
  return '''
{
  "name": "${index == 0 ? 'Тестовая' : 'Тестовая $index'}",
  "gamePart": 1,
  "color": "#BE5737",
  "background": "assets/faction_background/humans_low.PNG",
  "description": "Тестовая фракция.",
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
        (ref) => GameRecordStorage(preferences: FakePreferences()),
      ),
    ],
  );
  addTearDown(container.dispose);

  // Ассеты из pubspec в `flutter test` не грузятся: без мока канал
  // 'flutter/assets' никогда не отвечает, Image.asset остаётся в загрузке
  // и errorBuilder ячеек не срабатывает. Мок отвечает null — загрузка
  // падает сразу и тесты видят фолбэк ячеек (подписи категорий).
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async => null,
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    );
  });

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
  final entries = await storage.loadAll();
  return [for (final entry in entries) entry.record];
}

/// Текст ячейки подсчёта по ключу ячейки (поле ввода внутри).
String _cellText(WidgetTester tester, Key cellKey) {
  final field = tester.widget<TextField>(
    find.descendant(
      of: find.byKey(cellKey),
      matching: find.byType(TextField),
    ),
  );
  return field.controller!.text;
}

void main() {
  testWidgets('экран: игрок 1 с фракцией из партии, 4 игрока, ячейки подсчёта', (
    tester,
  ) async {
    await _openScoreScreen(tester);

    // Тикет 18: верхнего бара нет — заголовок «Ввод очков» в теле экрана.
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Ввод очков'), findsOneWidget);
    final titleContext = tester.element(find.text('Ввод очков'));
    expect(
      tester.widget<Text>(find.text('Ввод очков')).style,
      Theme.of(titleContext).textTheme.titleLarge,
    );
    expect(find.text('Фракция: Тестовая'), findsOneWidget);
    for (var player = 1; player <= 4; player++) {
      expect(find.text('Игрок $player'), findsOneWidget);
      expect(find.byKey(ValueKey('p$player-name')), findsOneWidget);
    }
    // 5 категорий и сумма — только у игрока 1 (в тестах без ассетов
    // ячейки показывают подписи в fallback).
    for (final label in [
      'Здания',
      'Фундаменты',
      'Ресурсы',
      'Победы в сражениях',
      'Артефакты',
      'Сумма',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // У игроков 2–4 — одна ячейка «Итог» вместо категорий и автосуммы.
    expect(find.text('Итог'), findsNWidgets(3));
    expect(find.text('Сохранить результаты'), findsOneWidget);
  });

  testWidgets('у игроков 2–4 одна ячейка «Итог», без категорий и суммы', (
    tester,
  ) async {
    await _openScoreScreen(tester);

    for (var player = 2; player <= 4; player++) {
      expect(find.byKey(ValueKey('p$player-cell-0')), findsOneWidget);
      for (var cell = 1; cell < 5; cell++) {
        expect(find.byKey(ValueKey('p$player-cell-$cell')), findsNothing);
      }
      expect(find.byKey(ValueKey('p$player-sum')), findsNothing);
    }
  });

  testWidgets('автосумма игрока 1 считается из пяти ячеек и меняется при вводе', (
    tester,
  ) async {
    await _openScoreScreen(tester);

    expect(find.text('0'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('p1-cell-0')), '2');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-1')), '3');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-2')), '0');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-3')), '4');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-4')), '6');
    await tester.pump();

    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('в ячейки нельзя ввести буквы — фильтр отбрасывает ввод', (
    tester,
  ) async {
    await _openScoreScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('p1-cell-0')), '12a');
    await tester.pump();
    expect(_cellText(tester, const ValueKey('p1-cell-0')), '');

    await tester.enterText(find.byKey(const ValueKey('p2-cell-0')), 'abc');
    await tester.pump();
    expect(_cellText(tester, const ValueKey('p2-cell-0')), '');
  });

  testWidgets('отрицательные очки вводятся, сумма становится отрицательной', (
    tester,
  ) async {
    await _openScoreScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('p1-cell-0')), '-4');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-1')), '2');
    await tester.pump();

    expect(find.text('-2'), findsOneWidget);
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

  testWidgets('итог игрока 2 — из его единственной ячейки, в т.ч. отрицательный', (
    tester,
  ) async {
    final container = await _openScoreScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('p1-name')), 'Иван');
    await tester.enterText(find.byKey(const ValueKey('p1-cell-0')), '10');
    await tester.enterText(find.byKey(const ValueKey('p2-name')), 'Пётр');
    await tester.enterText(find.byKey(const ValueKey('p2-cell-0')), '-3');
    await tester.tap(find.text('Сохранить результаты'));
    await tester.pumpAndSettle();

    final records = await _savedRecords(container);
    expect(records.single.playerScores, hasLength(2));
    expect(records.single.playerScores[1].playerName, 'Пётр');
    expect(records.single.playerScores[1].score, -3);
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

  testWidgets('системное «назад» (одно нажатие) ведёт на главное меню', (
    tester,
  ) async {
    await _openScoreScreen(tester);

    await simulateSystemBack();
    await tester.pumpAndSettle();

    // Главное меню, а не экран партии: ввод очков открыт напрямую,
    // партии в стеке нет (тикет 18 — PopScope + go('/')).
    expect(find.text('Герои — Помощник'), findsOneWidget);
    expect(find.text('Начать игру'), findsOneWidget);
    expect(find.text('Ввод очков'), findsNothing);
  });
}
