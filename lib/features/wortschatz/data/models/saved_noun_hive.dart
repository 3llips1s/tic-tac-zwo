import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/german_noun.dart';

part 'saved_noun_hive.g.dart';

@HiveType(typeId: 2)
class SavedNounHive extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String article;

  @HiveField(2)
  final String noun;

  @HiveField(3)
  final String plural;

  @HiveField(4)
  final String english;

  @HiveField(5)
  final DateTime savedAt;

  SavedNounHive({
    required this.id,
    required this.article,
    required this.noun,
    this.plural = '',
    this.english = '',
    required this.savedAt,
  });

  factory SavedNounHive.fromGermanNoun(GermanNoun noun) {
    return SavedNounHive(
      id: noun.id,
      article: noun.article,
      noun: noun.noun,
      plural: noun.plural,
      english: noun.english,
      savedAt: DateTime.now(),
    );
  }

  // override equality and hashcode for easier comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SavedNounHive && other.id == id && other.noun == noun;
  }

  @override
  int get hashCode => id.hashCode ^ noun.hashCode;
}
