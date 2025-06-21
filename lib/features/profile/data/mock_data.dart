import 'models/game_history_entry.dart';
import 'models/user_profile.dart';

// todod: remove this mock data

// --- Mock User Profiles ---

// We'll use a map to easily look up mock users by their ID.
final Map<String, UserProfile> mockUserProfiles = {
  'my_mock_id': UserProfile(
    id: 'my_mock_id',
    username: '3ll1psis',
    points: 1337,
    gamesPlayed: 88,
    gamesWon: 50,
    gamesDrawn: 10,
    lastOnline: DateTime.now().subtract(const Duration(minutes: 5)),
    isOnline: true,
    avatarUrl: 'https://picsum.photos/id/237/200', // A random dog picture
    countryCode: 'KE', // Germany
    totalArticleAttempts: 250,
    totalCorrectArticles: 220,
  ),
  'opponent_mock_id': UserProfile(
    id: 'opponent_mock_id',
    username: 'Spieler_2',
    points: 950,
    gamesPlayed: 75,
    gamesWon: 40,
    gamesDrawn: 5,
    lastOnline: DateTime.now().subtract(const Duration(days: 1)),
    isOnline: false,
    avatarUrl: 'https://picsum.photos/id/1025/200', // Another random dog
    countryCode: 'AT', // Austria
    totalArticleAttempts: 200,
    totalCorrectArticles: 150,
  ),
};

// --- Mock Game History ---

final List<GameHistoryEntry> mockGameHistory = [
  GameHistoryEntry(
    gameId: 'game1',
    opponentUsername: 'Lukas',
    opponentAvatarUrl: 'https://picsum.photos/id/10/200',
    opponentCountryCode: 'CH', // Switzerland
    result: 'Win',
    playedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  GameHistoryEntry(
    gameId: 'game2',
    opponentUsername: 'Mia',
    opponentAvatarUrl: null, // Test placeholder avatar
    opponentCountryCode: 'DE',
    result: 'Loss',
    playedAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  GameHistoryEntry(
    gameId: 'game3',
    opponentUsername: 'Finn',
    opponentAvatarUrl: 'https://picsum.photos/id/45/200',
    opponentCountryCode: 'AT',
    result: 'Draw',
    playedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  GameHistoryEntry(
    gameId: 'game4',
    opponentUsername: 'Sophia',
    opponentAvatarUrl: 'https://picsum.photos/id/67/200',
    opponentCountryCode: 'DE',
    result: 'Win',
    playedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  GameHistoryEntry(
    gameId: 'game5',
    opponentUsername: 'Jonas',
    opponentAvatarUrl: 'https://picsum.photos/id/88/200',
    opponentCountryCode: 'CH',
    result: 'Win',
    playedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];
