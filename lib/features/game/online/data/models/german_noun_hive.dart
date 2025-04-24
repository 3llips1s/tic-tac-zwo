import 'package:hive_ce/hive.dart';
import 'package:tic_tac_zwo/features/game/core/data/models/german_noun.dart';

part 'german_noun_hive.g.dart';

@HiveType(typeId: 1)
class GermanNounHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String noun;

  @HiveField(2)
  String article;

  @HiveField(3)
  String plural;

  @HiveField(4)
  String english;

  @HiveField(5)
  int difficulty;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  int version;

  GermanNounHive({
    required this.id,
    required this.noun,
    required this.article,
    this.plural = '',
    this.english = '',
    required this.difficulty,
    required this.updatedAt,
    required this.version,
  });

  // convert from existing noun model
  factory GermanNounHive.fromGermanNoun(GermanNoun noun, String id,
      int difficulty, DateTime updatedAt, int version) {
    return GermanNounHive(
      id: id,
      noun: noun.noun,
      article: noun.article,
      plural: noun.plural,
      english: noun.english,
      difficulty: difficulty,
      updatedAt: updatedAt,
      version: version,
    );
  }

  // convert to noun model
  GermanNoun toGermanNoun() {
    return GermanNoun(
      id: id,
      article: article,
      noun: noun,
      english: english,
      plural: plural,
    );
  }
}
