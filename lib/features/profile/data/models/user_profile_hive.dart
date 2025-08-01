import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';

part 'user_profile_hive.g.dart';

@HiveType(typeId: 2)
class UserProfileHive extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final int points;

  @HiveField(3)
  final int gamesPlayed;

  @HiveField(4)
  final int gamesWon;

  @HiveField(5)
  final int gamesDrawn;

  @HiveField(6)
  final double? lat;

  @HiveField(7)
  final double? lng;

  @HiveField(8)
  final DateTime lastOnline;

  @HiveField(9)
  final bool isOnline;

  @HiveField(10)
  final String? avatarUrl;

  @HiveField(11)
  final String? countryCode;

  @HiveField(12)
  final int totalArticleAttempts;

  @HiveField(13)
  final int totalCorrectArticles;

  UserProfileHive({
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

  // Convert from UserProfile to UserProfileHive
  factory UserProfileHive.fromUserProfile(UserProfile userProfile) {
    return UserProfileHive(
      id: userProfile.id,
      username: userProfile.username,
      points: userProfile.points,
      gamesPlayed: userProfile.gamesPlayed,
      gamesWon: userProfile.gamesWon,
      gamesDrawn: userProfile.gamesDrawn,
      lat: userProfile.lat,
      lng: userProfile.lng,
      lastOnline: userProfile.lastOnline,
      isOnline: userProfile.isOnline,
      avatarUrl: userProfile.avatarUrl,
      countryCode: userProfile.countryCode,
      totalArticleAttempts: userProfile.totalArticleAttempts,
      totalCorrectArticles: userProfile.totalCorrectArticles,
    );
  }

  // Convert from UserProfileHive to UserProfile
  UserProfile toUserProfile() {
    return UserProfile(
      id: id,
      username: username,
      points: points,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      gamesDrawn: gamesDrawn,
      lat: lat,
      lng: lng,
      lastOnline: lastOnline,
      isOnline: isOnline,
      avatarUrl: avatarUrl,
      countryCode: countryCode,
      totalArticleAttempts: totalArticleAttempts,
      totalCorrectArticles: totalCorrectArticles,
    );
  }
}
