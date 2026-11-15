import 'dart:io';

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../screens/reminders.dart';

/// Colores de la maqueta (verde selva + rosa).
class C {
  static const emerald = Color(0xFF1B8A5A);
  static const emeraldDark = Color(0xFF0B5E3B);
  static const pink = Color(0xFFE8457F);
  static const pinkDark = Color(0xFFD81B60);
  static const red = Color(0xFFE5284F);
  static const pinkSoft = Color(0xFFFFE1EC);
  static const pinkLine = Color(0xFFF7CADB);
  static const pinkBg = Color(0xFFFFF2F7);
  static const lavender = Color(0xFFB79CEB);
  static const lavenderSoft = Color(0xFFE7DCFA);
  static const purple = Color(0xFF7B4FD6);
  static const greenSoft = Color(0xFFE2F3E2);
  static const green = Color(0xFF2E9E4F);
  static const text = Color(0xFF2B2230);
  static const muted = Color(0xFF7E7183);
  static const blue = Color(0xFF3BA3D9);
  static const orange = Color(0xFFF29B38);
}

/// Tarjeta rosada translúcida con borde blanco (estilo de la foto).
BoxDecoration card({Color? color, double radius = 22}) => BoxDecoration(
  color: color ?? Colors.white.withOpacity(0.62),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.3),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFFD0407A).withOpacity(0.10),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ],
);

/// Baldosa interior (botones, cifras) blanca con borde rosado.
BoxDecoration tile({bool selected = false, double radius = 16}) =>
    BoxDecoration(
      color: selected ? null : Colors.white.withOpacity(0.92),
      gradient: selected ? pinkGradient : null,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: selected ? C.pink : const Color(0xFFF6D3E1),
        width: selected ? 1.6 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFD0407A).withOpacity(selected ? 0.28 : 0.07),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

const pinkGradient = LinearGradient(
  colors: [Color(0xFFF2588F), Color(0xFFD81B60)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

/// Imagen de assets/img con icono de reserva si falta.
class Img extends StatelessWidget {
  final String name;
  final double size;
  final IconData fallback;
  final Color fallbackColor;
  final BoxFit fit;
  const Img(
    this.name, {
    super.key,
    this.size = 32,
    this.fallback = Icons.circle,
    this.fallbackColor = C.pink,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/go/$name.png',
    width: size,
    height: size,
    fit: fit,
    errorBuilder: (_, __, ___) =>
        Icon(fallback, size: size * 0.85, color: fallbackColor),
  );
}

/// Foto de perfil: la de la usuaria si la puso, si no la ilustración.
class Avatar extends StatelessWidget {
  final double size;
  const Avatar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final path = AppStore.instance.photoPath;
    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Img(
          'avatar',
          size: size,
          fit: BoxFit.cover,
          fallback: Icons.face_3,
        ),
      );
    }
    return Img('avatar', size: size, fit: BoxFit.cover, fallback: Icons.face_3);
  }
}

/// Fondo rosa de todas las pantallas.
class PinkBackground extends StatelessWidget {
  final Widget child;
  const PinkBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFFCE6F0), Color(0xFFF9D9E7), Color(0xFFFBE3EE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: child,
  );
}

