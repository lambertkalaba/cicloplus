import 'package:audioplayers/audioplayers.dart';

import '../data/store.dart';

/// Sonidos suaves de Michi (ronroneo, maullido y campanita). Respetan el
/// modo silencio del teléfono y se pueden apagar en Configuración.
class MichiSound {
  MichiSound._();

  static final _player = AudioPlayer(playerId: 'michi');
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _player.setAudioContext(AudioContextConfig(respectSilence: true, focus: AudioContextConfigFocus.mixWithOthers).build());
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
  }

  static Future<void> _play(String name, double volume) async {
    if (!AppStore.instance.showMichi || !AppStore.instance.michiSounds) return;
    try {
      await _init();
      await _player.stop();
      await _player.play(AssetSource('sounds/$name.wav'), volume: volume);
    } catch (_) {}
  }

  static Future<void> purr() => _play('purr', 0.7);
  static Future<void> meow() => _play('meow', 0.5);
  static Future<void> chime() => _play('chime', 0.45);
}
