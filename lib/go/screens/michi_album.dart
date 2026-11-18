import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../strings.dart';
import '../widgets/michi_logic.dart';
import '../widgets/ui.dart';

/// Álbum de postales de Michi: una postal por cada parada del mapa.
/// Se quedan para siempre aunque se rompa la racha.
class MichiAlbumScreen extends StatefulWidget {
  const MichiAlbumScreen({super.key});

  @override
  State<MichiAlbumScreen> createState() => _MichiAlbumScreenState();
}

class _MichiAlbumScreenState extends State<MichiAlbumScreen> with SingleTickerProviderStateMixin {
  Set<int> _got = {};
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    MichiLogic.postcards().then((g) {
      if (!mounted) return;
      setState(() => _got = g);
      _in.forward();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  void _open(MichiStop s) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, a, __) => _PostcardView(stop: s, anim: a),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final count = _got.length;
    return Scaffold(
      backgroundColor: C.t(0xFFFCE4F1),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(10, top + 8, 16, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [C.t(0xFF9C1C4C), C.t(0xFFD9507D)]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('Álbum de postales', 'Postcard album'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('📮 $count / ${MichiLogic.stops.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white70)),
                  ]),
                ),
                const Img('michi_heart', size: 64, fallback: Icons.pets_rounded),
              ]),
            ),
          ),
          for (final world in [1, 2]) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Text(world == 1 ? '🏰  ${tr('Castillo en las nubes', 'Castle in the clouds')}' : '🌙  ${tr('Palacio de la luna', 'Moon palace')}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.pinkDark)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: 0.95),
                delegate: SliverChildListDelegate([
                  for (final (i, s) in MichiLogic.stops.where((s) => s.world == world).indexed) _card(s, i + (world - 1) * 4),
                ]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _card(MichiStop s, int index) {
    final got = _got.contains(s.day);
    final angle = (index.isEven ? -1 : 1) * 0.035;
    return AnimatedBuilder(
      animation: _in,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(((_in.value * 1.6) - index * 0.08).clamp(0.0, 1.0));
        return Opacity(opacity: t.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, (1 - t) * 40), child: child));
      },
      child: GestureDetector(
        onTap: got ? () => _open(s) : null,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: C.t(0xFF8E1B47).withOpacity(0.16), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(fit: StackFit.expand, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ColorFiltered(
                        colorFilter: got
                            ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                            : const ColorFilter.matrix([0.3, 0.3, 0.3, 0, 60, 0.3, 0.3, 0.3, 0, 60, 0.3, 0.3, 0.3, 0, 60, 0, 0, 0, 1, 0]),
                        child: Image.asset('assets/go/${s.postcard}.jpg', fit: BoxFit.cover),
                      ),
                    ),
                    // Sello
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: got ? const Color(0xFFFFC94D) : Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: got
                              ? Image.asset('assets/go/${s.prize}.png', fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(child: Text(s.emoji, style: const TextStyle(fontSize: 16))))
                              : const Center(child: Text('🔒', style: TextStyle(fontSize: 15))),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 6),
                Text(got ? s.name() : '${s.day} ${daysWord(s.day)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: got ? C.pinkDark : C.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Postal grande que se da la vuelta: delante la imagen, detrás la historia.
class _PostcardView extends StatefulWidget {
  final MichiStop stop;
  final Animation<double> anim;
  const _PostcardView({required this.stop, required this.anim});

  @override
  State<_PostcardView> createState() => _PostcardViewState();
}

class _PostcardViewState extends State<_PostcardView> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stop;
    final w = MediaQuery.of(context).size.width - 40;
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: widget.anim, curve: Curves.easeOutBack),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _flip.isCompleted ? _flip.reverse() : _flip.forward();
              },
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final a = _flip.value * math.pi;
                  final back = a > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(a),
                    child: Container(
                      width: w,
                      height: w * 0.78,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF5),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24)],
                      ),
                      child: back
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: Row(children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Text(s.name(), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.pinkDark)),
                                      const SizedBox(height: 10),
                                      Text(MichiLogic.story(s.day),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text, height: 1.4, fontStyle: FontStyle.italic)),
                                      const SizedBox(height: 10),
                                      Text('— Michi 🐾', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.pink)),
                                    ]),
                                  ),
                                ),
                                Container(width: 1.5, color: C.t(0xFFF3C6D6), margin: const EdgeInsets.symmetric(vertical: 10)),
                                Expanded(
                                  flex: 2,
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFC94D), width: 3)),
                                      child: ClipOval(child: Image.asset('assets/go/${s.prize}.png', fit: BoxFit.cover)),
                                    ),
                                    const SizedBox(height: 10),
                                    const Img('michi_flower', size: 76, fallback: Icons.pets_rounded),
                                  ]),
                                ),
                              ]),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(fit: StackFit.expand, children: [
                                Image.asset('assets/go/${s.postcard}.jpg', fit: BoxFit.cover),
                                Positioned(
                                  left: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                                    child: Text('${s.name()}  ↻', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: C.pinkDark)),
                                  ),
                                ),
                              ]),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
