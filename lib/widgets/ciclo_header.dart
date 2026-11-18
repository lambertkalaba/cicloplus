import 'package:flutter/material.dart';

/// Cabecera común de las pantallas internas (diseño de ChatGPT, nov. 2026):
/// degradado burdeos-rosa, esquinas inferiores redondeadas y flor de
/// hibisco. Incluye el hueco de la barra de estado.
class CicloHeader extends StatelessWidget {
  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBack;

  const CicloHeader({super.key, this.title, this.titleText, this.leading, this.actions, this.showBack = true});

  static const gradient = LinearGradient(
    colors: [Color(0xFF9C1C4C), Color(0xFFD9507D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    final hasActions = actions != null && actions!.isNotEmpty;
    Widget? lead = leading;
    if (lead == null && showBack && canPop) {
      lead = IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4, top + 4, 8, 14),
      decoration: const BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: hasActions ? 64 : -2,
            top: -6,
            child: Opacity(
              opacity: hasActions ? 0.55 : 1,
              child: Image.asset('assets/go/hibiscus.png', width: 58, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                if (lead != null)
                  IconTheme(data: const IconThemeData(color: Colors.white), child: lead)
                else
                  const SizedBox(width: 12),
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title ?? Text(titleText ?? ''),
                  ),
                ),
                if (hasActions)
                  IconTheme(
                    data: const IconThemeData(color: Colors.white),
                    child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
                  )
                else
                  const SizedBox(width: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Igual que [CicloHeader] pero para usar como `appBar:` de un Scaffold.
/// Acepta los mismos parámetros que se usaban con `AppBar` (los de color
/// y elevación se ignoran: la cabecera siempre tiene el mismo estilo).
class CicloAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final bool? centerTitle;
  final IconThemeData? iconTheme;

  const CicloAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.centerTitle,
    this.iconTheme,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) => CicloHeader(
        title: title,
        leading: leading,
        actions: actions,
        showBack: automaticallyImplyLeading,
      );
}
