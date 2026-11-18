import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Piezas visuales de la parte de pareja (Invitar a tu pareja y la entrada
/// "solo ver el seguimiento de mi pareja"), según la maqueta elegante hecha
/// con ChatGPT: cabecera en degradado, tarjeta-sobre con sello dorado,
/// tarjetas blancas muy redondeadas y chips de acciones.
class PartnerUi {
  PartnerUi._();

  static const gold = Color(0xFFD4A24C);
  static const goldSoft = Color(0xFFF3DFB5);

  static BoxDecoration card({Color color = Colors.white, double radius = 24}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8A1C46).withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      );
}

/// Cabecera en degradado con el logo pequeño, flecha de volver y el título.
class PartnerHeader extends StatelessWidget implements PreferredSizeWidget {
  const PartnerHeader({super.key, required this.title, required this.primary, required this.primaryDark, this.actions = const []});

  final String title;
  final Color primary;
  final Color primaryDark;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final side = actions.length > 1 ? 96.0 : 48.0;
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryDark, primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(children: [
          // Corazón dorado de línea fina como adorno, como en la maqueta.
          Positioned(
            right: 14,
            bottom: 10,
            child: Icon(Icons.favorite_border_rounded, size: 46, color: PartnerUi.goldSoft.withOpacity(0.30)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  SizedBox(
                    width: side,
                    child: canPop
                        ? IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          )
                        : null,
                  ),
                  const Expanded(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.favorite_border_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 5),
                      Text('CicloPlus', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  SizedBox(width: side, child: actions.isEmpty ? null : Row(mainAxisAlignment: MainAxisAlignment.end, children: actions)),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Tarjeta con forma de sobre: solapa rosa arriba y un sello dorado con un
/// corazón en el centro. Debajo, [child].
class InviteEnvelopeCard extends StatelessWidget {
  const InviteEnvelopeCard({super.key, required this.primary, required this.label, required this.child});

  final Color primary;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PartnerUi.card(color: const Color(0xFFFFF8FA)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        SizedBox(
          height: 64,
          child: Stack(alignment: Alignment.topCenter, children: [
            Positioned.fill(child: CustomPaint(painter: _FlapPainter(primary))),
            Positioned(
              top: 14,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFF1CF85), PartnerUi.gold], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: PartnerUi.gold.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(children: [
            Row(children: [
              const Expanded(child: _GoldLine()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(label.toUpperCase(),
                    style: const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
              ),
              const Expanded(child: _GoldLine()),
            ]),
            const SizedBox(height: 14),
            child,
          ]),
        ),
      ]),
    );
  }
}

class _GoldLine extends StatelessWidget {
  const _GoldLine();
  @override
  Widget build(BuildContext context) => Container(
        height: 1.2,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0x00D4A24C), PartnerUi.gold, Color(0x00D4A24C)])),
      );
}

class _FlapPainter extends CustomPainter {
  _FlapPainter(this.primary);
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [primary.withOpacity(0.30), primary.withOpacity(0.12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 6)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.55, size.width / 2, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.55, 0, 6)
      ..close();
    canvas.drawPath(path, paint);
    final line = Paint()
      ..color = PartnerUi.gold.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final edge = Path()
      ..moveTo(0, 6)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.55, size.width / 2, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.55, size.width, 6);
    canvas.drawPath(edge, line);
  }

  @override
  bool shouldRepaint(covariant _FlapPainter old) => old.primary != primary;
}

/// Botón principal en degradado, de ancho completo.
class PartnerButton extends StatelessWidget {
  const PartnerButton({super.key, required this.label, required this.primary, required this.primaryDark, this.onPressed, this.icon, this.loading = false, this.height = 50});

  final String label;
  final Color primary;
  final Color primaryDark;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(colors: [primary, primaryDark]),
            boxShadow: [BoxShadow(color: primary.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(height / 2),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
                      Flexible(
                        child: Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón secundario con borde.
class PartnerOutlineButton extends StatelessWidget {
  const PartnerOutlineButton({super.key, required this.label, required this.primary, this.onPressed, this.icon, this.height = 50});

  final String label;
  final Color primary;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: Colors.white,
          side: BorderSide(color: primary.withOpacity(0.55), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(height / 2)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 7)],
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
        ]),
      ),
    );
  }
}

/// Campo de texto redondeado con icono a la izquierda.
class PartnerField extends StatelessWidget {
  const PartnerField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.primary,
    this.errorText,
    this.onChanged,
    this.code = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color primary;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool code;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: primary.withOpacity(0.18)),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: code ? TextCapitalization.characters : TextCapitalization.sentences,
      style: TextStyle(
        fontSize: code ? 17 : 15,
        letterSpacing: code ? 2 : 0,
        fontWeight: code ? FontWeight.w800 : FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 15, letterSpacing: 0, fontWeight: FontWeight.w500, color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        enabledBorder: border,
        border: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: primary, width: 1.6)),
        errorText: errorText,
        errorMaxLines: 3,
        errorStyle: const TextStyle(fontSize: 11.5),
      ),
    );
  }
}

/// Chip pequeño de acción (Chat, Deseos, Compartir ciclo…).
class PartnerChip extends StatelessWidget {
  const PartnerChip({super.key, required this.icon, required this.label, required this.primary, this.onTap, this.active = true});

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fg = active ? primary : AppColors.textMuted;
    return Material(
      color: active ? primary.withOpacity(0.09) : const Color(0xFFF2EEF0),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: fg)),
          ]),
        ),
      ),
    );
  }
}

/// Avatar redondo con la inicial y un corazoncito en la esquina.
class PartnerAvatar extends StatelessWidget {
  const PartnerAvatar({super.key, required this.name, required this.primary, required this.primaryDark, this.badge = Icons.favorite_rounded});

  final String name;
  final Color primary;
  final Color primaryDark;
  final IconData badge;

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    final initial = t.isEmpty ? '♡' : t.characters.first.toUpperCase();
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [primary.withOpacity(0.18), primary.withOpacity(0.38)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(initial, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryDark)),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            child: Icon(badge, size: 11, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

/// Fila de ventaja: icono en cuadradito rosa, título y descripción.
class PartnerBenefit extends StatelessWidget {
  const PartnerBenefit({super.key, required this.icon, required this.title, required this.text, required this.primary});

  final IconData icon;
  final String title;
  final String text;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: primary.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(text, style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }
}

/// Título de sección (sin mayúsculas, más elegante que la etiqueta gris).
class PartnerSectionTitle extends StatelessWidget {
  const PartnerSectionTitle(this.text, {super.key, required this.color, this.trailing});

  final String text;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Row(children: [
        Expanded(child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}
