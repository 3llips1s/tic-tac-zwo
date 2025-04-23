import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';

class OnlineTurnSelection extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final String gameSessionId;

  const OnlineTurnSelection({
    super.key,
    required this.gameMode,
    required this.gameSessionId,
  })
}
