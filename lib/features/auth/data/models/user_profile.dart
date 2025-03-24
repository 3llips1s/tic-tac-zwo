class UserProfile {
  final String id;
  final String username;
  final int score;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesDrawn;
  final double? lat;
  final double? lng;
  final DateTime lastOnline;
  final bool isOnline;
  final String? avatarUrl;
  final String? countryCode;

  UserProfile({
    required this.id,
    required this.username,
    required this.score,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.gamesDrawn,
    this.lat,
    this.lng,
    required this.lastOnline,
    required this.isOnline,
    this.avatarUrl,
    this.countryCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      score: json['score'] ?? 0,
      gamesPlayed: json['games_played'] ?? 0,
      gamesWon: json['games_won'] ?? 0,
      gamesDrawn: json['games_drawn'] ?? 0,
      lat: json['lat'],
      lng: json['lng'],
      lastOnline: DateTime.parse(json['last_online']),
      isOnline: json['is_online'] ?? false,
      avatarUrl: json['avatar_url'],
      countryCode: json['country_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'score': score,
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'games_drawn': gamesDrawn,
      'lat': lat,
      'lng': lng,
      'last_online': lastOnline.toIso8601String(),
      'is_online': isOnline,
      'avatar_url': avatarUrl,
      'country_code': countryCode,
    };
  }

  UserProfile copyWith({
    String? username,
    int? score,
    int? gamesPlayed,
    int? gamesWon,
    int? gamesDrawn,
    double? lat,
    double? lng,
    DateTime? lastOnline,
    bool? isOnline,
    String? avatarUrl,
    String? countryCode,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      score: score ?? this.score,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesDrawn: gamesDrawn ?? this.gamesDrawn,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      lastOnline: lastOnline ?? this.lastOnline,
      isOnline: isOnline ?? this.isOnline,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}
