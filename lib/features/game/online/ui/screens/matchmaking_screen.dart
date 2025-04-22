import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/routes/route_names.dart';

import '../../data/services/matchmaking_service.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isNearbySearch = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // listen for match success and navigate to turn selection
    Future.delayed(
      Duration.zero,
      () {
        ref.listen<AsyncValue<String?>>(
          matchedGameIdProvider,
          (_, next) {
            next.whenData(
              (gameId) {
                if (gameId != null) {
                  _navigateToTurnSelection(gameId);
                }
              },
            );
          },
        );
      },
    );
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startGlobalMatchMaking() {
    setState(() {
      _isNearbySearch = false;
    });
    ref.read(matchmakingServiceProvider).startGlobalMatchmaking();

    // start animation only when searching
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _startNearbyMatchmaking() {
    setState(() {
      _isNearbySearch = true;
    });
    ref.read(matchmakingServiceProvider).startNearbyMatchmaking();

    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _cancelMatchmaking() {
    ref.read(matchmakingServiceProvider).cancelMatchmaking();

    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  void _navigateToTurnSelection(String gameId) {
    _cancelMatchmaking();

    Navigator.of(context).pushNamed(
      RouteNames.onlineTurnSelection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchmakingState = ref.watch(matchmakingStateProvider);
    final nearbyPlayers = ref.watch(nearbyPlayersProvider);

    if (matchmakingState.value == MatchmakingState.searching &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (matchmakingState.value != MatchmakingState.searching &&
        _pulseController.isAnimating) {
      _pulseController.stop();
    }

    final isSearching = matchmakingState.value == MatchmakingState.searching;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_pulseController.isAnimating) {
          _pulseController.stop();
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
                      // todo: might need to change this down the line
                      'online',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),

              if (isSearching) ...[
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _isNearbySearch ? colorYellow : colorRed,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isNearbySearch
                                ? Icons.wifi_tethering_rounded
                                : Icons.public_rounded,
                            color: _isNearbySearch ? colorBlack : colorWhite,
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Text(
                  _isNearbySearch
                      ? 'Suche nach Spielern in der Nähe'
                      : 'Suche nach Spielern online',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 20,
                      ),
                ),

                // cancel button
                OutlinedButton(
                  onPressed: _cancelMatchmaking,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    overlayColor: colorBlack,
                    side: BorderSide(
                      color: Colors.black87,
                    ),
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

                // show found players for nearby search
                if (_isNearbySearch) ...[
                  nearbyPlayers.when(
                    data: (players) {
                      if (players.isEmpty) {
                        return Text(
                          'Keine Spieler in der Nähe gefunden.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    error: (error, stackTrace) =>
                        Text('Fehler beim Laden der Spieler'),
                    loading: () => CircularProgressIndicator(
                      color: colorBlack,
                      strokeWidth: 1,
                    ),
                  ),
                ],
              ] else ...[
                // mode selection
                _buildModeButton(
                  icon: Icons.public_rounded,
                  title: 'Online Spielen',
                  subtitle: 'Gegen globale Spieler',
                  color: colorRed,
                  textColor: colorWhite,
                  onTap: _startGlobalMatchMaking,
                ),

                SizedBox(height: kTextTabBarHeight),

                _buildModeButton(
                  icon: Icons.wifi_tethering_rounded,
                  title: 'In der Nähe spielen',
                  subtitle: 'Gegen Spieler in deiner Umgebung',
                  color: colorYellowAccent,
                  textColor: colorBlack,
                  onTap: _startNearbyMatchmaking,
                ),
              ],

              // home
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 20),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          if (isSearching) {
                            _cancelMatchmaking();
                          } else {
                            Navigator.pop(context);
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
                ),
              ),
            ],
          ),
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
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(3, 3),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: textColor),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
