import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';

import '../../../../../config/config.dart';
import '../../../../../config/constants.dart';
import '../../data/models/player.dart';

class PlayerNameDialog extends StatefulWidget {
  final List<Player> players;
  final Function(String, String) onNamesSubmitted;
  final bool singlePlayerEdit;

  const PlayerNameDialog({
    super.key,
    required this.players,
    required this.onNamesSubmitted,
    this.singlePlayerEdit = false,
  });

  @override
  State<PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<PlayerNameDialog> {
  late TextEditingController player1Controller;
  late TextEditingController player2Controller;

  @override
  void initState() {
    super.initState();
    player1Controller = TextEditingController(text: widget.players[0].userName);
    player2Controller = TextEditingController(text: widget.players[1].userName);
  }

  void handleSubmittedNames() {
    widget.onNamesSubmitted(
      player1Controller.text.trim(),
      player2Controller.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Name editieren:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorBlack,
              ),
        ),
        const SizedBox(height: kToolbarHeight / 3),
        if (!widget.singlePlayerEdit ||
            widget.players[0].userName == widget.players[0].userName)
          _buildPlayerInput(
            context: context,
            symbol: widget.players[0].symbol,
            controller: player1Controller,
            enabled: !widget.singlePlayerEdit ||
                widget.players[0].userName == widget.players[0].userName,
          ),
        if (!widget.singlePlayerEdit)
          const SizedBox(height: kToolbarHeight / 3),

        if (!widget.singlePlayerEdit)
          _buildPlayerInput(
              context: context,
              symbol: widget.players[1].symbol,
              controller: player2Controller,
              enabled: !widget.singlePlayerEdit),

        // consider using a snackbar for errors instead.

        const SizedBox(height: kToolbarHeight / 2),
      ],
    );
  }

  @override
  void dispose() {
    player1Controller.dispose();
    player2Controller.dispose();
    super.dispose();
  }
}

void showPlayerNameDialog(
  BuildContext context,
  List<Player> players,
  Function(String, String) onNamesSubmitted,
) {
  final dialogState = GlobalKey<_PlayerNameDialogState>();

  if (context.mounted) {
    showCustomDialog(
      context: context,
      height: 350,
      width: 300,
      child: PlayerNameDialog(
        key: dialogState,
        players: players,
        onNamesSubmitted: onNamesSubmitted,
      ),
      actions: [
        // cancel
        GlassMorphicButton(
          onPressed: () => Navigator.pop(context),
          child: Icon(
            Icons.close_rounded,
            color: colorRed,
            size: 35,
          ),
        ),

        // save
        GlassMorphicButton(
          onPressed: () {
            final state = dialogState.currentState;
            if (state != null) {
              state.handleSubmittedNames();
            }
          },
          child: Icon(
            Icons.done_rounded,
            color: colorYellowAccent,
            size: 35,
          ),
        ),
      ],
    );
  }
}

Widget _buildPlayerInput({
  required BuildContext context,
  required PlayerSymbol symbol,
  required TextEditingController controller,
  bool enabled = true,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // symbol
      Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: symbol == PlayerSymbol.X ? colorRed : colorYellow,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            symbol.string,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  color: symbol == PlayerSymbol.X ? colorWhite : colorBlack,
                ),
          ),
        ),
      ),
      const SizedBox(width: 20),

      // text field
      Expanded(
        child: TextField(
          enabled: enabled,
          showCursor: enabled,
          cursorColor: Colors.black54,
          controller: controller,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
              ),
          decoration: InputDecoration(
            hintText: 'Name',
            hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                fontSize: 16),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: symbol == PlayerSymbol.X ? colorRed : colorYellow,
                    width: 2)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorBlack,
                width: 1,
              ),
            ),
          ),
          maxLength: 9,
          buildCounter: (context,
                  {required currentLength, required isFocused, maxLength}) =>
              Text(
            '0${9 - currentLength}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black38,
                ),
          ),
        ),
      ),
    ],
  );
}
