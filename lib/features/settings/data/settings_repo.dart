import 'package:hive_ce/hive.dart';

class SettingsRepo {
  static const String _boxName = 'user_preferences';
  static const String _musicKey = 'music_enabled';
  static const String _soundEffectsKey = 'sound_effects_enabled';
  static const String _hapticsKey = 'haptics_enabled';

  Box get _box => Hive.box(_boxName);

  bool getIsMusicEnabled() {
    return _box.get(_musicKey, defaultValue: true);
  }

  bool getIsSoundEffectsEnabled() {
    return _box.get(_soundEffectsKey, defaultValue: true);
  }

  bool getIsHapticsEnabled() {
    return _box.get(_hapticsKey, defaultValue: true);
  }

  Future<void> setMusicEnabled(bool value) async {
    await _box.put(_musicKey, value);
  }

  Future<void> setSoundEffectsEnabled(bool value) async {
    await _box.put(_soundEffectsKey, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    await _box.put(_hapticsKey, value);
  }
}
