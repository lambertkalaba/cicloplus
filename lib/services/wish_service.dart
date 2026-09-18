import 'package:cloud_firestore/cloud_firestore.dart';

/// Un "deseo" de la dueña del embarazo — puede ser un antojo de comida, o
/// cualquier otra cosa que quiera o necesite (ver PartnerWishesScreen). Lo
/// escribe siempre la dueña; su pareja/socia vinculada puede verlo y
/// marcarlo como cumplido, pero no puede cambiar el texto ni borrarlo (esa
/// restricción vive en firestore.rules, no solo aquí).
class Wish {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool done;
  final String? doneBy;

  const Wish({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.done,
    this.doneBy,
  });

  factory Wish.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Wish(
      id: doc.id,
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      done: data['done'] as bool? ?? false,
      doneBy: data['doneBy'] as String?,
    );
  }
}

/// Gestiona la lista de deseos de una dueña de embarazo
/// (`users/{ownerUid}/wishes`), visible para ella y para su(s) socia(s) ya
/// vinculada(s) — ver PartnerWishesScreen (isOwner: true/false) y
/// firestore.rules > /wishes para la protección real de "quién puede
/// escribir qué".
class WishService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _wishesCol(String ownerUid) =>
      _db.collection('users').doc(ownerUid).collection('wishes');

  /// Lista de deseos en vivo, más recientes primero.
  Stream<List<Wish>> watchWishes(String ownerUid) {
    return _wishesCol(ownerUid).orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(Wish.fromDoc).toList(),
        );
  }

  /// Solo la dueña llama esto (ver PartnerWishesScreen isOwner: true) —
  /// firestore.rules también lo exige del lado del servidor.
  Future<void> addWish({required String ownerUid, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _wishesCol(ownerUid).add({
      'text': trimmed,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'done': false,
      'doneBy': null,
    });
  }

  /// Marcar/desmarcar como cumplido — puede llamarlo la dueña O su pareja
  /// vinculada (para que ella misma pueda avisar "ya te lo conseguí").
  Future<void> setDone({
    required String ownerUid,
    required String wishId,
    required bool done,
    required String byUid,
  }) async {
    await _wishesCol(ownerUid).doc(wishId).update({
      'done': done,
      'doneBy': done ? byUid : null,
    });
  }

  /// Solo la dueña (ver PartnerWishesScreen isOwner: true).
  Future<void> deleteWish({required String ownerUid, required String wishId}) async {
    await _wishesCol(ownerUid).doc(wishId).delete();
  }
}
