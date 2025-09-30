class SettingsState {
  final bool musicEnabled;
  final bool soundEffectsEnabled;
  final bool hapticsEnabled;

  const SettingsState({
    required this.musicEnabled,
    required this.soundEffectsEnabled,
    required this.hapticsEnabled,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      musicEnabled: true,
      soundEffectsEnabled: true,
      hapticsEnabled: true,
    );
  }

  SettingsState copyWith({
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    bool? hapticsEnabled,
  }) {
    return SettingsState(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  // popup icon state helper
  PopupIconState get iconState {
    final enabledCount = [musicEnabled, soundEffectsEnabled, hapticsEnabled]
        .where((enabled) => enabled)
        .length;

    if (enabledCount == 3) return PopupIconState.allOn;
    if (enabledCount == 0) return PopupIconState.allOff;
    return PopupIconState.mixed;
  }
}

enum PopupIconState { allOn, allOff, mixed }
