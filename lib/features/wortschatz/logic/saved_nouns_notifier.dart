import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/german_noun.dart';
import 'package:tic_tac_zwo/features/wortschatz/data/models/saved_noun_hive.dart';
import 'package:tic_tac_zwo/features/wortschatz/data/repositories/saved_nouns_repo.dart';

class SavedNounsNotifier extends AutoDisposeNotifier<List<SavedNounHive>> {
  SavedNounsRepo get _repo => ref.read(savedNounsRepoProvider);

  @override
  List<SavedNounHive> build() {
    return _repo.getSavedNouns();
  }

  Future<bool> addNoun(GermanNoun noun) async {
    final bool wasAdded = await _repo.addSavedNoun(noun);
    if (wasAdded) {
      final newSavedNoun = SavedNounHive.fromGermanNoun(noun);
      state = [...state, newSavedNoun]
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    }
    return wasAdded;
  }

  Future<void> deleteNoun(String nounId) async {
    await _repo.remoteSavedNoun(nounId);
    state = state.where((n) => n.id != nounId).toList();
  }

  Future<bool> isNounSaved(String nounId) async {
    return _repo.isNounAlreadySaved(nounId);
  }

  void refreshSavedNouns() {
    state = _repo.getSavedNouns();
  }
}

final savedNounsProvider =
    AutoDisposeNotifierProvider<SavedNounsNotifier, List<SavedNounHive>>(
  () {
    return SavedNounsNotifier();
  },
);
