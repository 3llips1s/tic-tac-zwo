import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/wordle_game_state.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/repositories/word_repo.dart';
import 'package:tic_tac_zwo/features/game/wordle/logic/wordle_logic.dart';

// word repo provider
final wordRepoProvider = Provider<WordRepo>((ref) {
  return WordRepo();
});

// game logic
final wordleLogicProvider = Provider<WordleLogic>((ref) {
  final repository = ref.watch(wordRepoProvider);
  return WordleLogic(repository: repository);
});

// loading game state
final wordleLoadingProvider = FutureProvider<WordleGameState>((ref) async {
  final gameLogic = ref.watch(wordleLogicProvider);
  return await gameLogic.createNewGame();
});

// state notifier for game state
class WordleGameNotifier extends StateNotifier<WordleGameState?> {
  final WordleLogic _gameLogic;

  WordleGameNotifier(this._gameLogic) : super(null) {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    state = await _gameLogic.createNewGame();
  }

  Future<void> newGame() async {
    state = await _gameLogic.createNewGame();
  }

  Future<void> makeGuess(String guess) async {
    if (state == null) return;
    state = await _gameLogic.makeGuess(state!, guess);
  }

  Future<bool> checkArticle(String article) async {
    if (state == null) return false;
    return await _gameLogic.checkArticle(state!, article);
  }

  String winFeedback() {
    if (state == null) return 'Sehr gut!';
    return _gameLogic.winFeedback(state!);
  }
}

final wordleGameStateProvider =
    StateNotifierProvider<WordleGameNotifier, WordleGameState?>(
  (ref) {
    final gameLogic = ref.watch(wordleLogicProvider);
    return WordleGameNotifier(gameLogic);
  },
);
