import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/features/wortschatz/data/models/saved_noun_hive.dart';

class SavedNounsSource {
  // open box lazily
  Box<SavedNounHive> get _savedNounsBox =>
      Hive.box<SavedNounHive>('saved_nouns');

  Future<bool> saveNoun(SavedNounHive noun) async {
    if (await isNounSaved(noun.id)) {
      return false;
    }
    await _savedNounsBox.put(noun.id, noun);

    return true;
  }

  Future<void> deleteNoun(String nounId) async {
    await _savedNounsBox.delete(nounId);
  }

  List<SavedNounHive> getAllSavedNouns() {
    final List<SavedNounHive> nouns = _savedNounsBox.values.toList();
    nouns.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return nouns;
  }

  Future<bool> isNounSaved(String nounId) async {
    final bool contains = _savedNounsBox.containsKey(nounId);
    return contains;
  }
}

final savedNounsSourceProvider = Provider<SavedNounsSource>(
  (ref) {
    return SavedNounsSource();
  },
);
