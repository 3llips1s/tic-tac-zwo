import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
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
  bool _isPlayerOne = false;
  String? _localUserId;

  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _loadGameSession();
    _initHoverAnimation();

    _localUserId = ref.read(supabaseProvider).auth.currentUser?.id;
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

  void _loadGameSession() {
    _gameSessionFuture = ref
        .read(supabaseProvider)
        .from('game_sessions')
        .select('*, player1:player1_id(*), player2:player2_id(*)')
        .eq('id', widget.gameSessionId)
        .single();

    _gameSessionFuture.then(
      (gameSession) {
        setState(() {
          _player1 = Player(
            userName: gameSession['player1']['username'] ?? 'Spieler 1',
            userId: gameSession['player1']['id'] ?? '',
            countryCode: gameSession['player1']['country_code'] ?? '',
            symbol: PlayerSymbol.X,
          );

          _player2 = Player(
            userName: gameSession['player2']['username'] ?? 'Spieler 2',
            userId: gameSession['player2']['id'] ?? '',
            countryCode: gameSession['player2']['country_code'] ?? '',
            symbol: PlayerSymbol.O,
          );

          _isPlayerOne = gameSession['player1']['id'] == _localUserId;
          print('Is player one: $_isPlayerOne');
        });
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

  void _startGame() {
    // todo: remove after testing
    if (_player1 == null || _player2 == null) {
      print('player not initialized');
      return;
    }

    print(
        'starting game with players: ${_player1!.userName} vs ${_player2!.userName}');

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
    // set up ready listener to start game
    ref.listen<AsyncValue<bool>>(
      opponentReadyProvider(widget.gameSessionId),
      (previous, next) {
        next.whenData(
          (isOpponentReady) {
            print(
                'opp ready state changed: $isOpponentReady, my ready state: $_isReady');

            if (isOpponentReady && _isReady) {
              print('both player ready. starting game...');
              _startGame();
            }
          },
        );
      },
    );

    return Scaffold(
      backgroundColor: colorGrey300,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gameSessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: DualProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
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
                  // Back button
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 20),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(9),
                      ),

                      // todo: add leave match to button + functionality on other clients side
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
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
            );
          }

          final gameSession = snapshot.data!;

          _player1 ??= Player(
            userName: gameSession['player1']['username'] ?? 'Spieler 1',
            userId: gameSession['player1']['id'] ?? '',
            countryCode: gameSession['player1']['country_code'],
            symbol: PlayerSymbol.X,
          );

          _player2 ??= Player(
            userName: gameSession['player2']['username'] ?? 'Spieler 2',
            userId: gameSession['player2']['id'] ?? '',
            countryCode: gameSession['player2']['country_code'],
            symbol: PlayerSymbol.O,
          );

          if (_localUserId != null) {
            _isPlayerOne = gameSession['player1']['id'] == _localUserId;
          }

          // Check opponent's ready state
          final opponentReadyState =
              ref.watch(opponentReadyProvider(widget.gameSessionId));
          final isOpponentReady = opponentReadyState.value ?? false;

          // todo: remove after testing
          //  check database directly for debugging purposes
          final player1Ready = gameSession['player1_ready'] ?? false;
          final player2Ready = gameSession['player2_ready'] ?? false;
          print('DB states - P1 ready: $player1Ready, P2 ready: $player2Ready');

          return Container(
            padding: EdgeInsets.only(top: 10),
            child: Column(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),

                // Player 1
                _buildPlayerRow(_player1!),

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
                _buildPlayerRow(_player2!, alignRight: true),

                SizedBox(height: kToolbarHeight / 1.5),

                // Ready button
                GestureDetector(
                  onTap: _isReady ? _toggleReady : null,
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
                        child: _showReadyStatus(isOpponentReady),
                      ),
                    );
                  },
                ),

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, bottom: 20, top: 10),
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
                            ref
                                .read(matchmakingServiceProvider)
                                .cancelMatchmaking();

                            Navigator.pushReplacementNamed(
                              context,
                              RouteNames.home,
                            );
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
          );
        },
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
          player.userName,
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
          color: Colors.amber,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    } else if (!_isReady && isOpponentReady) {
      return Text(
        "Gegner ist bereit. Drücke Play!",
        style: TextStyle(
          color: colorRed.withOpacity(0.5),
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
