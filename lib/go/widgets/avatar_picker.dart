import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../strings.dart';
import 'avatar_maker.dart';
import 'ui.dart';

/// Un avatar personalizable: piel + pelo, con tres posturas según la hora
/// (mañana: se estira; tarde: saluda; noche: tiene sueño).
class AvatarLook {
  const AvatarLook(this.id, this.skin, this.hair);
  final String id;
  final String skin; // s1..s5
  final String hair; // lisa, rizo, corto, afro, trenzas, mono, hijab, sinpelo, canas
}

/// Avatares para la pantalla Hoy y la opción de usar su propia foto.
class Avatars {
  Avatars._();

  static const looks = <AvatarLook>[
    AvatarLook('s1_lisa', 's1', 'lisa'),
    AvatarLook('s1_rizo', 's1', 'rizo'),
    AvatarLook('s1_sinpelo', 's1', 'sinpelo'),
    AvatarLook('s2_mono', 's2', 'mono'),
    AvatarLook('s2_hijab', 's2', 'hijab'),
    AvatarLook('s2_canas', 's2', 'canas'),
    AvatarLook('s3_afro', 's3', 'afro'),
    AvatarLook('s3_trenzas', 's3', 'trenzas'),
    AvatarLook('s3_lisa', 's3', 'lisa'),
    AvatarLook('s4_corto', 's4', 'corto'),
    AvatarLook('s4_sinpelo', 's4', 'sinpelo'),
    AvatarLook('s3_hijab', 's3', 'hijab'),
    AvatarLook('s5_lisa', 's5', 'lisa'),
    AvatarLook('s5_corto', 's5', 'corto'),
  ];

  /// Ilustraciones de antes (una sola postura).
  static const classic = ['avatar_hoy', 'avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5', 'avatar_6'];

  static const defaultLook = 's3_afro';

  static const skins = <String, Color>{
    's1': Color(0xFFF6D3B8),
    's2': Color(0xFFE2B48C),
    's3': Color(0xFFB9784F),
    's4': Color(0xFF6B4029),
    's5': Color(0xFFF3D6B5),
  };

  static List<(String, String)> get hairs => [
        ('lisa', tr('Liso', 'Straight')),
        ('rizo', tr('Rizado', 'Curly')),
        ('afro', tr('Afro', 'Afro')),
        ('trenzas', tr('Trenzas', 'Braids')),
        ('corto', tr('Corto', 'Short')),
        ('mono', tr('Moño', 'Bun')),
        ('canas', tr('Canas', 'Grey')),
        ('hijab', tr('Hiyab', 'Hijab')),
        ('sinpelo', tr('Sin pelo', 'No hair')),
      ];

  static bool isLook(String id) => looks.any((l) => l.id == id) || CustomLook.parse(id) != null;

  static bool get hasPhoto {
    final p = AppStore.instance.photoPath;
    return p != null && File(p).existsSync();
  }

  /// El avatar elegido: uno personalizable o una ilustración clásica.
  /// En Hoy siempre sale un avatar; la foto real solo se ve en Yo.
  static String get current {
    final id = AppStore.instance.avatarId;
    if (isLook(id) || classic.contains(id)) return id;
    return defaultLook;
  }

  /// Postura según la hora: m (mañana), a (tarde), n (noche).
  static String get pose {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'm';
    if (h >= 12 && h < 20) return 'a';
    return 'n';
  }

  /// Nombre de la imagen (sin extensión) para [id] en la postura de ahora.
  static String image(String id, [String? p]) =>
      CustomLook.parse(id) != null ? '$id~${p ?? pose}' : isLook(id) ? 'av_${id}_${p ?? pose}' : id;
}

/// Fila de Configuración: "Tu avatar" con la vista previa; al tocar abre la
/// hoja para elegir.
class AvatarSettings extends StatelessWidget {
  const AvatarSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _Preview(id: Avatars.current, size: 44),
        title: Text(tr('Tu avatar', 'Your avatar'), style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(tr('Elige tu piel, tu pelo y cómo te ves en la pantalla de inicio.', 'Choose your skin, your hair and how you appear on the home screen.')),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => showAvatarPicker(context),
      ),
    );
  }
}

