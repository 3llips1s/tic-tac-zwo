import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/logic/auth_providers.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';
import 'package:tic_tac_zwo/features/profile/ui/widgets/avatar_flag.dart';

class ProfileHeader extends ConsumerWidget {
  final UserProfile userProfile;

  const ProfileHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AvatarFlag(
          radius: 48,
          avatarUrl: userProfile.avatarUrl,
          countryCode: userProfile.countryCode,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  userProfile.username,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorBlack,
                      ),
                ),
                if (currentUserId == userProfile.id) const SizedBox(width: 8),
                IconButton(
                  icon: Center(
                    child: SvgPicture.asset(
                      'assets/images/edit.svg',
                      height: 20,
                      width: 20,
                    ),
                  ),
                  onPressed: _showEditUsernameDialog(context, ref, userProfile),
                )
              ],
            )
          ],
        )
      ],
    );
  }
}
