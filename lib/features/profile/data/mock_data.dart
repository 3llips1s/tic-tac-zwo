import 'dart:math';

import 'models/game_history_entry.dart';
import 'models/user_profile.dart';

// todo: remove this mock data

class MockDataService {
  static final List<UserProfile> mockUsers = _generateMockUsers(count: 50);

  static final UserProfile currentUser = mockUsers[6];

  static final List<GameHistoryEntry> mockGameHistory = [
    GameHistoryEntry(
      gameId: 'game1',
      opponentId: mockUsers[0].id,
      opponentUsername: mockUsers[0].username,
      opponentAvatarUrl: mockUsers[0].avatarUrl,
      opponentCountryCode: mockUsers[0].countryCode,
      result: 'Win',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GameHistoryEntry(
      gameId: 'game2',
      opponentId: mockUsers[1].id,
      opponentUsername: mockUsers[1].username,
      opponentAvatarUrl: mockUsers[1].avatarUrl,
      opponentCountryCode: mockUsers[1].countryCode,
      result: 'Draw',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GameHistoryEntry(
      gameId: 'game3',
      opponentId: mockUsers[2].id,
      opponentUsername: mockUsers[2].username,
      opponentAvatarUrl: mockUsers[2].avatarUrl,
      opponentCountryCode: mockUsers[2].countryCode,
      result: 'Loss',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GameHistoryEntry(
      gameId: 'game4',
      opponentId: mockUsers[3].id,
      opponentUsername: mockUsers[3].username,
      opponentAvatarUrl: mockUsers[3].avatarUrl,
      opponentCountryCode: mockUsers[3].countryCode,
      result: 'Loss',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GameHistoryEntry(
      gameId: 'game5',
      opponentId: mockUsers[4].id,
      opponentUsername: mockUsers[4].username,
      opponentAvatarUrl: mockUsers[4].avatarUrl,
      opponentCountryCode: mockUsers[4].countryCode,
      result: 'Win',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GameHistoryEntry(
      gameId: 'game6',
      opponentId: mockUsers[5].id,
      opponentUsername: mockUsers[5].username,
      opponentAvatarUrl: mockUsers[5].avatarUrl,
      opponentCountryCode: mockUsers[5].countryCode,
      result: 'Draw',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GameHistoryEntry(
      gameId: 'game7',
      opponentId: mockUsers[6].id,
      opponentUsername: mockUsers[6].username,
      opponentAvatarUrl: mockUsers[6].avatarUrl,
      opponentCountryCode: mockUsers[6].countryCode,
      result: 'Loss',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GameHistoryEntry(
      gameId: 'game8',
      opponentId: mockUsers[7].id,
      opponentUsername: mockUsers[7].username,
      opponentAvatarUrl: mockUsers[7].avatarUrl,
      opponentCountryCode: mockUsers[7].countryCode,
      result: 'Win',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GameHistoryEntry(
      gameId: 'game9',
      opponentId: mockUsers[8].id,
      opponentUsername: mockUsers[8].username,
      opponentAvatarUrl: mockUsers[8].avatarUrl,
      opponentCountryCode: mockUsers[8].countryCode,
      result: 'Draw',
      playedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static List<UserProfile> _generateMockUsers({int count = 50}) {
    final Random random = Random();
    final List<String> mockUsernames = [
      'G3ll1psis',
      'Mungai',
      'Chwaki',
      'Bo',
      'Nginyo',
      'Mwaki',
      'Boi',
      'Mimmo',
      'Emily'
    ];

    //
    final List<String> mockCountries = [
      'DE',
      'MR',
      'UG',
      'KE',
      'CA',
      'AU',
      'JP',
      'CH',
      'XK'
    ];
    List<UserProfile> users = [];

    for (int i = 0; i < count; i++) {
      String baseName = mockUsernames[random.nextInt(mockUsernames.length)];
      String username = '$baseName${random.nextInt(99)}';
      if (username.length > 9) {
        username = username.substring(0, 9);
      }

      int points = (1000 - i * 15) + random.nextInt(10);
      int gamesPlayed = 20 + random.nextInt(50);
      int gamesWon = (gamesPlayed * (0.4 + random.nextDouble() * 0.5)).round();
      int gamesDrawn = min((gamesPlayed - gamesWon), random.nextInt(5));
      int totalArticleAttempts = 100 + random.nextInt(150);
      int totalCorrectArticles =
          (totalArticleAttempts * (0.65 + random.nextDouble() * 0.34)).round();

      users.add(UserProfile(
        id: 'mock_user_id_$i',
        username: username,
        points: points,
        gamesPlayed: gamesPlayed,
        gamesWon: gamesWon,
        gamesDrawn: gamesDrawn,
        lastOnline:
            DateTime.now().subtract(Duration(minutes: random.nextInt(10000))),
        isOnline: random.nextBool(),
        avatarUrl: 'https://picsum.photos/id/${100 + i}/200',
        countryCode: mockCountries[random.nextInt(mockCountries.length)],
        totalArticleAttempts: totalArticleAttempts,
        totalCorrectArticles: totalCorrectArticles,
      ));
    }

    users[6] = users[6].copyWith(
      username: 'Du',
      countryCode: 'KE',
    );
    return users;
  }
}
