import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Paletas del selector de personajes.
class AvatarPalette {
  AvatarPalette._();

  /// Nombres y colores representativos de los 4 tonos de piel.
  static const List<String> toneNames = ['Claro', 'Medio', 'Moreno', 'Oscuro'];
  static const List<Color> toneColors = [
    Color(0xFFF3C9A8),
    Color(0xFFD9A07A),
    Color(0xFFB07048),
    Color(0xFF6B4026),
  ];

  /// Fondos (degradados) detrás del personaje.
  static const List<List<Color>> backgrounds = [
    [Color(0xFF4FA3FF), Color(0xFF1740B8)],
    [Color(0xFFFFB347), Color(0xFFFF4D97)],
    [Color(0xFF3DF2A5), Color(0xFF0E8F8F)],
    [Color(0xFFFFE680), Color(0xFFE08A00)],
    [Color(0xFFB57BFF), Color(0xFF4A1FA8)],
    [Color(0xFFFF7A7A), Color(0xFF9E1B3C)],
    [Color(0xFF5C6BC0), Color(0xFF0B1360)],
    [Color(0xFFE9EEF7), Color(0xFF8FA3C7)],
  ];

  /// Insignias opcionales que se ponen en una esquina del personaje.
  static const List<String> badges = ['', '⭐', '👑', '🔥', '⚡', '🚀', '💎', '🏆', '❤️', '🎮'];

  /// Colores del marco que rodea al personaje.
  static const List<Color> frames = [
    Color(0xFF4FA3FF),
    Color(0xFF8A4BFF),
    Color(0xFFFF5A7A),
    Color(0xFFFF9A2E),
    Color(0xFFFFC107),
    Color(0xFF3DF2A5),
    Color(0xFF22D3EE),
    Color(0xFFFFFFFF),
  ];
}

/// Personaje de un jugador: un retrato (tono de piel + modelo, de entre 6
/// por tono) y el color del marco. Se guarda en el dispositivo.
class AvatarConfig {
  static const int tones = 4;
  static const int perTone = 6;

  final int tone;
  final int index;
  final int frame;
  final int bg;
  final int badge;

  const AvatarConfig({required this.tone, required this.index, this.frame = 0, this.bg = 0, this.badge = 0});

  static const AvatarConfig fallback = AvatarConfig(tone: 0, index: 0);

  String get asset => 'assets/avatars/a_${tone}_$index.png';
  Color get frameColor => AvatarPalette.frames[frame];
  List<Color> get bgColors => AvatarPalette.backgrounds[bg];
  String get badgeEmoji => AvatarPalette.badges[badge];

  /// Los 24 personajes, para la opción "rápido".
  static List<AvatarConfig> get presets => [
        for (var t = 0; t < tones; t++)
          for (var i = 0; i < perTone; i++) AvatarConfig(
              tone: t,
              index: i,
              frame: (t * perTone + i) % AvatarPalette.frames.length,
              bg: (t * perTone + i) % AvatarPalette.backgrounds.length,
            ),
      ];

  static AvatarConfig random() {
    final rnd = math.Random();
    return AvatarConfig(
      tone: rnd.nextInt(tones),
      index: rnd.nextInt(perTone),
      frame: rnd.nextInt(AvatarPalette.frames.length),
      bg: rnd.nextInt(AvatarPalette.backgrounds.length),
      badge: rnd.nextInt(AvatarPalette.badges.length),
    );
  }

  AvatarConfig copyWith({int? tone, int? index, int? frame, int? bg, int? badge}) => AvatarConfig(
        tone: tone ?? this.tone,
        index: index ?? this.index,
        frame: frame ?? this.frame,
        bg: bg ?? this.bg,
        badge: badge ?? this.badge,
      );

  String encode() => 'v3:$tone,$index,$frame,$bg,$badge';

  static AvatarConfig decode(String? raw) {
    if (raw == null || !raw.startsWith('v3:')) return fallback;
    final parts = raw.substring(3).split(',');
    if (parts.length != 5) return fallback;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return fallback;
    final t = nums[0]!;
    final i = nums[1]!;
    final f = nums[2]!;
    final b = nums[3]!;
    final g = nums[4]!;
    if (t < 0 || t >= tones || i < 0 || i >= perTone) return fallback;
    if (f < 0 || f >= AvatarPalette.frames.length) return fallback;
    if (b < 0 || b >= AvatarPalette.backgrounds.length) return fallback;
    if (g < 0 || g >= AvatarPalette.badges.length) return fallback;
    return AvatarConfig(tone: t, index: i, frame: f, bg: b, badge: g);
  }

  @override
  bool operator ==(Object other) =>
      other is AvatarConfig &&
      other.tone == tone &&
      other.index == index &&
      other.frame == frame &&
      other.bg == bg &&
      other.badge == badge;

  @override
  int get hashCode => Object.hash(tone, index, frame, bg, badge);
}

/// Personaje del jugador de este dispositivo, guardado en SharedPreferences.
class AvatarStore {
  AvatarStore._();

  static const _key = 'conecta4_avatar';
  static final ValueNotifier<AvatarConfig> mine = ValueNotifier<AvatarConfig>(AvatarConfig.fallback);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mine.value = AvatarConfig.decode(prefs.getString(_key));
    } catch (_) {
      // Sin acceso al almacenamiento: se queda el personaje por defecto.
    }
  }

  static Future<void> save(AvatarConfig config) async {
    mine.value = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, config.encode());
    } catch (_) {}
  }
}
