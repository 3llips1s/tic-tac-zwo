import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/player_name_dialog.dart';
import 'package:tic_tac_zwo/routes/route_names.dart';

import '../../../../../config/config.dart';
import '../../../../../config/constants.dart';
import '../../data/models/game_config.dart';
import '../../data/models/player.dart';
import '../widgets/ripple_icon.dart';

class TurnSelectionScreen extends StatefulWidget {
  final GameMode gameMode;

  const TurnSelectionScreen({
    super.key,
    required this.gameMode,
  });

  @override
  State<TurnSelectionScreen> createState() => _TurnSelectionScreenState();
}

class _TurnSelectionScreenState extends State<TurnSelectionScreen> {
  late List<Player> players;
  late Player startingPlayer;

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  void _initializePlayers() {
    final playerSymbols = <PlayerSymbol>[PlayerSymbol.X, PlayerSymbol.O];
    playerSymbols.shuffle();

    if (widget.gameMode == GameMode.offline) {
      players = [
        Player(userName: 'Du', symbol: playerSymbols[0], isAI: false),
        Player(userName: 'nicht AI', symbol: playerSymbols[1], isAI: true),
      ];
    } else if (widget.gameMode == GameMode.pass) {
      players = [
        Player(userName: 'Du', symbol: playerSymbols[0]),
        Player(userName: 'Freund*in', symbol: playerSymbols[1]),
      ];
    } else {
      players = [
        Player(userName: 'Tic', symbol: playerSymbols[0]),
        Player(userName: 'Tac', symbol: playerSymbols[1]),
      ];
    }

    print('Players initialized:');
    players.forEach((player) {
      print(
          'Name: ${player.userName}, Symbol: ${player.symbol}, Is AI: ${player.isAI}');
    });

    startingPlayer =
        players.firstWhere((player) => player.symbol == PlayerSymbol.X);
  }

  void _handleNameEdit() {
    showPlayerNameDialog(
      context,
      players,
      (String player1Name, String player2Name) {
        setState(() {
          players = [
            Player(userName: player1Name, symbol: players[0].symbol),
            Player(userName: player2Name, symbol: players[1].symbol),
          ];
        });
      },
    );
  }

  void _startGame() async {
    final gameConfig = GameConfig(
      players: players,
      startingPlayer: startingPlayer,
      gameMode: widget.gameMode,
    );

    Navigator.pushReplacementNamed(
      context,
      RouteNames.gameBoard,
      arguments: gameConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorGrey300,
      padding: EdgeInsets.only(top: 10),
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

          SizedBox(height: kToolbarHeight / 1.5),

          // Player 1
          _buildPlayerRow(players[0]),

          SizedBox(height: kToolbarHeight * 1.2),

          // vs
          Center(
            child: SvgPicture.asset(
              'assets/images/versus.svg',
              height: 60,
              width: 60,
              colorFilter: ColorFilter.mode(Colors.black45, BlendMode.srcIn),
            ),
          ),

          SizedBox(height: kToolbarHeight * 1.2),

          // Player 2
          _buildPlayerRow(players[1], alignRight: true),

          SizedBox(height: kToolbarHeight * 1.5),

          if (widget.gameMode == GameMode.pass) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 40),
                child: GestureDetector(
                  onTap: _handleNameEdit,
                  child: Container(
                    height: 30,
                    width: 30,
                    color: Colors.transparent,
                    child: Center(
                        child: SvgPicture.asset('assets/images/edit.svg')),
                  ),
                ),
              ),
            ),
          ],

          // start game
          RippleIcon(
            includeShadows: false,
            icon: Icon(
              Icons.play_arrow_rounded,
              size: 120,
            ),
            onTap: _startGame,
          ),

          // back home
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 20, top: 10),
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
}
