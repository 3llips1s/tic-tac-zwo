import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/game/online/ui/widgets/display_ripple_icon.dart';
import 'package:tic_tac_zwo/features/navigation/routes/route_names.dart';

import '../../../../../config/game_config/config.dart';
import '../../data/services/matchmaking_service.dart';

// preference constants
const String preferencesBoxName = 'user_preferences';
const String hasSeenMatchmakingSelectionKey = 'has_seen_matchmaking_selection';

// define UI states
enum MatchmakingUIState {
  loading,
  modeSelection,
  globalSearching,
  nearbySearching,
  directMatchInitiating,
}

class MatchmakingScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;

  const MatchmakingScreen({
    super.key,
    this.gameMode = GameMode.online,
  });

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  MatchmakingUIState _uiState = MatchmakingUIState.loading;
  bool _hasSeenModeSelection = false;

  List<Map<String, dynamic>> _cachedNearbyPlayers = [];

  late final MatchmakingService _matchmakingService;

  @override
  void initState() {
    super.initState();

    _matchmakingService = ref.read(matchmakingServiceProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _hasSeenModeSelection = await _checkIfSeenModeSelection();

      if (!_hasSeenModeSelection) {
        await _markModeSelectionAsSeen();
        setState(() {
          _uiState = MatchmakingUIState.modeSelection;
        });
      } else {
        setState(() {
          _uiState = MatchmakingUIState.globalSearching;
        });
        _initializeMatchmaking();
      }
    });
  }

  Future<void> _initializeMatchmaking() async {
    try {
      await ref.read(matchmakingServiceProvider).goOnline();
      await Future.delayed(Duration(milliseconds: 700));

      if (_uiState != MatchmakingUIState.globalSearching) {
        _startGlobalMatchMaking();
      } else {
        ref.read(matchmakingServiceProvider).startGlobalMatchmaking();
      }
    } catch (e) {
      print('matchmaking initialization error: $e');

      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    }
  }

  Future<bool> _checkIfSeenModeSelection() async {
    try {
      final box = await Hive.openBox(preferencesBoxName);
      return box.get(hasSeenMatchmakingSelectionKey, defaultValue: false);
    } catch (e) {
      return false;
    }
  }

  Future<void> _markModeSelectionAsSeen() async {
    try {
      final box = await Hive.openBox(preferencesBoxName);
      await box.put(hasSeenMatchmakingSelectionKey, true);
      setState(() {
        _hasSeenModeSelection = true;
      });
    } catch (e) {
      // continue without setting the flag if there's an error
    }
  }

  void _startGlobalMatchMaking() {
    setState(() {
      _uiState = MatchmakingUIState.globalSearching;
    });
    ref.read(matchmakingServiceProvider).startGlobalMatchmaking();
  }

  Future<void> _startNearbyMatchmaking() async {
    setState(() {
      _uiState = MatchmakingUIState.nearbySearching;
    });
    ref.read(matchmakingServiceProvider).startNearbyMatchmaking();
  }

  void _cancelMatchmaking() {
    ref.read(matchmakingServiceProvider).cancelMatchmaking();
    ref.read(matchmakingServiceProvider).goOffline();

    if (mounted) {
      setState(() {
        _uiState = MatchmakingUIState.modeSelection;
      });
    }
  }

  void _switchToNearbySearch() {
    ref.read(matchmakingServiceProvider).cancelMatchmaking();
    _startNearbyMatchmaking();
  }

  void _navigateToOnlineTurnSelection(String gameId) {
    if (mounted) {
      ref.read(matchmakingServiceProvider).goOffline();
      Navigator.pushReplacementNamed(context, RouteNames.onlineTurnSelection,
          arguments: {'gameSessionId': gameId, 'matchMode': _getModeTitle()});
    }
  }

  void _handleBackNavigation() {
    final matchmakingService = ref.read(matchmakingServiceProvider);
    final currentState = ref.read(matchmakingStateProvider).value;

    if (currentState == MatchmakingState.searching) {
      matchmakingService.cancelMatchmaking();
    }

    matchmakingService.goOffline();

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        RouteNames.home,
      );
    }
  }

  String _getModeTitle() {
    if (_uiState == MatchmakingUIState.globalSearching) {
      return 'global';
    } else if (_uiState == MatchmakingUIState.nearbySearching) {
      return 'in der Nähe';
    } else {
      return 'online';
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchmakingState = ref.watch(matchmakingStateProvider);
    final nearbyPlayers = ref.watch(nearbyPlayersProvider);
    final isSearching = matchmakingState.value == MatchmakingState.searching;

    // set up match listener and navigate to turn selection
    ref.listen<AsyncValue<String?>>(
      matchedGameIdProvider,
      (_, next) {
        final gameId = next.value;
        if (gameId != null) {
          if (_uiState == MatchmakingUIState.globalSearching ||
              _uiState == MatchmakingUIState.nearbySearching ||
              ref.read(matchmakingStateProvider).value ==
                  MatchmakingState.matched) {
            _navigateToOnlineTurnSelection(gameId);
          }
        }
      },
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          final currentState = ref.read(matchmakingStateProvider).value;
          if (currentState == MatchmakingState.searching) {
            ref.read(matchmakingServiceProvider).cancelMatchmaking();
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorGrey300,
        body: Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: kToolbarHeight / 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // game mode title
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  height: kToolbarHeight * 2,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _getModeTitle(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _buildContentForUIState(isSearching, nearbyPlayers),
              ),

              // navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // back button
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 20),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: IconButton(
                        onPressed: _handleBackNavigation,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colorWhite,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  Spacer(),

                  // conditional nearby players link
                  if (_uiState == MatchmakingUIState.globalSearching &&
                      isSearching)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 30, top: 10, bottom: 10),
                      child: GestureDetector(
                        onTap: _switchToNearbySearch,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IntrinsicWidth(
                              child: Column(
                                children: [
                                  Text(
                                    'Spieler in deiner Nähe?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFC21807).withOpacity(0.4),
                                    ),
                                  ),
                                  Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFC21807).withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.wifi_tethering_rounded,
                              size: 30,
                              color: colorRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentForUIState(
      bool isSearching, AsyncValue<List<Map<String, dynamic>>> nearbyPlayers) {
    switch (_uiState) {
      case MatchmakingUIState.loading:
        return Center(
          child: DualProgressIndicator(),
        );

      case MatchmakingUIState.modeSelection:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeButton(
                icon: Icons.wifi_tethering,
                title: 'In der Nähe',
                subtitle: 'gegen Freunden in deiner Nähe',
                color: colorRed,
                textColor: colorWhite,
                onTap: () {
                  ref.read(matchmakingServiceProvider).goOnline();
                  _startNearbyMatchmaking();
                },
              ),
              SizedBox(height: kToolbarHeight),
              _buildModeButton(
                icon: Icons.travel_explore_rounded,
                title: 'Global',
                subtitle: 'gegen weltweite Spieler',
                color: colorYellowAccent,
                textColor: colorBlack,
                onTap: () {
                  ref.read(matchmakingServiceProvider).goOnline();
                  _startGlobalMatchMaking();
                },
              ),
            ],
          ),
        );

      case MatchmakingUIState.globalSearching:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(height: 24),
              DisplayRippleIcon(
                icon: Icon(
                  Icons.travel_explore_rounded,
                  color: colorBlack,
                  size: 50,
                ),
                rippleColor: colorYellowAccent,
                shadowScale: 3,
              ),
              SizedBox(height: kToolbarHeight),
              Text(
                'Suche nach Spielern weltweit...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      color: Colors.black26,
                    ),
              ),
              SizedBox(),
              OutlinedButton(
                onPressed: _cancelMatchmaking,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  overlayColor: colorBlack,
                  side: BorderSide(color: Colors.black87),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                  child: Text(
                    'abbrechen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorBlack,
                          fontSize: 20,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );

      case MatchmakingUIState.nearbySearching:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(height: 24),
              DisplayRippleIcon(
                icon: Icon(
                  Icons.wifi_tethering,
                  color: colorWhite,
                  size: 50,
                ),
                rippleColor: colorRed,
                shadowScale: 3,
              ),
              SizedBox(height: kToolbarHeight * 2),
              Text(
                'Suche nach Spielern in der Nähe...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      color: Colors.black26,
                    ),
              ),
              SizedBox(height: 12),
              // nearby players list
              _buildNearbyPlayersList(nearbyPlayers),

              SizedBox(height: 8),

              OutlinedButton(
                onPressed: _cancelMatchmaking,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  overlayColor: colorBlack,
                  side: BorderSide(color: Colors.black87),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                  child: Text(
                    'abbrechen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorBlack,
                          fontSize: 20,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );

      case MatchmakingUIState.directMatchInitiating:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(height: 24),
              DisplayRippleIcon(
                icon: Icon(
                  Icons.sports_esports_rounded,
                  color: colorWhite,
                  size: 50,
                ),
                rippleColor: Colors
                    .green, // Use green to indicate connection in progress
                shadowScale: 3,
              ),
              SizedBox(height: kToolbarHeight * 2),
              Text(
                'Verbindung wird hergestellt...', // "Connection is being established..."
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 12),
              _buildNearbyPlayersList(nearbyPlayers),
              SizedBox(height: 8),
            ],
          ),
        );
    }
  }

  Widget _buildNearbyPlayersList(
      AsyncValue<List<Map<String, dynamic>>> nearbyPlayers) {
    if (_uiState == MatchmakingUIState.directMatchInitiating) {
      if (_cachedNearbyPlayers.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            color: colorRed,
            strokeWidth: 1,
          ),
        );
      }

      final itemHeight = 60.0;
      final calculatedHeight = math.min(
        _cachedNearbyPlayers.length * itemHeight,
        2 * itemHeight,
      );

      return SizedBox(
        height: math.max(kToolbarHeight, calculatedHeight),
        width: 300,
        child: ListView.builder(
          itemCount: _cachedNearbyPlayers.length,
          padding: EdgeInsets.symmetric(horizontal: 40),
          physics: _cachedNearbyPlayers.length > 2
              ? AlwaysScrollableScrollPhysics()
              : NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final player = _cachedNearbyPlayers[index];
            final username = player['username'] as String? ?? 'Unbekannt';

            // Show loading indicator inside each item (or you could highlight just the selected one)
            return SizedBox(
              height: itemHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    username,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  // Replace arrow with loading indicator
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return nearbyPlayers.when(
      data: (remotePlayers) {
        if (remotePlayers.isNotEmpty) {
          _cachedNearbyPlayers = List.from(remotePlayers);
        }
        if (remotePlayers.isEmpty) {
          return Text(
            'Keine Spieler gefunden.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Color(0xFFC21807),
                  fontSize: 16,
                ),
          );
        }

        final itemHeight = 60.0;
        final calculatedHeight = math.min(
          remotePlayers.length * itemHeight,
          2 * itemHeight,
        );

        return SizedBox(
          height: math.max(kToolbarHeight, calculatedHeight),
          width: 300,
          child: ListView.builder(
            itemCount: remotePlayers.length,
            padding: EdgeInsets.symmetric(horizontal: 40),
            physics: remotePlayers.length > 2
                ? AlwaysScrollableScrollPhysics()
                : NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final player = remotePlayers[index];
              final username = player['username'] as String? ?? 'Unbekannt';
              final userId = player['user_id'] as String?;

              return SizedBox(
                height: itemHeight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (userId != null) {
                        setState(() {
                          _uiState = MatchmakingUIState.directMatchInitiating;
                        });
                        ref
                            .read(matchmakingServiceProvider)
                            .initiateDirectMatch(userId);
                      } else {
                        print('error: nearby player user_id is null');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          username,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 18,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 36,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Fehler beim Laden der Spieler',
          style: TextStyle(color: Colors.red[700]),
          textAlign: TextAlign.center,
        ),
      ),
      loading: () => Center(
        child: CircularProgressIndicator(
          color: colorRed,
          strokeWidth: 1,
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24),
        width: 300,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(5, 5),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: textColor,
            ),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _matchmakingService.goOffline();
    super.dispose();
  }
}
