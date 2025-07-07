import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/profile/logic/user_profile_providers.dart';
import 'package:tic_tac_zwo/features/profile/ui/widgets/wdl_test.dart';

import '../widgets/edit_username_dialog.dart';
import '../widgets/games_history_list.dart';
import '../widgets/profile_header.dart';
import '../widgets/stats_grid.dart';
// import '../widgets/wdl_bar.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider(userId));

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Stack(
        children: [
          userProfileAsync.when(
            loading: () => const Center(
              child: DualProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
            data: (userProfile) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  32.0,
                  MediaQuery.of(context).padding.top + 40.0,
                  32.0,
                  MediaQuery.of(context).padding.bottom + 60.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeader(
                        userProfile: userProfile,
                        onEditPressed: () {
                          showEditUsernameDialog(context, ref, userProfile);
                        }),
                    const SizedBox(height: 48),
                    // todo: remove test bar
                    WdlBarTest()
                        .animate(delay: 600.ms)
                        .slideX(
                          begin: 0.3,
                          duration: 900.ms,
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(
                          duration: 900.ms,
                          curve: Curves.easeInOut,
                        ),
                    // WdlBar(userProfile: userProfile),
                    const SizedBox(height: 64),
                    StatsGrid(userProfile: userProfile)
                        .animate(delay: 1200.ms)
                        .scale(
                          duration: 1500.ms,
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(
                          begin: 0.0,
                          duration: 1500.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 16),

                    GamesHistoryList(userId: userId),
                  ],
                ),
              );
            },
          ),

          // back button
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 24),
              child: SizedBox(
                height: 52,
                width: 52,
                child: FloatingActionButton(
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: colorBlack.withOpacity(0.75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colorWhite,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
