import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/logic/auth_providers.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/glassmorphic_dialog.dart';
import 'package:tic_tac_zwo/features/profile/logic/user_profile_providers.dart';
import 'package:tic_tac_zwo/features/profile/ui/widgets/wdl_test.dart';

import '../../../navigation/routes/route_names.dart';
import '../widgets/edit_username_dialog.dart';
import '../widgets/games_history_list.dart';
import '../widgets/profile_header.dart';
import '../widgets/stats_grid.dart';
// import '../widgets/wdl_bar.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    showCustomDialog(
      context: context,
      height: 300,
      width: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            'Konto löschen?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Bist du sicher? Alle deine Daten gehen für immer verloren.\n \nDiese Aktion kann nicht rückgängig gemacht werden.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ),
          const SizedBox(height: 12)
        ],
      ),
      actions: [
        // Cancel Button
        GlassMorphicButton(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'abbrechen',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
        ),
        // Delete Button
        GlassMorphicButton(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          onPressed: () async {
            Navigator.of(context).pop();

            try {
              await Supabase.instance.client.functions.invoke('delete-user');

              // on success, navigate to home and show a snackbar
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(RouteNames.home, (route) => false);

                _showSnackBar(
                    context, 'Dein Konto wurde erfolgreich gelöscht.');
              }
            } catch (e) {
              // handle errors
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Fehler beim Löschen des Kontos: ${e.toString()}')),
                );
              }
            }
          },
          child: Text(
            ' LÖSCHEN ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color.fromARGB(255, 201, 1, 1),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(
          bottom: kToolbarHeight,
          left: 40,
          right: 40,
        ),
        content: Container(
            padding: EdgeInsets.all(12),
            height: kToolbarHeight,
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            child: Center(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                    ),
              ),
            )),
      ),
    );
  }

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

                    const SizedBox(height: 64),

                    if (userProfile.id == ref.watch(currentUserIdProvider))
                      Center(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            overlayColor: colorBlack,
                            side: BorderSide(color: colorRed),
                          ),
                          onPressed: () =>
                              _showDeleteConfirmationDialog(context, ref),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            child: Text(
                              'Konto löschen?',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorBlack,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                        ),
                      ),
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