Future<void> showAvatarPicker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: C.t(0xFFFFF4F8),
    builder: (ctx) => const _AvatarSheet(),
  );
}

class _AvatarSheet extends StatefulWidget {
  const _AvatarSheet();

  @override
  State<_AvatarSheet> createState() => _AvatarSheetState();
}

class _AvatarSheetState extends State<_AvatarSheet> {
  String? _skin;
  String? _hair;

  void _pick(String id) {
    final s = AppStore.instance;
    s.avatarId = id;
    s.commit();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cur = Avatars.current;
    final looks = Avatars.looks.where((l) => (_skin == null || l.skin == _skin) && (_hair == null || l.hair == _hair)).toList();
    final usedHairs = Avatars.looks.where((l) => _skin == null || l.skin == _skin).map((l) => l.hair).toSet();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.86,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          children: [
            Text(tr('Tu avatar', 'Your avatar'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.pinkDark)),
            const SizedBox(height: 4),
            Text(tr('Elige la que se parezca a ti. Por la mañana se estira, por la tarde te saluda y por la noche tiene sueño.',
                    'Pick the one that looks like you. In the morning she stretches, in the afternoon she waves and at night she gets sleepy.'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: C.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => showAvatarMaker(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [C.pinkSoft, Colors.white]),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: C.pink, width: 1.5),
                ),
                child: Row(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: C.pinkLine)),
                    child: ClipOval(
                      child: CustomAvatarImg(
                          id: CustomLook.parse(AppStore.instance.avatarId) != null ? AppStore.instance.avatarId : CustomLook.defaultId,
                          pose: 'a',
                          size: 64),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('✨ Crea tu avatar', '✨ Create your avatar'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.pinkDark)),
                      const SizedBox(height: 2),
                      Text(tr('Elige tu piel, tu peinado y el color de tu pelo.', 'Choose your skin, hairstyle and hair colour.'),
                          style: const TextStyle(fontSize: 12.5, color: C.muted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: C.pink),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text(tr('O elige uno ya hecho', 'Or pick a ready-made one'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.text)),
            const SizedBox(height: 14),
            Text(tr('Piel', 'Skin'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.text)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 8, children: [
              _chip(tr('Todas', 'All'), _skin == null, () => setState(() => _skin = null)),
              for (final e in Avatars.skins.entries)
                GestureDetector(
                  onTap: () => setState(() {
                    _skin = _skin == e.key ? null : e.key;
                    if (_hair != null && !Avatars.looks.any((l) => (_skin == null || l.skin == _skin) && l.hair == _hair)) _hair = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                      border: Border.all(color: _skin == e.key ? C.pinkDark : Colors.white, width: _skin == e.key ? 3 : 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)],
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            Text(tr('Pelo', 'Hair'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.text)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip(tr('Todos', 'All'), _hair == null, () => setState(() => _hair = null)),
              for (final h in Avatars.hairs)
                if (usedHairs.contains(h.$1)) _chip(h.$2, _hair == h.$1, () => setState(() => _hair = _hair == h.$1 ? null : h.$1)),
            ]),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (final l in looks) _option(l.id, cur),
              ],
            ),
            if (_skin == null && _hair == null) ...[
              const SizedBox(height: 18),
              Text(tr('Clásicas', 'Classic'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.text)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [for (final id in Avatars.classic) _option(id, cur)],
              ),
            ],
          ],
        ),
      ),
    );
  }

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

  Widget _option(String id, String cur) => GestureDetector(
        onTap: () => _pick(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: id == cur ? C.pink : C.pinkLine, width: id == cur ? 3 : 1.2),
            boxShadow: [BoxShadow(color: C.pink.withOpacity(id == cur ? 0.25 : 0.08), blurRadius: 10)],
          ),
          padding: const EdgeInsets.all(4),
          child: Stack(alignment: Alignment.center, children: [
            LayoutBuilder(builder: (_, c) => _Preview(id: id, size: c.maxWidth, pose: 'a')),
            if (id == 'photo')
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: C.pink, borderRadius: BorderRadius.circular(10)),
                  child: Text(tr('Mi foto', 'My photo'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
        ),
      );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.id, required this.size, this.pose});
  final String id;
  final double size;
  final String? pose;

  @override
  Widget build(BuildContext context) {
    if (id == 'photo') {
      return ClipOval(child: Avatar(size: size));
    }
    return ClipOval(
      child: Container(
        color: C.pinkSoft,
        width: size,
        height: size,
        child: AvatarImg(Avatars.image(id, pose), size: size),
      ),
    );
  }
}

