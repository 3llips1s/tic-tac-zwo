import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/settings/logic/settings_notifier.dart';

import 'audio_manager.dart';

class AudioSettingsListener extends ConsumerStatefulWidget {
  final Widget child;

  const AudioSettingsListener({super.key, required this.child});

  @override
  ConsumerState<AudioSettingsListener> createState() =>
      _AudioSettingsListenerState();
}

class _AudioSettingsListenerState extends ConsumerState<AudioSettingsListener> {
  bool? _previousMusicEnabled;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    if (_previousMusicEnabled != null &&
        _previousMusicEnabled != settings.musicEnabled) {
      // only resume if music should be playing
      if (settings.musicEnabled) {
        AudioManager.instance.resumeBackgroundMusic();
      } else if (!settings.musicEnabled) {
        AudioManager.instance.pauseBackgroundMusic();
      }
    }

    _previousMusicEnabled = settings.musicEnabled;

    return widget.child;
  }
}
