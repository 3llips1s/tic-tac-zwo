import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'settings_notifier.dart';

class AudioManager {
  static AudioManager? _instance;
  static AudioManager get instance {
    _instance ??= AudioManager._();
    return _instance!;
  }

  AudioManager._();

  late AudioPlayer _musicPlayer;
  late AudioPlayer _clickPlayer;
  late AudioPlayer _correctPlayer;
  late AudioPlayer _incorrectPlayer;
  late AudioPlayer _winPlayer;

  WidgetRef? _ref;
  bool _isInitialized = false;
  Duration _lastMusicPosition = Duration.zero;

  Future<void> initialize(WidgetRef ref) async {
    if (_isInitialized) return;

    _ref = ref;
    _musicPlayer = AudioPlayer();
    _clickPlayer = AudioPlayer();
    _correctPlayer = AudioPlayer();
    _incorrectPlayer = AudioPlayer();
    _winPlayer = AudioPlayer();

    try {
      // preload music + loop
      await _musicPlayer.setAsset('assets/sounds/background.mp3');
      await _musicPlayer.setLoopMode(LoopMode.one);

      // preload sound effects
      await _clickPlayer.setAsset('assets/sounds/click.mp3');
      await _correctPlayer.setAsset('assets/sounds/correct.mp3');
      await _incorrectPlayer.setAsset('assets/sounds/incorrect.mp3');
      await _winPlayer.setAsset('assets/sounds/win.mp3');

      _isInitialized = true;
    } catch (e) {
      developer.log('Error initializing audio: $e', name: 'AudioManager');
    }
  }

  bool get _isMusicEnabled {
    if (_ref == null) return false;
    return _ref!.read(settingsProvider).musicEnabled;
  }

  bool get _areSoundEffectsEnabled {
    if (_ref == null) return false;
    return _ref!.read(settingsProvider).soundEffectsEnabled;
  }

  Future<void> playBackgroundMusic() async {
    if (!_isInitialized || !_isMusicEnabled) return;
    try {
      if (_lastMusicPosition != Duration.zero) {
        await _musicPlayer.seek(_lastMusicPosition);
      }
      await _musicPlayer.play();
    } catch (e) {
      developer.log('Error playing background music: $e', name: 'AudioManager');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    if (!_isInitialized) return;

    try {
      _lastMusicPosition = _musicPlayer.position;
      await _musicPlayer.pause();
    } catch (e) {
      developer.log('Error pausing background music: $e', name: 'AudioManager');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_isInitialized || !_isMusicEnabled) return;

    try {
      await _musicPlayer.play();
    } catch (e) {
      developer.log('Error resuming background music: $e',
          name: 'AudioManager');
    }
  }

  Future<void> playClickSound() async {
    if (!_isInitialized || !_areSoundEffectsEnabled) return;

    try {
      await _clickPlayer.seek(Duration.zero);
      _clickPlayer.play();
    } catch (e) {
      developer.log('Error playing click sound: $e', name: 'AudioManager');
    }
  }

  Future<void> playCorrectSound() async {
    if (!_isInitialized || !_areSoundEffectsEnabled) return;

    try {
      await _correctPlayer.seek(Duration.zero);
      _correctPlayer.play();
    } catch (e) {
      developer.log('Error playing correct sound: $e', name: 'AudioManager');
    }
  }

  Future<void> playIncorrectSound() async {
    if (!_isInitialized || !_areSoundEffectsEnabled) return;

    try {
      await _incorrectPlayer.seek(Duration.zero);
      _incorrectPlayer.play();
    } catch (e) {
      developer.log('Error playing incorrect sound: $e', name: 'AudioManager');
    }
  }

  Future<void> playWinSound() async {
    if (!_isInitialized || !_areSoundEffectsEnabled) return;

    try {
      await _winPlayer.seek(Duration.zero);
      _winPlayer.play();
    } catch (e) {
      developer.log('Error playing win sound: $e', name: 'AudioManager');
    }
  }

  void dispose() {
    _musicPlayer.dispose();
    _clickPlayer.dispose();
    _correctPlayer.dispose();
    _incorrectPlayer.dispose();
    _winPlayer.dispose();
  }
}