/// Foto de perfil de Yo cuando no ha puesto su foto: su mismo avatar en
/// pose de retrato (ojos cerrados, manos en la mejilla) con una flor en el pelo.
/// Las ilustraciones clásicas ya son retratos y se enseñan tal cual.
class AvatarPortrait extends StatelessWidget {
  const AvatarPortrait({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final id = Avatars.current;
    if (Avatars.classic.contains(id)) return Img(id, size: size, fit: BoxFit.cover, fallback: Icons.face_3);
    return Container(
      width: size,
      height: size,
      color: C.pinkSoft,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        AvatarImg(Avatars.image(id, 'n'), size: size),
        Positioned(
          left: size * 0.19,
          top: size * 0.07,
          child: Image.asset('assets/go/flower_overlay.png', width: size * 0.25, fit: BoxFit.contain),
        ),
      ]),
    );
  }
}

/// Imagen de avatar: los personalizables están en assets/go/av/*.webp y las
/// ilustraciones clásicas en assets/go/*.png.
class AvatarImg extends StatelessWidget {
  const AvatarImg(this.name, {super.key, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (name.contains('~')) {
      final i = name.lastIndexOf('~');
      return CustomAvatarImg(id: name.substring(0, i), pose: name.substring(i + 1), size: size);
    }
    if (!name.startsWith('av_')) return Img(name, size: size, fallback: Icons.face_3);
    // Con otro color de app, el jersey (y el hiyab) van a juego.
    final file = C.theme == 'rosa' ? 'assets/go/av/$name.webp' : 'assets/go/avt/${name}_${C.theme}.webp';
    return Image.asset(
      file,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Icon(Icons.face_3, size: size * 0.85, color: C.pink),
    );
  }
}

/// El avatar de la pantalla Hoy: cambia de postura según la hora (se estira,
/// saluda o tiene sueño), se mueve un poquito como si respirara y, al
/// aparecer o al tocarla, saluda distinto según la hora. Al salir de la app
/// dice adiós con la mano.
class LiveAvatar extends StatefulWidget {
  const LiveAvatar({super.key, required this.id, this.size = 140, this.onEdit});
  final String id;
  final double size;
  final VoidCallback? onEdit;

  @override
  State<LiveAvatar> createState() => _LiveAvatarState();
}

class _LiveAvatarState extends State<LiveAvatar> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  // Gesto de saludo / despedida.
  late final AnimationController _g = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  bool _bye = false;

