import 'package:tic_tac_zwo/features/game/wordle/data/models/letter_match.dart';

class WordGuess {
  final String word;
  final List<LetterMatch> matches;

  WordGuess({required this.word, required this.matches});
}
