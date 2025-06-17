import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/german_noun.dart';
import 'package:tic_tac_zwo/features/wortschatz/data/saved_nouns_source.dart';

import '../models/saved_noun_hive.dart';

class SavedNounsRepo {
  final SavedNounsSource _dataSource;

  SavedNounsRepo(this._dataSource);

  Future<bool> addSavedNoun(GermanNoun noun) async {
    final savedNoun = SavedNounHive.fromGermanNoun(noun);
    return _dataSource.saveNoun(savedNoun);
  }

  Future<void> remoteSavedNoun(String nounId) async {
    await _dataSource.deleteNoun(nounId);
  }

  List<SavedNounHive> getSavedNouns() {
    return _dataSource.getAllSavedNouns();
  }

  Future<bool> isNounAlreadySaved(String nounId) async {
    return _dataSource.isNounSaved(nounId);
  }
}

final savedNounsRepoProvider = Provider<SavedNounsRepo>(
  (ref) {
    final dataSource = ref.read(savedNounsSourceProvider);
    return SavedNounsRepo(dataSource);
  },
);
