import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Elementos visuales compartidos del rediseño (estilo neón/cristal sobre
/// el fondo cósmico): moneda dorada, paneles de cristal, botón principal
/// con brillo y fichas de menú con icono 3D.
class UiColors {
  UiColors._();

  static const Color gold1 = Color(0xFFFFE680);
  static const Color gold2 = Color(0xFFFFB800);
  static const Color gold3 = Color(0xFFC77700);
  static const Color goldInk = Color(0xFF4A2E00);
  static const Color blue = Color(0xFF4FA3FF);
  static const Color violet = Color(0xFF8A4BFF);
  static const Color mint = Color(0xFF3DF2A5);
  static const Color navy = Color(0xFF0B1360);

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, violet],
  );
}

/// Moneda dorada brillante, usada en el saldo y en todos los precios.
class GameCoin extends StatelessWidget {
  final double size;
  const GameCoin({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [Color(0xFFFFF6C2), UiColors.gold2, UiColors.gold3],
          stops: [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: const Color(0xFFFFE27A), width: size * 0.06),
        boxShadow: [BoxShadow(color: UiColors.gold2.withValues(alpha: 0.55), blurRadius: size * 0.45)],
      ),
      child: Center(
        child: Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: UiColors.gold3.withValues(alpha: 0.55), width: size * 0.05),
          ),
          child: Center(
            child: Text(
              r'$',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF8A5200),
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel de cristal esmerilado con borde luminoso.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius? radius;
  final double blur;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.radius,
    this.blur = 14,
    this.tint,
    this.border,
    this.shadows,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: shadows ?? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              color: tint ?? Colors.white.withValues(alpha: 0.10),
              border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;
  const GlassCircleButton({super.key, required this.child, required this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        radius: BorderRadius.circular(999),
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
  }
}

/// Icono 3D desde asset, con un icono de respaldo si la imagen falta.
class AssetIcon extends StatelessWidget {
  final String asset;
  final double size;
  final IconData fallback;
  const AssetIcon({super.key, required this.asset, required this.size, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(fallback, size: size * 0.8, color: Colors.white),
    );
  }
}

/// Pastilla con monedas (saldo): moneda dorada + cifra.
class CoinPill extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;
  const CoinPill({super.key, required this.coins, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: [UiColors.gold2.withValues(alpha: 0.30), UiColors.gold2.withValues(alpha: 0.12)]),
        border: Border.all(color: UiColors.gold1.withValues(alpha: 0.75), width: 1.2),
        boxShadow: [BoxShadow(color: UiColors.gold2.withValues(alpha: 0.35), blurRadius: 14)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameCoin(size: 26),
          const SizedBox(width: 8),
          Text('$coins', style: AppTheme.body(size: 16, weight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
    return onTap == null ? pill : GestureDetector(onTap: onTap, child: pill);
  }
}

/// Botón principal: degradado, reflejo superior y un brillo que late
/// despacio para invitar a pulsar.
class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final List<Color> colors;
  final Color glow;
  final Color textColor;
  final double height;
  final double fontSize;
  final bool pulse;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.colors = const [UiColors.blue, UiColors.violet],
    this.glow = UiColors.violet,
    this.textColor = Colors.white,
    this.height = 58,
    this.fontSize = 18,
    this.pulse = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = widget.pulse && enabled ? Curves.easeInOut.transform(_c.value) : 0.0;
          final r = BorderRadius.circular(widget.height * 0.34);
          return AnimatedScale(
            scale: _down ? 0.97 : 1,
            duration: const Duration(milliseconds: 90),
            child: Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled ? widget.colors : [Colors.white24, Colors.white12],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
                boxShadow: [
                  BoxShadow(color: widget.glow.withValues(alpha: 0.35 + 0.30 * t), blurRadius: 14 + 12 * t, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: r,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Reflejo de cristal en la mitad superior.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: widget.height * 0.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withValues(alpha: 0.38), Colors.white.withValues(alpha: 0.04)],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 10)],
                        Text(
                          widget.label,
                          style: AppTheme.body(size: widget.fontSize, weight: FontWeight.w900, color: widget.textColor)
                              .copyWith(letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ficha de menú: icono 3D grande arriba, título y subtítulo, sobre cristal
/// con un resplandor del color del modo.
class MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconAsset;
  final IconData fallbackIcon;
  final Color accent;
  final VoidCallback onTap;

  const MenuTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.fallbackIcon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        radius: BorderRadius.circular(22),
        tint: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
        shadows: [
          BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 18),
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
        ],
        child: Stack(
          children: [
            Positioned(
              top: -26,
              right: -26,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [accent.withValues(alpha: 0.45), accent.withValues(alpha: 0)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AssetIcon(asset: iconAsset, size: 52, fallback: fallbackIcon),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(size: 15, weight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(size: 11.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.65)),
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
