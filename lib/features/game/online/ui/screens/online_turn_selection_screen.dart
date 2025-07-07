import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/logic/auth_providers.dart';
import 'package:tic_tac_zwo/features/auth/ui/widgets/flag.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/player.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/ripple_icon.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/online_game_service.dart';

import '../../../../../config/game_config/config.dart';
import '../../../../navigation/routes/route_names.dart';

class OnlineTurnSelectionScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final String gameSessionId;
  final String matchMode;

  const OnlineTurnSelectionScreen({
    super.key,
    required this.gameSessionId,
    required this.matchMode,
    this.gameMode = GameMode.online,
  });

  @override
  ConsumerState<OnlineTurnSelectionScreen> createState() =>
      _OnlineTurnSelectionScreenState();
}

class _OnlineTurnSelectionScreenState
    extends ConsumerState<OnlineTurnSelectionScreen>
    with SingleTickerProviderStateMixin {
  bool _isReady = false;
  late Future<Map<String, dynamic>> _gameSessionFuture;

  Player? _player1;
  Player? _player2;
  String? _localUserId;

  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _localUserId = ref.read(currentUserIdProvider);

    _loadGameSession();
    _initHoverAnimation();
  }

  void _initHoverAnimation() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 0,
      end: 5,
    ).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeInOut,
      ),
    );

    _hoverController.repeat(reverse: true);
  }

  Player _createPlayer(Map<String, dynamic> playerData, PlayerSymbol symbol) {
    return Player(
      username: playerData['username'] ?? 'Unbekannt',
      userId: playerData['id'] ?? '',
      countryCode: playerData['country_code'] ?? '',
      symbol: symbol,
    );
  }

  void _loadGameSession() {
    _gameSessionFuture = ref
        .read(supabaseProvider)
        .from('game_sessions')
        .select(
            '*, player1:player1_id(*), player2:player2_id(*), startingPlayer:current_player_id(*)')
        .eq('id', widget.gameSessionId)
        .single();

    _gameSessionFuture.then(
      (gameSession) {
        if (!mounted) return;

        final serverPlayer1Data = gameSession['player1'];
        final serverPlayer2Data = gameSession['player2'];
        final startingPlayerData = gameSession['startingPlayer'];

        final serverPlayer1Starts =
            startingPlayerData['id'] == serverPlayer1Data['id'];

        if (serverPlayer1Starts) {
          setState(() {
            _player1 = _createPlayer(serverPlayer1Data, PlayerSymbol.X);
            _player2 = _createPlayer(serverPlayer2Data, PlayerSymbol.O);
          });
        } else {
          setState(() {
            _player1 = _createPlayer(serverPlayer2Data, PlayerSymbol.X);
            _player2 = _createPlayer(serverPlayer1Data, PlayerSymbol.O);
          });
        }
      },
    ).catchError((error) {
      print('error loading game session: $error');
    });
  }

  void _toggleReady() {
    HapticFeedback.mediumImpact();

    setState(() {
      _isReady = !_isReady;
    });

    if (_isReady) {
      ref.read(onlineGameServiceProvider).setPlayerReady(widget.gameSessionId);
    } else {
      ref
          .read(onlineGameServiceProvider)
          .setPlayerNotReady(widget.gameSessionId);
    }
  }

  void _startGame() async {
    // todo: remove after testing
    if (_player1 == null || _player2 == null) {
      print('players not initialized');
      return;
    }

    final gameConfig = GameConfig(
      players: [_player1!, _player2!],
      startingPlayer: _player1!,
      gameMode: GameMode.online,
      gameSessionId: widget.gameSessionId,
    );

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      RouteNames.gameBoard,
      arguments: gameConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameSessionStream =
        ref.watch(onlineGameStateProvider(widget.gameSessionId));

    return Scaffold(
      backgroundColor: colorGrey300,
      body: gameSessionStream.when(
        data: (sessionData) {
          if (sessionData.isEmpty) {
            return Center(child: DualProgressIndicator());
          }

          // determine readiness from stream data
          final String? streamPlayer1Id = sessionData['player1_id'];
          final String? streamPlayer2Id = sessionData['player2_id'];
          final bool p1Ready = sessionData['player1_ready'] ?? false;
          final bool p2Ready = sessionData['player2_ready'] ?? false;

          bool isOpponentActuallyReady = false;

          if (_localUserId != null) {
            if (_localUserId == streamPlayer1Id) {
              isOpponentActuallyReady = p2Ready;
            } else if (_localUserId == streamPlayer2Id) {
              isOpponentActuallyReady = p1Ready;
            } else {
              print(
                  'Debug: _localUserId ($_localUserId) does not match streamPlayer1Id ($streamPlayer1Id) or streamPlayer2Id ($streamPlayer2Id). Opponent readiness may be inaccurate temporarily.');
            }
          } else {
            print(
                'Debug: _localUserId is null. Cannot determine opponent readiness.');
          }

          print(
              'DB states from stream - P1 ready: $p1Ready, P2 ready: $p2Ready. My ready: $_isReady. Opponent ready: $isOpponentActuallyReady');

          if (isOpponentActuallyReady && _isReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                print(
                    'Both players ready (derived from gameSessionStream). Starting game...');
                _startGame();
              }
            });
          }

          if (_player1 == null || _player2 == null) {
            return Padding(
              padding: EdgeInsets.only(bottom: kToolbarHeight * 3),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DualProgressIndicator(),
              ),
            );
          }

          return Container(
            padding: EdgeInsets.only(top: 10),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // title
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        height: kToolbarHeight * 2,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            widget.matchMode,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ),

                    // Player 1
                    _buildPlayerRow(
                      _player1!.symbol == PlayerSymbol.X
                          ? _player1!
                          : _player2!,
                    )
                        .animate(delay: 450.ms)
                        .fadeIn(curve: Curves.linear, duration: 900.ms)
                        .slideX(
                          begin: -0.5,
                          end: 0.0,
                          curve: Curves.ease,
                          duration: 1200.ms,
                        ),

                    SizedBox(height: kToolbarHeight * 1.2),

                    // vs
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/versus.svg',
                        height: 60,
                        width: 60,
                        colorFilter:
                            ColorFilter.mode(Colors.black45, BlendMode.srcIn),
                      ),
                    ),

                    SizedBox(height: kToolbarHeight * 1.2),

                    // Player 2
                    _buildPlayerRow(
                      _player1!.symbol == PlayerSymbol.O
                          ? _player1!
                          : _player2!,
                      alignRight: true,
                    )
                        .animate(delay: 450.ms)
                        .fadeIn(curve: Curves.linear, duration: 900.ms)
                        .slideX(
                            begin: 0.5,
                            end: 0.0,
                            curve: Curves.ease,
                            duration: 1200.ms),

                    SizedBox(height: kToolbarHeight * 0.6),

                    // Ready button
                    GestureDetector(
                      onTap: _toggleReady,
                      child: _buildReadyButton(),
                    ),

                    // Opponent status
                    AnimatedBuilder(
                      animation: _hoverAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _hoverAnimation.value),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: _showReadyStatus(isOpponentActuallyReady),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: kToolbarHeight),
                  ],
                ),

                // back button
                Positioned(
                  bottom: 32,
                  left: 32,
                  child: SizedBox(
                    height: 52,
                    width: 52,
                    child: FloatingActionButton(
                      onPressed: () {
                        ref
                            .read(matchmakingServiceProvider)
                            .cancelMatchmaking();

                        Navigator.pushReplacementNamed(
                          context,
                          RouteNames.home,
                        );
                      },
                      backgroundColor: colorBlack.withOpacity(0.75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colorWhite,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Padding(
          // Consistent loading indicator
          padding: EdgeInsets.only(bottom: kToolbarHeight * 3),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DualProgressIndicator(),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Fehler beim Laden der Spielsitzung',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              SizedBox(height: 16),
              // home button
              // todo: add leave match button + functionality on other clients side

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
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      RouteNames.home,
                    ),
                    icon: Icon(
                      Icons.home_rounded,
                      color: colorWhite,
                      size: 24,
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

  // Helper method to build player display
  Widget _buildPlayerRow(Player player, {bool alignRight = false}) {
    final playerSymbol = Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        color: player.symbol == PlayerSymbol.X ? colorRed : colorYellow,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(3, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          player.symbol == PlayerSymbol.X ? 'X' : 'Ö',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 28,
                color:
                    player.symbol == PlayerSymbol.X ? colorWhite : colorBlack,
              ),
        ),
      ),
    );

    const space = SizedBox(width: 24);
    const flagSpace = SizedBox(width: 12);

    final playerInfo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          player.username,
          style: TextStyle(
            fontSize: 20,
            color: colorBlack,
          ),
        ),
        flagSpace,
        if (player.countryCode != null && player.countryCode!.isNotEmpty)
          Flag(
            countryCode: player.countryCode!,
            height: 12,
            width: 18,
          )
      ],
    );

    return Padding(
      padding:
          alignRight ? EdgeInsets.only(right: 50) : EdgeInsets.only(left: 50),
      child: alignRight
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [playerInfo, space, playerSymbol],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [playerSymbol, space, playerInfo],
            ),
    );
  }

  Widget _buildReadyButton() {
    if (_isReady) {
      return SizedBox(
        height: 90,
        width: 90,
        child: Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 75,
          shadows: [
            BoxShadow(
              color: colorGrey400,
              offset: Offset(5, 5),
              blurRadius: 15,
            )
          ],
        ),
      );
    } else {
      return SizedBox(
        height: 90,
        width: 90,
        child: RippleIcon(
          includeShadows: false,
          icon: Icon(
            Icons.play_arrow_rounded,
            color: colorBlack,
            size: 90,
          ),
          onTap: _toggleReady,
        ),
      ).animate(delay: 900.ms).scale(
            begin: Offset(0, -1),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
          );
    }
  }

  Widget _showReadyStatus(bool isOpponentReady) {
    if (_isReady && isOpponentReady) {
      return Text(
        'Spiel startet...',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    } else if (_isReady && !isOpponentReady) {
      return Text(
        "Warten auf Gegner...",
        style: TextStyle(
          color: Colors.orange[800]?.withOpacity(0.5),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    } else if (!_isReady && isOpponentReady) {
      return Text(
        "Gegner ist bereit. Drücke Play!",
        style: TextStyle(
          color: Colors.orange[800]?.withOpacity(0.5),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    } else {
      return Text(
        "Warten auf Spielbeginn...",
        style: TextStyle(
          color: Colors.black38,
          fontSize: 16,
        ),
      );
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }
}
