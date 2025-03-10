import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/player_name_dialog.dart';
import 'package:tic_tac_zwo/features/game/pair/data/game_message.dart';
import 'package:tic_tac_zwo/routes/route_names.dart';

import '../../../../config/config.dart';
import '../../../../config/constants.dart';
import '../../core/data/models/player.dart';
import '../../core/ui/widgets/ripple_icon.dart';
import '../logic/pair_service.dart';

class PairTurnSelectionScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final PairService pairService;

  const PairTurnSelectionScreen(
      {super.key, required this.gameMode, required this.pairService});

  @override
  ConsumerState<PairTurnSelectionScreen> createState() =>
      _PairTurnSelectionScreenState();
}

class _PairTurnSelectionScreenState
    extends ConsumerState<PairTurnSelectionScreen> {
  late List<Player> players;
  late Player startingPlayer;
  bool isReady = false;
  bool otherPlayerReady = false;
  late StreamSubscription _messageSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayers();
    _setupMessageListener();
  }

  void _initializePlayers() async {
    final isHost = widget.pairService.isHost;
    final localDeviceName = await widget.pairService.getLocalDeviceName();
    final remoteDeviceName =
        widget.pairService.getConnectedDeviceName() ?? 'Gegner*in';

    final symbols = [PlayerSymbol.X, PlayerSymbol.O];
    if (!isHost) symbols.reversed;

    players = [
      Player(userName: localDeviceName, symbol: symbols[0]),
      Player(userName: remoteDeviceName, symbol: symbols[1]),
    ];

    startingPlayer =
        players.firstWhere((player) => player.symbol == PlayerSymbol.X);
  }

  void _setupMessageListener() {
    _messageSubscription = widget.pairService.messages.listen(
      (message) {
        if (message.type == MessageType.playerNames) {
          final data = message.payload as Map<String, dynamic>;
          setState(() {
            final remotePlayerIndex = data['playerIndex'] as int;
            players[remotePlayerIndex] = Player(
              userName: data['local'] as String,
              symbol: players[remotePlayerIndex].symbol,
            );
          });
        } else if (message.type == MessageType.ready) {
          setState(() {
            otherPlayerReady = true;
            if (isReady) {
              widget.pairService.sendMessage(GameMessage(
                type: MessageType.readyConfirm,
                payload: null,
              ));
              _startGame();
            }
          });
        } else if (message.type == MessageType.readyConfirm) {
          if (isReady && otherPlayerReady) {
            _startGame();
          }
        }
      },
    );
  }

  void _handleNameEdit() {
    showPlayerNameDialog(
      context,
      players,
      (String player1Name, String player2Name) {
        setState(() {
          final localPlayerIndex = widget.pairService.isHost ? 0 : 1;
          final remotePlayerIndex = localPlayerIndex == 0 ? 1 : 0;

          // update local name
          players[localPlayerIndex] = Player(
            userName: player1Name,
            symbol: players[localPlayerIndex].symbol,
          );

          // maintain remote player unchanged
          players[remotePlayerIndex] = Player(
            userName: players[remotePlayerIndex].userName,
            symbol: players[remotePlayerIndex].symbol,
          );

          widget.pairService.sendMessage(
            GameMessage(
              type: MessageType.playerNames,
              payload: {
                'local': player1Name,
                'playerIndex': localPlayerIndex,
              },
            ),
          );
        });
      },
    );
  }

  void _handleReadyPressed() {
    setState(() => isReady = true);
    widget.pairService.sendMessage(GameMessage(
      type: MessageType.ready,
      payload: null,
    ));

    if (otherPlayerReady) {
      widget.pairService.sendMessage(GameMessage(
        type: MessageType.readyConfirm,
        payload: null,
      ));
      _startGame();
    }
  }

  void _startGame() {
    Future.delayed(
      Duration(milliseconds: 500),
      () {
        if (mounted) {
          final gameConfig = GameConfig(
            players: players,
            startingPlayer: startingPlayer,
            gameMode: widget.gameMode,
            pairService: widget.pairService,
          );
          Navigator.pushReplacementNamed(
            context,
            RouteNames.gameBoard,
            arguments: gameConfig,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: colorGrey300,
      padding: EdgeInsets.only(bottom: 10, top: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // game mode title
          Padding(
            padding: const EdgeInsets.only(top: 10),
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

          SizedBox(height: kToolbarHeight / 2),

          // Player 1
          _buildPlayerRow(players[0]),

          SizedBox(height: kToolbarHeight * 1.5),

          // vs
          Center(
            child: SvgPicture.asset(
              'assets/images/versus.svg',
              height: 60,
              width: 60,
              colorFilter: ColorFilter.mode(Colors.black45, BlendMode.srcIn),
            ),
          ),

          SizedBox(height: kToolbarHeight * 1.5),

          // Player 2
          _buildPlayerRow(players[1], alignRight: true),

          SizedBox(height: kToolbarHeight * 1.5),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 40),
              child: GestureDetector(
                onTap: _handleNameEdit,
                child: Container(
                  height: 40,
                  width: 40,
                  color: Colors.transparent,
                  child:
                      Center(child: SvgPicture.asset('assets/images/edit.svg')),
                ),
              ),
            ),
          ),

          // start game
          RippleIcon(
            includeShadows: false,
            icon: Icon(
              isReady
                  ? Icons.check_circle_outline_rounded
                  : Icons.play_arrow_rounded,
              size: isReady ? 40 : 120,
              color: isReady ? Colors.green : colorBlack,
            ),
            onTap: isReady ? () {} : _handleReadyPressed,
          ),

          // back home
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10, top: 10),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
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
              SizedBox(width: screenWidth / 4.5),
              if (isReady || otherPlayerReady)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isReady)
                      Text(
                        'Du bist bereit.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                      ),
                    if (isReady && otherPlayerReady) Text(' ••• '),
                    if (otherPlayerReady)
                      Text(
                        'Gegner*in ist bereit.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // player symbol
  Widget _buildPlayerSymbol(Player player) {
    Offset shadowOffset = const Offset(3, 3);
    double blurRadius = 15;
    double spreadRadius = 1;

    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        color: player.symbol == PlayerSymbol.X ? colorRed : colorYellow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // bottom right
          BoxShadow(
            color: colorGrey600,
            offset: shadowOffset,
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),

          // top left
          BoxShadow(
            color: colorGrey200,
            offset: -shadowOffset,
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          )
        ],
      ),
      child: Center(
        child: Text(
          player.symbol.string,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 28,
                color:
                    player.symbol == PlayerSymbol.X ? colorWhite : colorBlack,
              ),
        ),
      ),
    );
  }

  // player symbol + name
  Widget _buildPlayerRow(
    Player player, {
    bool alignRight = false,
  }) {
    final playerSymbol = _buildPlayerSymbol(player);
    const space = SizedBox(width: 30);
    final playerName = Text(
      player.userName,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 20,
            fontStyle: player.isAI ? FontStyle.italic : FontStyle.normal,
            color: player.isAI ? Colors.black54 : colorBlack,
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
    _messageSubscription.cancel();
    super.dispose();
  }
}
