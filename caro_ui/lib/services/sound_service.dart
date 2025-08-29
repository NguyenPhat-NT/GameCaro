// caro_ui/lib/services/sound_service.dart

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // --- Các hàm phát hiệu ứng âm thanh (SFX) ---
  void playClickSound() {
    // Phát âm thanh click với âm lượng 70%
    _sfxPlayer.play(AssetSource('audio/click.wav'), volume: 0.7);
  }

  void playMoveSound() {
    // Phát âm thanh đi cờ với âm lượng 100%
    _sfxPlayer.play(AssetSource('audio/move.wav'), volume: 1.0);
  }

  void playWinSound() {
    // Phát âm thanh chiến thắng với âm lượng 100%
    _sfxPlayer.play(AssetSource('audio/win.wav'), volume: 1.0);
  }

  // --- Các hàm điều khiển nhạc nền (BGM) ---
  Future<void> playBgm() async {
    // Đặt chế độ lặp lại cho nhạc nền
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

    // Phát nhạc nền với âm lượng 50%
    // Lưu ý: Tên file nhạc nền của bạn phải được đặt ở đây
    await _bgmPlayer.play(AssetSource('audio/bgm.mp3'), volume: 0.5);
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }
}
