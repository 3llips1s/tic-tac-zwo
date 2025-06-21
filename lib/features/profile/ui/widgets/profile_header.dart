import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
// import 'package:tic_tac_zwo/features/auth/logic/auth_providers.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';
import 'package:tic_tac_zwo/features/profile/logic/user_profile_providers.dart';
import 'package:tic_tac_zwo/features/profile/ui/widgets/avatar_flag.dart';

class ProfileHeader extends ConsumerWidget {
  final UserProfile userProfile;
  final VoidCallback onEditPressed;

  const ProfileHeader({
    super.key,
    required this.userProfile,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final currentUserId = ref.watch(currentUserIdProvider);

    // todo: remove mock user data
    final currentUserId = ref.watch(mockCurrentUserIdProvider);

    return Column(
      children: [
        AvatarFlag(
          radius: 48,
          avatarUrl: userProfile.avatarUrl,
          countryCode: userProfile.countryCode,
        ),
        const SizedBox(height: 44),
        SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                userProfile.username,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                    ),
              ),
              // Edit button positioned to the right
              if (currentUserId == userProfile.id)
                Positioned(
                  right: 60,
                  bottom: -10,
                  child: IconButton(
                    icon: Center(
                      child: SvgPicture.asset(
                        'assets/images/edit.svg',
                        height: 25,
                        width: 25,
                        colorFilter:
                            ColorFilter.mode(Colors.black87, BlendMode.srcIn),
                      ),
                    ),
                    onPressed: onEditPressed,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
