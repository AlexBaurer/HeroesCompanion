import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/domain/game_record.dart';
import 'package:heroescompanion/domain/history_sort.dart';

PlayerScore _player(String name, int score, String faction) =>
    PlayerScore(playerName: name, score: score, faction: faction);

GameRecord _record(DateTime dateTime, List<PlayerScore> players) =>
    GameRecord(dateTime: dateTime, playerScores: players);

/// Сортирует копию списка компаратором выбранного направления.
List<GameRecord> _sorted(List<GameRecord> records, HistorySort sort) {
  final result = [...records];
  result.sort(historyComparator(sort));
  return result;
}

void main() {
  final newGame = _record(DateTime(2026, 9, 1), [_player('Аня', 50, 'Майя')]);
  final midGame = _record(DateTime(2026, 8, 1), [_player('Боря', 80, 'Наги')]);
  final oldGame = _record(DateTime(2026, 7, 1), [_player('Витя', 30, 'Гномы')]);

  group('по дате', () {
    test('новые сверху (по умолчанию, как в тикете 09)', () {
      final sorted = _sorted(
        [oldGame, newGame, midGame],
        HistorySort.dateNewestFirst,
      );

      expect(
        sorted.map((record) => record.dateTime).toList(),
        [DateTime(2026, 9, 1), DateTime(2026, 8, 1), DateTime(2026, 7, 1)],
      );
    });

    test('старые сверху', () {
      final sorted = _sorted(
        [midGame, newGame, oldGame],
        HistorySort.dateOldestFirst,
      );

      expect(
        sorted.map((record) => record.dateTime).toList(),
        [DateTime(2026, 7, 1), DateTime(2026, 8, 1), DateTime(2026, 9, 1)],
      );
    });
  });

  group('по сумме очков', () {
    test('больше сверху', () {
      final sorted = _sorted(
        [newGame, oldGame, midGame],
        HistorySort.scoreDescending,
      );

      expect(sorted.map((record) => record.totalScore).toList(), [80, 50, 30]);
    });

    test('меньше сверху', () {
      final sorted = _sorted(
        [midGame, newGame, oldGame],
        HistorySort.scoreAscending,
      );

      expect(sorted.map((record) => record.totalScore).toList(), [30, 50, 80]);
    });

    test('равные суммы: детерминированный порядок, новые сверху', () {
      final later = _record(DateTime(2026, 9, 1), [_player('Аня', 50, 'Майя')]);
      final earlier = _record(
        DateTime(2026, 8, 1),
        [_player('Боря', 50, 'Наги')],
      );

      final sorted = _sorted([earlier, later], HistorySort.scoreDescending);

      expect(sorted.map((record) => record.dateTime).toList(), [
        DateTime(2026, 9, 1),
        DateTime(2026, 8, 1),
      ]);
    });

    test('сумма по всем игрокам записи, не очки одного игрока', () {
      final twoPlayers = _record(DateTime(2026, 9, 1), [
        _player('Аня', 30, 'Майя'),
        _player('Боря', 40, 'Наги'),
      ]);
      final onePlayer = _record(DateTime(2026, 8, 1), [
        _player('Витя', 60, 'Гномы'),
      ]);

      final sorted = _sorted([onePlayer, twoPlayers], HistorySort.scoreDescending);

      expect(sorted, [twoPlayers, onePlayer]);
    });

    test('отрицательные очки не ломают сортировку', () {
      final minus = _record(DateTime(2026, 8, 1), [_player('Аня', -5, 'Майя')]);
      final zero = _record(DateTime(2026, 9, 1), [_player('Боря', 0, 'Наги')]);

      final sorted = _sorted([minus, zero], HistorySort.scoreAscending);

      expect(sorted, [minus, zero]);
    });
  });
}
