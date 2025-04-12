import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/data/repositories/german_noun_repo.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/models/wordle_game_state.dart';
import 'package:tic_tac_zwo/features/game/wordle/data/repositories/worlde_word_repo.dart';
import 'package:tic_tac_zwo/features/game/wordle/logic/wordle_logic.dart';

final worldeWordRepoProvider = Provider<WorldeWordRepo>(
  (ref) {
    final nounsBox = ref.watch(nounsBoxProvider);
    final repo = WorldeWordRepo(nounsBox: nounsBox);
    repo.initialize();

    return repo;
  },
);

final wordleRepoReadyProvider = FutureProvider<bool>(
  (ref) async {
    final repo = ref.read(worldeWordRepoProvider);
    await repo.ready;
    return true;
  },
);

// game logic
final wordleLogicProvider = Provider<WordleLogic>((ref) {
  final repository = ref.watch(worldeWordRepoProvider);
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

  String getWinFeedback() {
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
