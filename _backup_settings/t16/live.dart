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
