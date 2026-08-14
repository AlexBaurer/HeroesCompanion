import 'game_record.dart';

/// Сортировка истории игр (тикет 14): по дате или по сумме очков записи,
/// в каждом из двух направлений. Значения — варианты меню сортировки
/// на экране истории.
enum HistorySort {
  /// По дате, новые сверху — сортировка по умолчанию (как в тикете 09).
  dateNewestFirst,

  /// По дате, старые сверху.
  dateOldestFirst,

  /// По сумме очков, больше сверху.
  scoreDescending,

  /// По сумме очков, меньше сверху.
  scoreAscending,
}

/// Компаратор записей для выбранной сортировки истории.
/// При равенстве ключа сортировки записи сравниваются по дате
/// (новые сверху), чтобы порядок был детерминированным.
Comparator<GameRecord> historyComparator(HistorySort sort) {
  switch (sort) {
    case HistorySort.dateNewestFirst:
      return _byDateDesc;
    case HistorySort.dateOldestFirst:
      return _byDateAsc;
    case HistorySort.scoreDescending:
      return _byScoreDesc;
    case HistorySort.scoreAscending:
      return _byScoreAsc;
  }
}

int _byDateDesc(GameRecord a, GameRecord b) =>
    b.dateTime.compareTo(a.dateTime);

int _byDateAsc(GameRecord a, GameRecord b) => a.dateTime.compareTo(b.dateTime);

int _byScoreDesc(GameRecord a, GameRecord b) {
  final byScore = b.totalScore.compareTo(a.totalScore);
  return byScore != 0 ? byScore : _byDateDesc(a, b);
}

int _byScoreAsc(GameRecord a, GameRecord b) {
  final byScore = a.totalScore.compareTo(b.totalScore);
  return byScore != 0 ? byScore : _byDateDesc(a, b);
}
