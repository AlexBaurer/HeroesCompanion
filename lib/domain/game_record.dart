/// Очки игрока в записи игры: имя, сумма очков и фракция.
class PlayerScore {
  const PlayerScore({
    required this.playerName,
    required this.score,
    required this.faction,
  });

  final String playerName;
  final int score;
  final String faction;

  /// JSON в формате v1: `{playerName, score, faction}`.
  Map<String, dynamic> toJson() {
    return {'playerName': playerName, 'score': score, 'faction': faction};
  }

  @override
  String toString() {
    return 'PlayerScore(playerName: $playerName, score: $score, '
        'faction: $faction)';
  }
}

/// Запись одной сыгранной партии: дата и результаты 1–4 игроков.
class GameRecord {
  GameRecord({required this.dateTime, required List<PlayerScore> playerScores})
    : playerScores = List.unmodifiable(playerScores) {
    if (playerScores.isEmpty || playerScores.length > maxPlayers) {
      throw ArgumentError.value(
        playerScores.length,
        'playerScores',
        'запись должна содержать от $minPlayers до $maxPlayers игроков',
      );
    }
  }

  static const int minPlayers = 1;
  static const int maxPlayers = 4;

  final DateTime dateTime;
  final List<PlayerScore> playerScores;

  /// Сумма очков всех игроков записи — ключ сортировки «по сумме очков»
  /// (тикет 14).
  int get totalScore {
    var sum = 0;
    for (final player in playerScores) {
      sum += player.score;
    }
    return sum;
  }

  /// JSON в формате v1 (ADR-0002): `{dateTime, playerScores}`,
  /// дата — ISO-8601 строка.
  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'playerScores': playerScores.map((player) => player.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'GameRecord(dateTime: $dateTime, playerScores: $playerScores)';
  }
}
