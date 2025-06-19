class GameHistoryEntry {
  final String gameId;
  final String opponentUsername;
  final String? opponentAvatarUrl;
  final String result;
  final DateTime playedAt;

  GameHistoryEntry({
    required this.gameId,
    required this.opponentUsername,
    this.opponentAvatarUrl,
    required this.result,
    required this.playedAt,
  });

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) {
    return GameHistoryEntry(
      gameId: json['game_id'],
      opponentUsername: json['opponent_username'] ?? 'Unbekannt',
      opponentAvatarUrl: json['opponent_avatar_url'],
      result: json['result'] ?? 'Draw',
      playedAt: DateTime.parse(json['played_at']),
    );
  }
}
