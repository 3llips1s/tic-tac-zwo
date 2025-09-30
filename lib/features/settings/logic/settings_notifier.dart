import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repo.dart';
import 'settings_state.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepo _repo;

  SettingsNotifier(this._repo) : super(SettingsState.initial()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = SettingsState(
      musicEnabled: _repo.getIsMusicEnabled(),
      soundEffectsEnabled: _repo.getIsSoundEffectsEnabled(),
      hapticsEnabled: _repo.getIsHapticsEnabled(),
    );
  }

  Future<void> toggleMusic() async {
    final newValue = !state.musicEnabled;
    await _repo.setMusicEnabled(newValue);
    state = state.copyWith(musicEnabled: newValue);
  }

  Future<void> toggleSoundEffects() async {
    final newValue = !state.soundEffectsEnabled;
    await _repo.setSoundEffectsEnabled(newValue);
    state = state.copyWith(soundEffectsEnabled: newValue);
  }

  Future<void> toggleHaptics() async {
    final newValue = !state.hapticsEnabled;
    await _repo.setHapticsEnabled(newValue);
    state = state.copyWith(hapticsEnabled: newValue);
  }
}

final settingsRepoProvider = Provider<SettingsRepo>(
  (ref) {
    return SettingsRepo();
  },
);

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final repo = ref.watch(settingsRepoProvider);
    return SettingsNotifier(repo);
  },
);
