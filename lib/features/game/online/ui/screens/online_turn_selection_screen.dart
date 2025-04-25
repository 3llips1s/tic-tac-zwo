import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/player.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/matchmaking_service.dart';
import 'package:tic_tac_zwo/features/game/online/data/services/online_game_service.dart';

import '../../../../../config/game_config/config.dart';
import '../../../../navigation/routes/route_names.dart';

class OnlineTurnSelectionScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final String gameSessionId;

  const OnlineTurnSelectionScreen({
    super.key,
    required this.gameSessionId,
    this.gameMode = GameMode.online,
  });

  @override
  ConsumerState<OnlineTurnSelectionScreen> createState() =>
      _OnlineTurnSelectionScreenState();
}

class _OnlineTurnSelectionScreenState
    extends ConsumerState<OnlineTurnSelectionScreen> {
  bool _isReady = false;
  late Future<Map<String, dynamic>> _gameSessionFuture;

  late Player player1;
  late Player player2;
  bool isPlayerOne = false;

  @override
  void initState() {
    super.initState();
    _loadGameSession();
  }

  void _loadGameSession() {
    _gameSessionFuture = ref
        .read(supabaseProvider)
        .from('game_sessions')
        .select('*, player1:player1_id(*), player2:player2_id(*)')
        .eq('id', widget.gameSessionId)
        .single();
  }

  void _toggleReady() {
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
    final gameConfig = GameConfig(
      players: [player1, player2],
      startingPlayer: player1,
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
      (_, next) {
        next.whenData(
          (isOpponentReady) {
            if (isOpponentReady && _isReady) {
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
              child: CircularProgressIndicator(
                color: colorBlack,
                strokeWidth: 1,
              ),
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

          final player1 = Player(
            userName: gameSession['player1']['username'] ?? 'Spieler 1',
            userId: gameSession['player1']['id'] ?? '',
            symbol: PlayerSymbol.X,
          );

          final player2 = Player(
            userName: gameSession['player2']['username'] ?? 'Spieler 2',
            userId: gameSession['player2']['id'] ?? '',
            symbol: PlayerSymbol.O,
          );

          // Check opponent's ready state
          final isOpponentReady =
              ref.watch(opponentReadyProvider(widget.gameSessionId)).value ??
                  false;

          return Container(
            padding: EdgeInsets.only(top: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // title
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: kToolbarHeight * 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        GameMode.online.string,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: kToolbarHeight / 1.5),

                // Player 1
                _buildPlayerRow(player1),

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
                _buildPlayerRow(player2, alignRight: true),

                SizedBox(height: kToolbarHeight * 2),

                // Ready button
                GestureDetector(
                  onTap: _toggleReady,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 70,
                    width: 200,
                    decoration: BoxDecoration(
                      color: _isReady ? Colors.green : Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(3, 3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isReady
                                ? Icons.check_circle
                                : Icons.play_arrow_rounded,
                            color: colorWhite,
                            size: 32,
                          ),
                          SizedBox(width: 10),
                          Text(
                            _isReady ? "Bereit!" : "Spielen",
                            style: TextStyle(
                              color: colorWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Opponent status
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: isOpponentReady
                      ? Text(
                          "Gegner ist bereit!",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : Text(
                          "Warten auf Gegner...",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
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
                            Navigator.pop(context);
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
        borderRadius: BorderRadius.circular(12),
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
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: player.symbol == PlayerSymbol.X ? colorWhite : colorBlack,
          ),
        ),
      ),
    );

    const space = SizedBox(width: 30);

    final playerName = Text(
      player.userName,
      style: TextStyle(
        fontSize: 20,
        color: colorBlack,
      ),
    );

    return Padding(
      padding:
          alignRight ? EdgeInsets.only(right: 50) : EdgeInsets.only(left: 50),
      child: alignRight
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [playerName, space, playerSymbol],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [playerSymbol, space, playerName],
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
