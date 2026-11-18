import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../strings.dart';
import 'avatar_lum.dart';
import 'avatar_picker.dart';
import 'ui.dart';

/// Avatar hecho por ella misma: piel + peinado + color de pelo.
/// Se guarda como avatarId = 'c_<piel>_<peinado>_<color>' (p. ej. c_s3_afro_negro).
/// Las piezas están en assets/go/avc/ y se montan una vez en una imagen:
///   b_<piel>_<postura>[_<tema>].webp  base (cara, cuerpo, pendientes, jersey)
///   c_<peinado>_<postura>.webp        lo que hay que borrar de la base (cabeza calva)
///   r_<peinado>_<postura>_<piel>.webp bordes y detalles del peinado (con su tono de piel)
///   h_<peinado>_<postura>.webp        el pelo (se recolorea)
class CustomLook {
  const CustomLook(this.skin, this.hair, this.color);
  final String skin;
  final String hair;
  final String color;

  static const skins = <String, Color>{
    's5': Color(0xFFF8DCC8),
    's1': Color(0xFFF2C6A2),
    's2': Color(0xFFD9A07A),
    's3': Color(0xFFA8693F),
    's4': Color(0xFF6E4128),
  };

  static const hairs = ['ondas', 'lisa', 'rizo', 'afro', 'trenzas', 'bob', 'pixie', 'mono', 'coleta', 'hijab', 'sinpelo'];

  static String hairLabel(String h) => switch (h) {
        'ondas' => tr('Ondas', 'Waves'),
        'lisa' => tr('Liso', 'Straight'),
        'rizo' => tr('Rizos', 'Curls'),
        'afro' => tr('Afro', 'Afro'),
        'trenzas' => tr('Trenzas', 'Braids'),
        'bob' => tr('Media melena', 'Bob'),
        'pixie' => tr('Corto', 'Pixie'),
        'mono' => tr('Moño', 'Bun'),
        'coleta' => tr('Coleta', 'Ponytail'),
        'hijab' => tr('Hiyab', 'Hijab'),
        _ => tr('Sin pelo', 'No hair'),
      };

  /// Color de pelo: (color, contraste). 'castano' es el original.
  static const colors = <String, (Color, double)?>{
    'castano': null,
    'negro': (Color(0xFF1E1714), 0.7),
    'rubio': (Color(0xFFD9B26A), 1.3),
    'pelirrojo': (Color(0xFFB5482A), 1.1),
    'canoso': (Color(0xFFC9C6C4), 1.3),
    'rosa': (Color(0xFFF08FB8), 1.2),
    'azul': (Color(0xFF6F8FE0), 1.2),
  };

  static Color colorSample(String c) => switch (c) {
        'castano' => const Color(0xFF6B3A24),
        _ => colors[c]!.$1,
      };

  static String colorLabel(String c) => switch (c) {
        'negro' => tr('Negro', 'Black'),
        'rubio' => tr('Rubio', 'Blonde'),
        'pelirrojo' => tr('Pelirrojo', 'Red'),
        'canoso' => tr('Canoso', 'Grey'),
        'rosa' => tr('Rosa', 'Pink'),
        'azul' => tr('Azul', 'Blue'),
        _ => tr('Castaño', 'Brown'),
      };

  static const defaultId = 'c_s1_ondas_castano';

  String get id => 'c_${skin}_${hair}_$color';

  CustomLook copy({String? skin, String? hair, String? color}) => CustomLook(skin ?? this.skin, hair ?? this.hair, color ?? this.color);

  static CustomLook? parse(String id) {
    if (!id.startsWith('c_')) return null;
    final p = id.split('_');
    if (p.length != 4) return null;
    if (!skins.containsKey(p[1]) || !hairs.contains(p[2]) || !colors.containsKey(p[3])) return null;
    return CustomLook(p[1], p[2], p[3]);
  }

