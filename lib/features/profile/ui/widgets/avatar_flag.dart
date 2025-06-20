import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/ui/widgets/flag.dart';

class AvatarFlag extends StatelessWidget {
  final String? avatarUrl;
  final String? countryCode;
  final double radius;

  const AvatarFlag({
    this.avatarUrl,
    this.countryCode,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: colorGrey400,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(Icons.person_rounded, size: radius, color: colorGrey100)
              : null,
        ),
        if (countryCode != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(6.0)),
              child: Flag(
                countryCode: countryCode!,
                height: radius * 0.45,
                width: radius * 0.6,
              ),
            ),
          )
      ],
    );
  }
}