/// Borde inferior ondulado de la cabecera.
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path()..lineTo(0, s.height - 18);
    p.cubicTo(
      s.width * 0.22,
      s.height - 2,
      s.width * 0.42,
      s.height - 30,
      s.width * 0.62,
      s.height - 16,
    );
    p.cubicTo(
      s.width * 0.8,
      s.height - 4,
      s.width * 0.92,
      s.height - 10,
      s.width,
      s.height - 24,
    );
    p.lineTo(s.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Cabecera verde selva con hojas (y hibiscos), logo, menú y campana.
class GreenHeader extends StatelessWidget {
  final String? title;
  final VoidCallback? onMenu;
  final VoidCallback? onBack;
  final VoidCallback? onBell;
  final bool bellDot;
  final bool flowers;

  const GreenHeader({
    super.key,
    this.title,
    this.onMenu,
    this.onBack,
    this.onBell,
    this.bellDot = true,
    this.flowers = false,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final corner = flowers ? 'header_flowers' : 'header_leaves';
    final cw = flowers ? 104.0 : 92.0;
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        padding: EdgeInsets.only(top: top),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B5E3B), Color(0xFF187A4C), Color(0xFF0E6842)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -8,
              bottom: 0,
              child: Img(
                corner,
                size: cw,
                fallback: Icons.eco,
                fallbackColor: const Color(0xFF3FA866),
              ),
            ),
            Positioned(
              right: -8,
              bottom: 0,
              child: Transform.flip(
                flipX: true,
                child: Img(
                  corner,
                  size: cw,
                  fallback: Icons.eco,
                  fallbackColor: const Color(0xFF3FA866),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(6, 2, 6, title == null ? 26 : 30),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack ?? onMenu,
                        icon: Icon(
                          onBack != null
                              ? Icons.arrow_back_ios_new_rounded
                              : Icons.menu_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const Expanded(child: Center(child: Logo())),
                      IconButton(
                        onPressed:
                            onBell ??
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SubPage(
                                  title: 'Recordatorios',
                                  child: const RemindersScreen(),
                                ),
                              ),
                            ),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            if (bellDot)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B6B),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Img(
          'logo_flower',
          size: 28,
          fallback: Icons.local_florist,
          fallbackColor: Colors.white,
        ),
        const SizedBox(width: 6),
        const Text(
          'CicloPlus',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Título de sección con icono rosa.
class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;
  const SectionTitle(this.icon, this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: C.pink, size: 20),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: C.text,
          ),
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

/// Botón grande rosa.
class PinkButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;
  const PinkButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? C.pinkDark : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: outlined ? null : pinkGradient,
          color: outlined ? Colors.white : null,
          border: outlined ? Border.all(color: C.pink, width: 1.6) : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: C.pink.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastilla pequeña de color.
class Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? img;
  final Color color;
  final Color bg;
  const Pill(
    this.text, {
    super.key,
    this.icon,
    this.img,
    this.color = C.emerald,
    this.bg = C.greenSoft,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (img != null) ...[
          Img(
            img!,
            size: 20,
            fallback: icon ?? Icons.eco,
            fallbackColor: color,
          ),
          const SizedBox(width: 5),
        ] else if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Opción seleccionable (fondo blanco, borde rosa y check cuando está activa).
class Choice extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  const Choice({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: padding,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFFFE3EE)
                  : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? C.pink : const Color(0xFFF3D6E2),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD0407A)
                      .withOpacity(selected ? 0.18 : 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(child: child),
          ),
          if (selected)
            Positioned(
              right: -5,
              top: -7,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: C.pink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Página secundaria con cabecera verde y botón atrás.
class SubPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottom;
  const SubPage({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PinkBackground(
        child: Column(
          children: [
            GreenHeader(
              title: title,
              onBack: () => Navigator.of(context).pop(),
              bellDot: false,
            ),
            Expanded(child: child),
            if (bottom != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: bottom,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Selector numérico − valor +.
class Stepper2 extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;
  const Stepper2({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _btn(Icons.remove, value > min ? () => onChanged(value - 1) : null),
      SizedBox(
        width: 74,
        child: Text(
          '$value$suffix',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: C.text,
          ),
        ),
      ),
      _btn(Icons.add, value < max ? () => onChanged(value + 1) : null),
    ],
  );

  Widget _btn(IconData i, VoidCallback? f) => InkWell(
    onTap: f,
    borderRadius: BorderRadius.circular(20),
    child: CircleAvatar(
      radius: 17,
      backgroundColor: f == null ? const Color(0xFFF3E9EE) : C.pinkSoft,
      child: Icon(i, size: 18, color: f == null ? C.muted : C.pinkDark),
    ),
  );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.emeraldDark,
      duration: const Duration(seconds: 2),
    ),
  );
}
