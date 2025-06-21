import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/ui/widgets/flag.dart';

class AvatarFlag extends StatelessWidget {
  final String? avatarUrl;
  final String? countryCode;
  final double radius;

  const AvatarFlag({
    super.key,
    this.avatarUrl,
    this.countryCode,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
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
            right: -3,
            bottom: -3,
            child: ClipRRect(
              child: Flag(
                countryCode: countryCode!,
                height: radius * 0.45,
                width: radius * 0.6,
              ),
            ),
          ),
      ],
    );
  }
}