  @override
  void initState() {
    super.initState();
    AvatarBus.bye.addListener(_sayBye);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Future.delayed(const Duration(milliseconds: 350), () => mounted ? _hello() : null);
    });
  }

  @override
  void dispose() {
    AvatarBus.bye.removeListener(_sayBye);
    _c.dispose();
    _g.dispose();
    super.dispose();
  }

  void _hello() {
    setState(() => _bye = false);
    _g.forward(from: 0);
  }

  void _sayBye() {
    if (!mounted) return;
    setState(() => _bye = true);
    _g.forward(from: 0).then((_) => Future.delayed(const Duration(milliseconds: 1500), () {
          // Si la app sigue abierta (o vuelve), que se vea otra vez.
          if (!mounted) return;
          _g.value = 0;
          setState(() => _bye = false);
        }));
  }

  String _bubble(String pose) {
    if (_bye) return tr('¡Adiós! 👋', 'Bye! 👋');
    return switch (pose) {
      'm' => tr('¡Buenos días! ☀️', 'Good morning! ☀️'),
      'n' => tr('Buenas noches… 💤', 'Good night… 💤'),
      _ => tr('¡Hola! 👋', 'Hi! 👋'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = Avatars.pose;
    // Para decir adiós usa siempre la postura de saludar con la mano.
    final pose = _bye ? 'a' : now;
    final img = Avatars.image(widget.id, pose);
    return GestureDetector(
      onTap: _hello,
      onLongPress: widget.onEdit,
      child: AnimatedBuilder(
        animation: Listenable.merge([_c, _g]),
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_c.value);
          final g = _g.value; // 0..1 mientras saluda
          final on = _g.isAnimating || (_bye && g > 0);
          // Respirar: mañana se estira (sube y baja); tarde se balancea;
          // noche respira despacito.
          var angle = pose == 'a' ? (t - 0.5) * 0.05 : 0.0;
          var dy = pose == 'm' ? -t * 4 : 0.0;
          var sc = pose == 'n' ? 1 + t * 0.015 : 1.0;
          var op = 1.0;
          if (on) {
            final env = math.sin(g * math.pi); // sube y baja
            if (_bye || pose == 'a') {
              // Mueve la mano: balanceo rápido de lado a lado.
              angle += math.sin(g * math.pi * 6) * 0.11 * env;
            } else if (pose == 'm') {
              // Estiramiento: se alarga hacia arriba con un saltito.
              dy -= env * 10;
              sc *= 1 + env * 0.06;
            } else {
              // Sueño: se mece despacio, como un bostezo.
              angle += math.sin(g * math.pi * 2) * 0.06 * env;
              sc *= 1 + env * 0.03;
            }
            if (_bye && g > 0.7) op = 1 - (g - 0.7) / 0.3;
          }
          return Opacity(
            opacity: op.clamp(0.0, 1.0),
            child: Stack(clipBehavior: Clip.none, children: [
              Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(
                  alignment: Alignment.bottomCenter,
                  angle: angle * math.pi / 2,
                  child: Transform.scale(alignment: Alignment.bottomCenter, scale: sc, child: child),
                ),
              ),
              if (on)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Opacity(
                    opacity: (math.sin(g * math.pi) * 2).clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: C.pink.withValues(alpha: 0.25), blurRadius: 8)],
                      ),
                      child: Text(_bubble(pose), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: C.pinkDark)),
                    ),
                  ),
                ),
            ]),
          );
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: AvatarImg(img, key: ValueKey(img), size: widget.size),
        ),
      ),
    );
  }
}


/// Fila de Configuración: elegir el color de la app (rosa, lila, azul, menta
/// o melocotón). Todos gratis: cada una lo pone a su gusto.
class ThemeColorSettings extends StatelessWidget {
  const ThemeColorSettings({super.key});

  static String label(String v) => switch (v) {
        'lila' => tr('Lila', 'Lilac'),
        'azul' => tr('Azul', 'Blue'),
        'menta' => tr('Menta', 'Mint'),
        'melocoton' => tr('Melocotón', 'Peach'),
        _ => tr('Rosa', 'Pink'),
      };

  @override
  Widget build(BuildContext context) {
    final cur = C.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.palette_rounded, color: C.pink),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Color de la app', 'App colour'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(tr('Elige el color que más te guste.', 'Choose the colour you like best.'),
                  style: const TextStyle(color: C.muted, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          for (final v in C.themes)
            GestureDetector(
              onTap: () {
                if (v == cur) return;
                final s = AppStore.instance;
                s.themeColor = v;
                s.commit();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: C.sample(v),
                    shape: BoxShape.circle,
                    border: Border.all(color: v == cur ? C.text : Colors.white, width: v == cur ? 3 : 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 5)],
                  ),
                  child: v == cur ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
                ),
                const SizedBox(height: 4),
                Text(label(v), style: TextStyle(fontSize: 11.5, fontWeight: v == cur ? FontWeight.w900 : FontWeight.w600, color: C.text)),
              ]),
            ),
        ]),
      ]),
    );
  }
}
