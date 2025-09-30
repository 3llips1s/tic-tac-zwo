import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_settings/app_settings.dart';

import '../../../../config/game_config/constants.dart';
import '../../logic/haptics_manager.dart';
import '../../logic/settings_notifier.dart';
import '../../logic/settings_state.dart';
import 'settings_toggle.dart';

class AudioSettingsPopup extends ConsumerWidget {
  const AudioSettingsPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      offset: const Offset(12, 10),
      color: colorWhite.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: BorderSide(
          color: colorWhite.withOpacity(0.1),
          width: 1,
        ),
      ),
      elevation: 24,
      itemBuilder: (context) => [
        // sound effects
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              const Icon(
                Icons.volume_mute_rounded,
                color: colorBlack,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                'Töne',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colorBlack,
                    ),
              ),
              const Spacer(),
              SettingsToggle(
                value: settings.soundEffectsEnabled,
                activeColor: colorBlack,
                onChanged: (value) {
                  if (value) HapticsManager.light();
                  notifier.toggleSoundEffects();
                },
              )
            ],
          ),
        ),

        //  music
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: colorBlack,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                'Musik',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colorBlack,
                    ),
              ),
              const Spacer(),
              SettingsToggle(
                value: settings.soundEffectsEnabled,
                activeColor: colorRed,
                onChanged: (value) {
                  if (value) HapticsManager.light();
                  notifier.toggleMusic();
                },
              )
            ],
          ),
        ),

        // haptics
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.vibration_rounded,
                    color: colorBlack,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Haptik',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colorBlack,
                        ),
                  ),
                  const Spacer(),
                  SettingsToggle(
                    value: settings.soundEffectsEnabled,
                    activeColor: colorYellow,
                    onChanged: (value) {
                      if (value) HapticsManager.light();
                      notifier.toggleHaptics();
                    },
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Keine Haptik?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => AppSettings.openAppSettings(
                      type: AppSettingsType.sound,
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      size: 16,
                      color: Colors.black54,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getAudioStateIcon(settings.iconState),
              color: colorGrey300,
              size: 28,
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorGrey300,
              size: 24,
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          duration: 600.ms,
          curve: Curves.easeInOut,
        )
        .fadeIn(
          duration: 600.ms,
          curve: Curves.easeInOut,
        );
  }

  IconData _getAudioStateIcon(PopupIconState state) {
    switch (state) {
      case PopupIconState.allOff:
        return Icons.volume_up_rounded;
      case PopupIconState.allOn:
        return Icons.volume_off_rounded;
      case PopupIconState.mixed:
        return Icons.volume_down_rounded;
    }
  }
}
