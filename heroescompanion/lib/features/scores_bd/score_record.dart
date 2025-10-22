class ScoreRecord {
  final DateTime dateTime;
  final List<PlayerScore> playerScores;

  ScoreRecord({
    required this.dateTime,
    required this.playerScores,
  });

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'playerScores': playerScores.map((ps) => ps.toJson()).toList(),
    };
  }

  factory ScoreRecord.fromJson(Map<String, dynamic> json) {
    // Handle potentially null or missing playerScores
    final playerScoresJson = json['playerScores'] as List? ?? [];
    final playerScores = playerScoresJson
        .map((ps) => PlayerScore.fromJson(ps as Map<String, dynamic>))
        .toList();

    return ScoreRecord(
      dateTime: DateTime.parse(json['dateTime']),
      playerScores: playerScores,
    );
  }

  @override
  String toString() {
    return 'ScoreRecord(dateTime: $dateTime, playerScores: $playerScores)';
  }
}

class PlayerScore {
  final String playerName;
  final int score;
  final String faction;

  PlayerScore({
    required this.playerName,
    required this.score,
    required this.faction,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'score': score,
      'faction': faction,
    };
  }

  factory PlayerScore.fromJson(Map<String, dynamic> json) {
    return PlayerScore(
      playerName: json['playerName'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      faction: json['faction'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'PlayerScore(playerName: $playerName, score: $score, faction: $faction)';
  }
}