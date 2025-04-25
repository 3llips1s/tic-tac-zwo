import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if user has seen mode selection before
      _hasSeenModeSelection = await _checkIfSeenModeSelection();

      if (!_hasSeenModeSelection) {
        // First time user: Show mode selection UI
        await _markModeSelectionAsSeen();
        setState(() {
          _uiState = MatchmakingUIState.modeSelection;
        });
      } else {
        // Returning user: Start global matchmaking automatically
        _startGlobalMatchMaking();
      }
    });
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
    setState(() {
      _uiState = MatchmakingUIState.modeSelection;
    });
  }

  void _switchToNearbySearch() {
    _cancelMatchmaking();
    _startNearbyMatchmaking();
  }

  void _navigateToOnlineTurnSelection(String gameId) {
    _cancelMatchmaking();
    Navigator.pushReplacementNamed(context, RouteNames.onlineTurnSelection,
        arguments: {'gameSessionId': gameId});
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
        next.whenData(
          (gameId) {
            if (gameId != null) {
              _navigateToOnlineTurnSelection(gameId);
            }
          },
        );
      },
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (isSearching) {
          _cancelMatchmaking();
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
                      widget.gameMode.string,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 28,
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
                        onPressed: () {
                          if (isSearching) {
                            ref
                                .read(matchmakingServiceProvider)
                                .cancelMatchmaking();
                          }
                          if (mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              RouteNames.home,
                            );
                          }
                        },
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
                      padding: const EdgeInsets.only(right: 30, top: 20),
                      child: GestureDetector(
                        onTap: _switchToNearbySearch,
                        child: IntrinsicWidth(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Spieler in deiner Nähe finden?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorRed.withOpacity(0.5),
                                ),
                              ),
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  color: colorRed.withOpacity(0.5),
                                ),
                              )
                            ],
                          ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorYellowAccent,
                strokeWidth: 1,
              ),
              SizedBox(height: kToolbarHeight),
              Text(
                'Wird geladen...',
                style: TextStyle(
                  color: colorBlack,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        );

      case MatchmakingUIState.modeSelection:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeButton(
                icon: Icons.wifi_tethering,
                title: 'in der Nähe spielen',
                subtitle: 'gegen Spieler in deiner Umgebung',
                color: colorRed,
                textColor: colorWhite,
                onTap: _startNearbyMatchmaking,
              ),
              SizedBox(height: kToolbarHeight),
              _buildModeButton(
                icon: Icons.travel_explore_rounded,
                title: 'online spielen',
                subtitle: 'gegen globale Spieler',
                color: colorYellowAccent,
                textColor: colorBlack,
                onTap: _startGlobalMatchMaking,
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
    }
  }

  Widget _buildNearbyPlayersList(
      AsyncValue<List<Map<String, dynamic>>> nearbyPlayers) {
    return nearbyPlayers.when(
      data: (players) {
        if (players.isEmpty) {
          return Text(
            'Keine Spieler*in in der Nähe gefunden.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorBlack,
                  fontSize: 20,
                ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...players.map(
              (player) => ListTile(
                title: Text(player['username'] ?? 'Unbekannt'),
                subtitle: Text(
                    '${player['distance_meters'].toStringAsFixed(1)}m entfernt'),
                trailing: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(matchmakingServiceProvider)
                        .initiateDirectMatch(player['user_id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorYellowAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Icon(
                    Icons.double_arrow_rounded,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) => Text('Fehler beim Laden der Spieler'),
      loading: () => CircularProgressIndicator(
        color: colorRed,
        strokeWidth: 1,
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
                color: textColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
