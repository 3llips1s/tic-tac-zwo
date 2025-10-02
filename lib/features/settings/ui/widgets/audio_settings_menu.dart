import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/game_config/constants.dart';
import '../../logic/haptics_manager.dart';
import '../../logic/settings_notifier.dart';
import '../../logic/settings_state.dart';
import 'settings_toggle.dart';

class AudioSettingsMenu extends ConsumerStatefulWidget {
  const AudioSettingsMenu({super.key});

  @override
  ConsumerState<AudioSettingsMenu> createState() => _AudioSettingsMenuState();
}

class _AudioSettingsMenuState extends ConsumerState<AudioSettingsMenu> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showMenu() {
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideMenu,
        child: Stack(
          children: [
            Positioned(
              width: 240,
              child: CompositedTransformFollower(
                link: _layerLink,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: Offset(175, 7),
                child: Material(
                  color: colorWhite.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(9),
                  elevation: 24,
                  child: _MenuContent(onClose: _hideMenu),
                ).animate().fadeIn(duration: 600.ms).scaleY(
                      begin: 0,
                      end: 1,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                    ),
              ),
            )
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          HapticsManager.light();
          if (_overlayEntry == null) {
            _showMenu();
          } else {
            _hideMenu();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCurrentStateIcon(settings.iconState),
                color: colorGrey300,
                size: 28,
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorGrey300,
                size: 24,
              )
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCurrentStateIcon(PopupIconState state) {
    switch (state) {
      case PopupIconState.allOn:
        return Icons.volume_up_rounded;
      case PopupIconState.allOff:
        return Icons.volume_off_rounded;
      case PopupIconState.mixed:
        return Icons.volume_down_rounded;
    }
  }
}

class _MenuContent extends ConsumerWidget {
  final VoidCallback onClose;

  const _MenuContent({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // Töne
          _MenuItem(
            icon: Icons.volume_mute_rounded,
            label: 'Töne',
            value: settings.soundEffectsEnabled,
            activeColor: colorBlack,
            onChanged: (value) {
              if (value) HapticsManager.light();
              notifier.toggleSoundEffects();
            },
          ),
          const SizedBox(height: 16),

          // Musik
          _MenuItem(
            icon: Icons.music_note_rounded,
            label: 'Musik',
            value: settings.musicEnabled,
            activeColor: colorRed,
            onChanged: (value) {
              if (value) HapticsManager.light();
              notifier.toggleMusic();
            },
          ),
          const SizedBox(height: 16),

          // Haptik
          _MenuItem(
            icon: Icons.vibration_rounded,
            label: 'Haptik',
            value: settings.hapticsEnabled,
            activeColor: colorYellow,
            onChanged: (value) {
              if (value) HapticsManager.light();
              notifier.toggleHaptics();
            },
          ),
          const SizedBox(height: 16),

          // Help text
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Keine Haptik?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  onClose();
                  AppSettings.openAppSettings(type: AppSettingsType.sound);
                },
                child: const Icon(
                  Icons.settings_rounded,
                  size: 28,
                  color: colorBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 24),
        const SizedBox(width: 16),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: colorBlack,
              ),
        ),
        const Spacer(),
        SettingsToggle(
          value: value,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
