import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

class Flag extends StatelessWidget {
  final String? countryCode;
  final double height;
  final double width;

  const Flag({
    super.key,
    this.countryCode,
    this.height = 20,
    this.width = 30,
  });

  @override
  Widget build(BuildContext context) {
    final String? currentCode = countryCode;

    if (currentCode != null && currentCode.isNotEmpty) {
      return CountryFlag.fromCountryCode(
        currentCode,
        height: height,
        width: width,
      );
    } else {
      final double emojiSize = height * 1.4;
      return Text(
        '🌍',
        style: TextStyle(fontSize: emojiSize),
      );
    }
  }
}