  static ColorFilter _tint(Color t, double s, double m) {
    final r = t.r * 255, g = t.g * 255, b = t.b * 255;
    return ColorFilter.matrix(<double>[
      0.3 * s, 0.59 * s, 0.11 * s, 0, r - m * s, //
      0.3 * s, 0.59 * s, 0.11 * s, 0, g - m * s,
      0.3 * s, 0.59 * s, 0.11 * s, 0, b - m * s,
      0, 0, 0, 1, 0,
    ]);
  }

  /// Filtro para el pelo del retrato de Yo (las capas ph_ tienen el pelo en
  /// gris con brillo medio 100). El hiyab va a juego con el color de la app.
  ColorFilter? portraitFilter() {
    if (hair == 'hijab') return _tint(C.t(0xFFE7A9CC), 1.05, 100);
    final c = colors[color];
    if (c == null) return null;
    return _tint(c.$1, c.$2, 100);
  }

  /// Filtro para el pelo (o el hiyab, que va a juego con el color de la app).
  ColorFilter? hairFilter(String pose) {
    final m = avatarHairLum['${hair}_$pose'] ?? 76;
    if (hair == 'hijab') return _tint(C.t(0xFFE7A9CC), 1.05, m);
    final c = colors[color];
    if (c == null) return null;
    return _tint(c.$1, c.$2, m);
  }
}

/// Monta el avatar (base + peinado) en una sola imagen y la guarda en memoria.
class AvatarMaker {
  AvatarMaker._();
  static const _dir = 'assets/go/avc';
  static final _cache = <String, ui.Image>{};
  static final _loading = <String, Future<ui.Image?>>{};

  static String _key(String id, String pose) => '$id|$pose|${C.theme}';

  static ui.Image? cached(String id, String pose) => _cache[_key(id, pose)];

  static Future<ui.Image?> _load(String path) async {
    try {
      final d = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(d.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> build(String id, String pose) {
    final k = _key(id, pose);
    final c = _cache[k];
    if (c != null) return Future.value(c);
    return _loading[k] ??= _compose(id, pose).then((im) {
      _loading.remove(k);
      if (im != null) {
        if (_cache.length > 40) _cache.clear();
        _cache[k] = im;
      }
      return im;
    });
  }

  static Future<ui.Image?> _compose(String id, String pose) async {
    final l = CustomLook.parse(id);
    if (l == null) return null;
    final th = C.theme;
    ui.Image? base;
    if (th != 'rosa') base = await _load('$_dir/b_${l.skin}_${pose}_$th.webp');
    base ??= await _load('$_dir/b_${l.skin}_$pose.webp');
    if (base == null) return null;
    ui.Image? hair, rest, cut;
    if (l.hair != 'sinpelo') {
      final r = await Future.wait([
        _load('$_dir/h_${l.hair}_$pose.webp'),
        _load('$_dir/r_${l.hair}_${pose}_${l.skin}.webp'),
        _load('$_dir/c_${l.hair}_$pose.webp'),
      ]);
      hair = r[0];
      rest = r[1];
      cut = r[2];
    }
    final w = base.width.toDouble(), h = base.height.toDouble();
    final dst = Rect.fromLTWH(0, 0, w, h);
    final rec = ui.PictureRecorder();
    final cv = Canvas(rec, dst);
    void draw(ui.Image? im, Paint p) {
      if (im == null) return;
      p.filterQuality = FilterQuality.medium;
      cv.drawImageRect(im, Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()), dst, p);
    }

    cv.saveLayer(dst, Paint());
    draw(base, Paint());
    draw(cut, Paint()..blendMode = BlendMode.dstOut);
    draw(rest, Paint());
    final f = l.hairFilter(pose);
    draw(hair, f == null ? Paint() : (Paint()..colorFilter = f));
    cv.restore();
    return rec.endRecording().toImage(base.width, base.height);
  }
}

/// Imagen de un avatar hecho por ella.
class CustomAvatarImg extends StatefulWidget {
  const CustomAvatarImg({super.key, required this.id, required this.pose, required this.size});
  final String id;
  final String pose;
  final double size;

  @override
  State<CustomAvatarImg> createState() => _CustomAvatarImgState();
}

class _CustomAvatarImgState extends State<CustomAvatarImg> {
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    _get();
  }

  @override
  void didUpdateWidget(CustomAvatarImg old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id || old.pose != widget.pose) _get();
  }

