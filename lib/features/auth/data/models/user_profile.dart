class UserProfile {
  final String id;
  final String username;
  final int points;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesDrawn;
  final double? lat;
  final double? lng;
  final DateTime lastOnline;
  final bool isOnline;
  final String? avatarUrl;
  final String? countryCode;
  final int totalArticleAttempts;
  final int totalCorrectArticles;

  UserProfile({
    required this.id,
    required this.username,
    required this.points,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.gamesDrawn,
    this.lat,
    this.lng,
    required this.lastOnline,
    required this.isOnline,
    this.avatarUrl,
    this.countryCode,
    required this.totalArticleAttempts,
    required this.totalCorrectArticles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
        id: json['id'],
        username: json['username'],
        points: json['points'] ?? 0,
        gamesPlayed: json['games_played'] ?? 0,
        gamesWon: json['games_won'] ?? 0,
        gamesDrawn: json['games_drawn'] ?? 0,
        lat: json['lat'],
        lng: json['lng'],
        lastOnline: DateTime.parse(json['last_online']),
        isOnline: json['is_online'] ?? false,
        avatarUrl: json['avatar_url'],
        countryCode: json['country_code'],
        totalArticleAttempts: json['total_article_attempts'],
        totalCorrectArticles: json['total_correct_articles']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'points': points,
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'games_drawn': gamesDrawn,
      'lat': lat,
      'lng': lng,
      'last_online': lastOnline.toIso8601String(),
      'is_online': isOnline,
      'avatar_url': avatarUrl,
      'country_code': countryCode,
      'total_article_attempts': totalArticleAttempts,
      'total_correct_articles': totalCorrectArticles,
    };
  }

  UserProfile copyWith({
    String? username,
    int? points,
    int? gamesPlayed,
    int? gamesWon,
    int? gamesDrawn,
    double? lat,
    double? lng,
    DateTime? lastOnline,
    bool? isOnline,
    String? avatarUrl,
    String? countryCode,
    int? totalArticleAttempts,
    int? totalCorrectArticles,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      points: points ?? this.points,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesDrawn: gamesDrawn ?? this.gamesDrawn,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      lastOnline: lastOnline ?? this.lastOnline,
      isOnline: isOnline ?? this.isOnline,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      countryCode: countryCode ?? this.countryCode,
      totalArticleAttempts: totalArticleAttempts ?? this.totalArticleAttempts,
      totalCorrectArticles: totalCorrectArticles ?? this.totalCorrectArticles,
    );
  }
}
