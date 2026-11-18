import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/michi_logic.dart';
import '../widgets/michi_sound.dart';
import '../widgets/ui.dart';
import 'michi_more.dart';

/// Armario de Michi: elige qué lleva puesto los días normales (sin
/// cumpleaños, regla, ánimo registrado, etc., que tienen su propia pose).
class MichiWardrobeScreen extends StatefulWidget {
  const MichiWardrobeScreen({super.key});
  @override
  State<MichiWardrobeScreen> createState() => _MichiWardrobeScreenState();
}

class _Outfit {
  final String img; // '' = automático
  final String name;
  final String lock; // texto para desbloquear
  final bool Function(int best, int challenges) open;
  const _Outfit(this.img, this.name, this.lock, this.open);
}

class _MichiWardrobeScreenState extends State<MichiWardrobeScreen> {
  int _best = 0;
  int _ch = 0;
  bool _ready = false;

  List<_Outfit> get _outfits => [
        _Outfit('', tr('Automático', 'Automatic'), '', (_, __) => true),
        _Outfit('michi_flower', tr('Flor', 'Flower'), '', (_, __) => true),
        _Outfit('michi_scarf', tr('Bufanda', 'Scarf'), '', (_, __) => true),
        _Outfit('michi_collar', tr('Collar', 'Collar'), tr('Racha de 3 días', '3-day streak'), (b, _) => b >= 3),
        _Outfit('michi_party', tr('Gorro de fiesta', 'Party hat'), tr('Completa un reto de 7 días.', 'Complete a 7-day challenge.'), (_, c) => c >= 1),
        _Outfit('michi_crown', tr('Corona', 'Crown'), tr('Racha de 30 días.', '30-day streak.'), (b, _) => b >= 30),
      ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final now = MichiLogic.streak;
    final saved = p.getInt('michi_best_streak') ?? 0;
    final best = now > saved ? now : saved;
    if (best != saved) await p.setInt('michi_best_streak', best);
    final ch = await MichiChallenges.completed();
    if (!mounted) return;
    setState(() {
      _best = best;
      _ch = ch;
      _ready = true;
    });
  }

  void _pick(_Outfit o) {
    final s = AppStore.instance;
    if (!o.open(_best, _ch)) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('🔒 ${o.lock}')));
      return;
    }
    HapticFeedback.selectionClick();
    s.michiOutfit = o.img;
    s.commit();
    MichiSound.meow();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cur = AppStore.instance.michiOutfit;
    final preview = cur.isEmpty ? MichiLogic.pose(fedToday: true) : cur;
    return Scaffold(
      backgroundColor: C.pinkBg,
      appBar: AppBar(
        backgroundColor: C.pinkBg,
        foregroundColor: C.pinkDark,
        elevation: 0,
        title: Text(tr('Armario de Michi', "Michi's wardrobe"), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Img(preview, key: ValueKey(preview), size: 170, fallback: Icons.pets_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Elige qué se pone Michi los días normales. En tu cumpleaños, con la regla o cuando le cuentas cómo estás, se viste para la ocasión.',
                      'Choose what Michi wears on normal days. On your birthday, during your period or when you tell him how you feel, he dresses for the occasion.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.muted, height: 1.35),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                  children: [
                    for (final o in _outfits) _tile(o, o.img == cur),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _tile(_Outfit o, bool sel) {
    final open = o.open(_best, _ch);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _pick(o),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sel ? C.pink : const Color(0x14000000), width: sel ? 2.5 : 1),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(
              child: Stack(alignment: Alignment.center, children: [
                Opacity(
                  opacity: open ? 1 : 0.35,
                  child: o.img.isEmpty
                      ? const Center(child: Text('✨', style: TextStyle(fontSize: 38)))
                      : Img(o.img, size: 72, fallback: Icons.pets_rounded),
                ),
                if (!open) const Text('🔒', style: TextStyle(fontSize: 24)),
              ]),
            ),
            const SizedBox(height: 4),
            Text(o.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: open ? C.text : C.muted)),
          ]),
        ),
      ),
    );
  }
}
