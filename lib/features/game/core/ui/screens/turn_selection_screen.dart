import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/player_name_dialog.dart';
import 'package:tic_tac_zwo/features/navigation/routes/route_names.dart';

import '../../../../../config/game_config/config.dart';
import '../../../../../config/game_config/constants.dart';
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
  AIDifficulty _selectedDifficulty = AIDifficulty.medium;

  @override
  void initState() {
    super.initState();
    _initializePlayers();
    _loadSavedDifficulty();
  }

  void _initializePlayers() {
    final playerSymbols = <PlayerSymbol>[PlayerSymbol.X, PlayerSymbol.O];
    playerSymbols.shuffle();

    if (widget.gameMode == GameMode.offline) {
      players = [
        Player(username: 'Du', symbol: playerSymbols[0], isAI: false),
        Player(username: 'Zwö', symbol: playerSymbols[1], isAI: true),
      ];
    } else if (widget.gameMode == GameMode.pass) {
      players = [
        Player(username: 'Tic', symbol: playerSymbols[0]),
        Player(username: 'Tac', symbol: playerSymbols[1]),
      ];
    } else {
      players = [
        Player(username: 'Tic', symbol: playerSymbols[0]),
        Player(username: 'Tac', symbol: playerSymbols[1]),
      ];
    }

    startingPlayer =
        players.firstWhere((player) => player.symbol == PlayerSymbol.X);
  }

  Future<void> _loadSavedDifficulty() async {
    final preferences = Hive.box('user_preferences');
    final savedDifficulty = preferences.get('ai_difficulty');
    if (savedDifficulty != null) {
      final loadedDifficulty = AIDifficulty.fromHiveKey(savedDifficulty);
      if (mounted) {
        setState(() {
          _selectedDifficulty = loadedDifficulty;
        });
      }
      setState(() {
        _selectedDifficulty = AIDifficulty.fromHiveKey(savedDifficulty);
      });
    }
  }

  Future<void> _saveDifficulty(AIDifficulty difficulty) async {
    final preferences = Hive.box('user_preferences');
    await preferences.put('ai_difficulty', difficulty.hiveKey);
  }

  void _handleNameEdit() {
    showPlayerNameDialog(
      context,
      players,
      (String player1Name, String player2Name) {
        setState(
          () {
            players = [
              Player(username: player1Name, symbol: players[0].symbol),
              Player(username: player2Name, symbol: players[1].symbol),
            ];
            startingPlayer =
                players.firstWhere((player) => player.symbol == PlayerSymbol.X);
          },
        );
      },
    );
  }

  void _startGame() async {
    final gameConfig = GameConfig(
      players: players,
      startingPlayer: startingPlayer,
      gameMode: widget.gameMode,
      difficulty:
          widget.gameMode == GameMode.offline ? _selectedDifficulty : null,
    );

    Navigator.pushReplacementNamed(
      context,
      RouteNames.gameBoard,
      arguments: gameConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    final xPlayer = players.firstWhere((p) => p.symbol == PlayerSymbol.X);
    final oPlayer = players.firstWhere((p) => p.symbol == PlayerSymbol.O);

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Stack(
          children: [
            Column(
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

                SizedBox(height: kToolbarHeight * 0.3),

                // Player 1
                _buildPlayerRow(xPlayer)
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
                _buildPlayerRow(oPlayer, alignRight: true)
                    .animate(delay: 450.ms)
                    .fadeIn(curve: Curves.linear, duration: 900.ms)
                    .slideX(
                      begin: 0.5,
                      end: 0.0,
                      curve: Curves.ease,
                      duration: 1200.ms,
                    ),

                SizedBox(
                  height: widget.gameMode == GameMode.pass ||
                          widget.gameMode == GameMode.offline
                      ? kToolbarHeight
                      : kToolbarHeight * 1.3,
                ),

                if (widget.gameMode == GameMode.pass) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 50),
                      child: GestureDetector(
                        onTap: _handleNameEdit,
                        child: Container(
                          height: 30,
                          width: 30,
                          color: Colors.transparent,
                          child: Center(
                            child: SvgPicture.asset('assets/images/edit.svg'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (widget.gameMode == GameMode.offline) ...[
                  _buildDifficultySelector(),
                ],

                // start game
                RippleIcon(
                  includeShadows: false,
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    size: 120,
                  ),
                  onTap: _startGame,
                ).animate(delay: 900.ms).scale(
                      begin: Offset(0, -1),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOut,
                    ),

                SizedBox(height: kToolbarHeight * 1.5),
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
                  onPressed: () => Navigator.pop(context),
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
        borderRadius: BorderRadius.circular(8),
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
      player.username,
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

  Widget _buildDifficultySelector() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 34,
        ),
        child: PopupMenuButton<AIDifficulty>(
          position: PopupMenuPosition.under,
          onSelected: (AIDifficulty difficulty) async {
            setState(() {
              _selectedDifficulty = difficulty;
            });
            await _saveDifficulty(difficulty);
          },
          itemBuilder: (BuildContext context) => AIDifficulty.values
              .map(
                (difficulty) => PopupMenuItem<AIDifficulty>(
                  value: difficulty,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                          color: difficulty.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        difficulty.string,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: difficulty == _selectedDifficulty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: difficulty == _selectedDifficulty
                                  ? difficulty.color
                                  : colorBlack.withOpacity(0.3),
                            ),
                      ),
                      if (difficulty == _selectedDifficulty) ...[
                        const Spacer(),
                        Icon(
                          Icons.check_rounded,
                          color: difficulty.color,
                          size: 22,
                        ),
                      ]
                    ],
                  ),
                ),
              )
              .toList(),
          color: colorWhite.withOpacity(0.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
              side: BorderSide(
                color: colorWhite.withOpacity(0.1),
                width: 1,
              )),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Text(
                      _selectedDifficulty.string,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedDifficulty.color,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1,
                      width: _selectedDifficulty.string.length * 6.5,
                      color: _selectedDifficulty.color,
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _selectedDifficulty.color,
                  size: 30,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
