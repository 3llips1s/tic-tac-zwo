import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/german_noun_repo.dart';

class GermanNoun {
  final String article;
  final String noun;
  final String english;
  final String plural;

  const GermanNoun({
    required this.article,
    required this.noun,
    required this.english,
    required this.plural,
  });

  factory GermanNoun.fromJson(Map<String, dynamic> json) => GermanNoun(
        article: json['article'] as String,
        noun: json['noun'] as String,
        english: json['english'] as String,
        plural: json['plural'] as String,
      );
}

class NounRepository {
  final GermanNounRepo _germanNounRepo;

  NounRepository(this._germanNounRepo);

  Future<List<GermanNoun>> loadNouns() async {
    return _germanNounRepo.loadNouns();
  }

  void removeUsedNoun(GermanNoun noun) {
    _germanNounRepo.removeUsedNoun(noun);
  }

  Future<GermanNoun> loadRandomNoun() async {
    return _germanNounRepo.loadRandomNoun();
  }

  void resetNouns() {
    _germanNounRepo.resetNouns();
  }
}

final nounRepositoryProvider = Provider((ref) {
  final nounRepo = ref.watch(germanNounRepoProvider);
  return NounRepository(nounRepo);
});
final nounsProvider = FutureProvider<List<GermanNoun>>((ref) {
  return ref.read(nounRepositoryProvider).loadNouns();
});
final randomNounProvider = FutureProvider<GermanNoun>((ref) {
  return ref.read(nounRepositoryProvider).loadRandomNoun();
});
