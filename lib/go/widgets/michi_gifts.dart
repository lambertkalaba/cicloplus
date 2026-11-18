import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../strings.dart';
import 'ui.dart';

/// Regalos de la pareja para Michi.
/// La pareja vinculada escribe en `users/{ownerUid}/michiGifts` (ver
/// firestore.rules > /michiGifts) y a la dueña le aparece en la tarjeta de
/// Michi para abrirlo.
class MichiGift {
  final String id;
  final String gift; // fish | yarn | hug
  final String fromName;
  const MichiGift(this.id, this.gift, this.fromName);

  String get emoji => switch (gift) { 'yarn' => '🧶', 'hug' => '💗', _ => '🐟' };
}

class MichiGiftService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _col(String ownerUid) => _db.collection('users').doc(ownerUid).collection('michiGifts');

  static Future<void> send({required String ownerUid, required String gift, required String fromName}) => _col(ownerUid).add({
        'gift': gift,
        'fromName': fromName,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });

  /// Regalos sin abrir de la dueña conectada (vacío si no hay sesión).
  static Stream<List<MichiGift>> watchMine() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _col(uid).where('seen', isEqualTo: false).snapshots().map((s) => s.docs
        .map((d) => MichiGift(d.id, d.data()['gift'] as String? ?? 'fish', (d.data()['fromName'] as String? ?? '').trim()))
        .toList()).handleError((_) {});
  }

  static Future<void> markSeen(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(id).update({'seen': true});
  }
}

/// Hoja para que la pareja elija y envíe un regalo.
Future<void> showSendMichiGiftSheet(BuildContext context, {required String ownerUid, required String fromName}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      Widget option(String gift, String emoji, String label) => Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(ctx).pop();
                try {
                  await MichiGiftService.send(ownerUid: ownerUid, gift: gift, fromName: fromName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('¡Regalo enviado! 🎁', 'Gift sent! 🎁'))));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(tr('Algo salió mal. Inténtalo de nuevo.', 'Something went wrong. Please try again.'))));
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(color: C.t(0xFFFCE4F1), borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  Text(emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 6),
                  Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: C.pinkDark)),
                ]),
              ),
            ),
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            const Img('gift_box', size: 90, fallback: Icons.card_giftcard_rounded),
            const SizedBox(height: 6),
            Text(tr('Regalo para Michi', 'Gift for Michi'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.pinkDark)),
            const SizedBox(height: 4),
            Text(tr('Envía un regalo a Michi: ella lo verá en su app 💗', "Send Michi a gift: she'll see it in her app 💗"),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.text)),
            const SizedBox(height: 16),
            Row(children: [
              option('fish', '🐟', tr('Pescadito', 'Little fish')),
              option('yarn', '🧶', tr('Ovillo', 'Yarn ball')),
              option('hug', '💗', tr('Mimos', 'Cuddles')),
            ]),
          ]),
        ),
      );
    },
  );
}

/// La dueña abre el regalo: la caja tiembla, se abre y Michi lo celebra.
Future<void> showOpenMichiGift(BuildContext context, MichiGift g) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'gift',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => _GiftOpen(gift: g),
  ).then((_) => MichiGiftService.markSeen(g.id));
}

class _GiftOpen extends StatefulWidget {
  final MichiGift gift;
  const _GiftOpen({required this.gift});

  @override
  State<_GiftOpen> createState() => _GiftOpenState();
}

class _GiftOpenState extends State<_GiftOpen> with TickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  bool _opened = false;

  @override
  void dispose() {
    _shake.dispose();
    _open.dispose();
    super.dispose();
  }

  void _doOpen() {
    if (_opened) return;
    HapticFeedback.heavyImpact();
    _shake.stop();
    setState(() => _opened = true);
    _open.forward();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gift;
    final size = MediaQuery.of(context).size;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _opened ? () => Navigator.of(context).pop() : _doOpen,
        child: AnimatedBuilder(
          animation: Listenable.merge([_shake, _open]),
          builder: (context, _) {
            final t = _open.value;
            return Stack(children: [
              if (_opened)
                for (var i = 0; i < 26; i++)
                  Positioned(
                    left: size.width / 2 + math.cos(i * 0.9) * t * size.width * 0.55 - 12,
                    top: size.height / 2 + math.sin(i * 0.9) * t * size.height * 0.4 - 12 + t * t * 120,
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Text(['✨', '💖', g.emoji, '🎉', '⭐'][i % 5], style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 36),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_opened ? tr('¡Gracias! 💗', 'Thank you! 💗') : tr('¡Michi tiene un regalo! 🎁', 'Michi has a gift! 🎁'),
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.pinkDark)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: _opened
                          ? Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                              Transform.scale(
                                scale: Curves.elasticOut.transform(t.clamp(0.0, 1.0)),
                                child: const Img('michi_return', size: 150, fallback: Icons.pets_rounded),
                              ),
                              Positioned(
                                right: 10,
                                top: 10 - t * 20,
                                child: Text(g.emoji, style: const TextStyle(fontSize: 40)),
                              ),
                            ])
                          : Transform.rotate(
                              angle: math.sin(_shake.value * math.pi * 2) * 0.08,
                              child: const Img('gift_box', size: 140, fallback: Icons.card_giftcard_rounded),
                            ),
                    ),
                    const SizedBox(height: 10),
                    if (g.fromName.isNotEmpty) ...[
                      Text(tr('Te lo envía con cariño:', 'Sent with love by:'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.muted)),
                      Text(g.fromName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.text)),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: _opened ? () => Navigator.of(context).pop() : _doOpen,
                        style: FilledButton.styleFrom(backgroundColor: C.pink, shape: const StadiumBorder()),
                        child: Text(_opened ? 'OK' : tr('Abrir', 'Open'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ]),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
