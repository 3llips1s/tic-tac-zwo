import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/constants.dart';

class WordleKeyboard extends StatelessWidget {
  final Function(String)? onKeyTap;
  final Map<String, Color> letterStates;

  const WordleKeyboard({
    super.key,
    this.onKeyTap,
    this.letterStates = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: colorBlack,
      child: Column(
        children: [
          _buildKeyRow(['Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P', 'Ü']),
          const SizedBox(height: 8),
          _buildKeyRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ö', 'Ä']),
          const SizedBox(height: 8),
          _buildKeyRow(['↵ ', 'Y', 'X', 'C', 'V', 'B', 'N', 'M', 'ß', '←']),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String letter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: letterStates.containsKey(letter)
            ? letterStates[letter]
            : colorGrey300,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onKeyTap != null ? () => onKeyTap!(letter) : null,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: letter.length > 1 ? 50 : 30,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    letterStates.containsKey(letter) ? colorWhite : colorBlack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