  void _get() {
    final c = AvatarMaker.cached(widget.id, widget.pose);
    if (c != null) {
      _img = c;
      return;
    }
    final id = widget.id, pose = widget.pose;
    AvatarMaker.build(id, pose).then((im) {
      if (!mounted || id != widget.id || pose != widget.pose) return;
      setState(() => _img = im);
    });
  }

  @override
  Widget build(BuildContext context) {
    final im = _img;
    if (im == null) return SizedBox(width: widget.size, height: widget.size);
    return RawImage(image: im, width: widget.size, height: widget.size, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
  }
}

/// Hoja para crear tu propio avatar.
Future<void> showAvatarMaker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: C.t(0xFFFFF4F8),
    builder: (ctx) => const _MakerSheet(),
  );
}

class _MakerSheet extends StatefulWidget {
  const _MakerSheet();

  @override
  State<_MakerSheet> createState() => _MakerSheetState();
}

class _MakerSheetState extends State<_MakerSheet> {
  late CustomLook _l = CustomLook.parse(AppStore.instance.avatarId) ?? CustomLook.parse(CustomLook.defaultId)!;
  final String _pose = Avatars.pose;

  void _save() {
    final s = AppStore.instance;
    s.avatarId = _l.id;
    s.commit();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void initState() {
    super.initState();
    // Prepara las tres posturas para que el cambio sea inmediato.
    for (final p in const ['m', 'a', 'n']) {
      AvatarMaker.build(_l.id, p);
    }
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.text)),
      );

  Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: on ? C.pinkDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? C.pinkDark : C.pinkLine),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: on ? Colors.white : C.pinkDark)),
        ),
      );

  Widget _dot(Color c, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: on ? C.pinkDark : Colors.white, width: on ? 3 : 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
          ),
          child: on ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
        ),
      );

  void _set(CustomLook l) {
    setState(() => _l = l);
    for (final p in const ['m', 'a', 'n']) {
      AvatarMaker.build(l.id, p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showColor = _l.hair != 'hijab' && _l.hair != 'sinpelo';
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(children: [
          Text(tr('Crea tu avatar', 'Create your avatar'),
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.pinkDark)),
          const SizedBox(height: 8),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(color: C.pinkSoft, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4),
                boxShadow: [BoxShadow(color: C.pink.withValues(alpha: 0.2), blurRadius: 14)]),
            child: ClipOval(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: CustomAvatarImg(key: ValueKey('${_l.id}$_pose'), id: _l.id, pose: _pose, size: 182),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              children: [
                _title(tr('Piel', 'Skin')),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  for (final e in CustomLook.skins.entries) _dot(e.value, _l.skin == e.key, () => _set(_l.copy(skin: e.key))),
                ]),
                _title(tr('Peinado', 'Hairstyle')),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final h in CustomLook.hairs) _chip(CustomLook.hairLabel(h), _l.hair == h, () => _set(_l.copy(hair: h))),
                ]),
                if (showColor) ...[
                  _title(tr('Color de pelo', 'Hair colour')),
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    for (final c in CustomLook.colors.keys)
                      Tooltip(
                        message: CustomLook.colorLabel(c),
                        child: _dot(CustomLook.colorSample(c), _l.color == c, () => _set(_l.copy(color: c))),
                      ),
                  ]),
                ],
                const SizedBox(height: 10),
                Text(
                    tr('Por la mañana se estira, por la tarde te saluda y por la noche tiene sueño. Si sales de la app, te dice adiós.',
                        'In the morning she stretches, in the afternoon she waves and at night she gets sleepy. When you leave the app, she says goodbye.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: C.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.pink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                onPressed: _save,
                child: Text(tr('Usar este avatar', 'Use this avatar'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Avisos al avatar de la pantalla Hoy (por ejemplo, decir adiós al salir).
class AvatarBus {
  AvatarBus._();
  static final bye = ValueNotifier<int>(0);
}

/// Retrato de Yo (ojos cerrados, manos bajo la mejilla y una flor), el mismo
/// avatar de Hoy. Está en assets/go/avp/:
///   p_<piel>_<peinado>.webp   el retrato tal cual (pelo castaño)
///   pg_<piel>_<peinado>.webp  el mismo con el pelo (o el hiyab) marcado
///   ph_<piel>_<peinado>.webp  solo el pelo en gris, para recolorearlo
class PortraitMaker {
  PortraitMaker._();
  static const _dir = 'assets/go/avp';
  static final _cache = <String, ui.Image>{};
  static final _loading = <String, Future<ui.Image?>>{};

  static String _key(String id) => '$id|${C.theme}';

  static ui.Image? cached(String id) => _cache[_key(id)];

  static Future<ui.Image?> build(String id) {
    final k = _key(id);
    final c = _cache[k];
    if (c != null) return Future.value(c);
    return _loading[k] ??= _compose(id).then((im) {
      _loading.remove(k);
      if (im != null) {
        if (_cache.length > 20) _cache.clear();
        _cache[k] = im;
      }
      return im;
    });
  }

  static Future<ui.Image?> _compose(String id) async {
    final l = CustomLook.parse(id);
    if (l == null) return null;
    final n = '${l.skin}_${l.hair}';
    final f = l.hair == 'sinpelo' ? null : l.portraitFilter();
    if (f == null) return AvatarMaker._load('$_dir/p_$n.webp');
    final r = await Future.wait([AvatarMaker._load('$_dir/pg_$n.webp'), AvatarMaker._load('$_dir/ph_$n.webp')]);
    final base = r[0], hair = r[1];
    if (base == null || hair == null) return AvatarMaker._load('$_dir/p_$n.webp');
    final w = base.width.toDouble(), h = base.height.toDouble();
    final dst = Rect.fromLTWH(0, 0, w, h);
    final rec = ui.PictureRecorder();
    final cv = Canvas(rec, dst);
    final q = FilterQuality.medium;
    cv.drawImage(base, Offset.zero, Paint()..filterQuality = q);
    cv.drawImageRect(hair, Rect.fromLTWH(0, 0, hair.width.toDouble(), hair.height.toDouble()), dst, Paint()
      ..filterQuality = q
      ..colorFilter = f);
    return rec.endRecording().toImage(base.width, base.height);
  }
}

/// Imagen del retrato de un avatar hecho por ella.
class PortraitImg extends StatefulWidget {
  const PortraitImg({super.key, required this.id, required this.size});
  final String id;
  final double size;

  @override
  State<PortraitImg> createState() => _PortraitImgState();
}

class _PortraitImgState extends State<PortraitImg> {
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    _get();
  }

  @override
  void didUpdateWidget(PortraitImg old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) _get();
  }

  void _get() {
    final c = PortraitMaker.cached(widget.id);
    if (c != null) {
      _img = c;
      return;
    }
    final id = widget.id;
    PortraitMaker.build(id).then((im) {
      if (!mounted || id != widget.id) return;
      setState(() => _img = im);
    });
  }

  @override
  Widget build(BuildContext context) {
    final im = _img;
    if (im == null) return SizedBox(width: widget.size, height: widget.size);
    return RawImage(image: im, width: widget.size, height: widget.size, fit: BoxFit.cover, filterQuality: FilterQuality.medium);
  }
}
