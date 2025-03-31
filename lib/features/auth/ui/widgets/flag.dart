import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

class Flag extends StatelessWidget {
  final String countryCode;

  const Flag({
    super.key,
    required this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CountryFlag.fromCountryCode(
          countryCode,
          height: 20,
          width: 30,
        ),
      ],
    );
  }
}
