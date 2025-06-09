class LeaderboardEntry {
  final String id;
  final int rank;
  final String username;
  final String countryCode;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesDrawn;
  final double accuracy;
  final int points;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.username,
    required this.countryCode,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.gamesDrawn,
    required this.accuracy,
    required this.points,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      rank: json['rank'] as int? ?? 0,
      username: json['username'] as String? ?? 'Unbekannt',
      countryCode: json['country_code'] as String? ?? '',
      gamesPlayed: json['games_played'] as int? ?? 0,
      gamesWon: json['games_won'] as int? ?? 0,
      gamesDrawn: json['games_drawn'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      points: json['points'] as int? ?? 0,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rank': rank,
      'username': username,
      'country_code': countryCode,
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'games_drawn': gamesDrawn,
      'accuracy': accuracy,
      'points': points,
      'is_current_user': isCurrentUser,
    };
  }
}
