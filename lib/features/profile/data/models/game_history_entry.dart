class GameHistoryEntry {
  final String gameId;
  final String opponentId;
  final String opponentUsername;
  final String? opponentAvatarUrl;
  final String? opponentCountryCode;
  final String result;
  final DateTime playedAt;

  GameHistoryEntry({
    required this.gameId,
    required this.opponentId,
    required this.opponentUsername,
    this.opponentAvatarUrl,
    this.opponentCountryCode,
    required this.result,
    required this.playedAt,
  });

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) {
    return GameHistoryEntry(
      gameId: json['game_id'],
      opponentId: json['opponent_id'],
      opponentUsername: json['opponent_username'] ?? 'Unbekannt',
      opponentAvatarUrl: json['opponent_avatar_url'],
      opponentCountryCode: json['opponent_country_code'],
      result: json['result'] ?? 'Draw',
      playedAt: DateTime.parse(json['played_at']),
    );
  }
}
