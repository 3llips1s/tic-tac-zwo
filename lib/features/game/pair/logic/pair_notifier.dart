import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/game_config.dart';
import 'package:tic_tac_zwo/features/game/core/logic/game_state.dart';
import 'package:tic_tac_zwo/features/game/pair/logic/pair_service.dart';

import '../../core/logic/game_notifier.dart';
import '../data/game_message.dart';

class PairNotifier extends GameNotifier {
  final PairService pairService;
  final _messageQueue = <GameMessage>[];
  Timer? _resendTimer;

  PairNotifier(
    super.ref,
    super.players,
    super.startingPlayer,
    this.pairService,
  ) {
    _setupMessageListener();
    _setupResendTimer();
  }

  void _setupMessageListener() {
    pairService.messages.listen(
      (message) {
        if (message.type == MessageType.cellSelection) {
          if (!isLocalPlayer) {
            super.selectCell(message.payload);
          }
        } else if (message.type == MessageType.articleSelection) {
          if (!isLocalPlayer) {
            super.makeMove(message.payload);
            _messageQueue.remove(message);
          }
        } else if (message.type == MessageType.rematch) {
          super.rematch();
        } else if (message.type == MessageType.gameState) {
          _handleSync(message.payload);
        }
      },
    );
  }

  void _setupResendTimer() {
    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_messageQueue.isNotEmpty) {
          final message = _messageQueue.first;
          pairService.sendMessage(message);
        }
      },
    );
  }

  void _handleSync(Map<String, dynamic> payload) {
    final syncedState = GameState.fromJson(payload);
    state = syncedState;
  }

  bool get isLocalPlayer {
    final localPlayerIndex = pairService.isHost ? 0 : 1;
    return state.currentPlayer == state.players[localPlayerIndex];
  }

  @override
  void selectCell(int index) {
    if (!isLocalPlayer) return;

    super.selectCell(index);
    final message = GameMessage(
      type: MessageType.cellSelection,
      payload: index,
    );
    pairService.sendMessage(message);
    _messageQueue.add(message);
  }

  @override
  void makeMove(String selectedArticle) {
    if (!isLocalPlayer) return;

    super.makeMove(selectedArticle);
    final message = GameMessage(
      type: MessageType.articleSelection,
      payload: selectedArticle,
    );
    pairService.sendMessage(message);
    _messageQueue.add(message);
  }

  @override
  void rematch() {
    _messageQueue.clear();
    super.rematch();
    pairService.sendMessage(
      GameMessage(
        type: MessageType.rematch,
        payload: null,
      ),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}

final pairStateProvider =
    StateNotifierProvider.family<PairNotifier, GameState, GameConfig>(
        (ref, config) => PairNotifier(
              ref,
              config.players,
              config.startingPlayer,
              config.pairService!,
            ));
