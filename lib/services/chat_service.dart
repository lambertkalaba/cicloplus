import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Un mensaje del chat privado 1 a 1 (ver [ChatService]). Siempre tiene
/// texto O foto, nunca ambos ni ninguno — la UI decide cuál mostrar según
/// cuál de los dos venga con contenido.
class ChatMessage {
  final String id;
  final String senderUid;
  final String? text;
  final String? photoUrl;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    this.text,
    this.photoUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatMessage(
      id: doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      text: data['text'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Chat privado 1 a 1 entre la dueña de un embarazo y una socia ya
/// vinculada (ver PartnerService) — nunca entre desconocidos: la regla de
/// creación del chat en firestore.rules exige que ya exista un vínculo
/// partners/viewerOf entre ambos uids antes de poder crear la conversación.
///
/// Igual que en PartnerService, la protección real de "solo estas dos
/// personas pueden leer/escribir aquí" vive en firestore.rules (y en
/// storage.rules para las fotos), no en esta clase.
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _chatsCollection = 'chats';

  /// Id determinista del chat entre dos personas: siempre el mismo sin
  /// importar quién lo abra primero, ordenando los dos uids.
  String chatIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> _ensureChat(String chatId, String myUid, String otherUid) async {
    final ref = _db.collection(_chatsCollection).doc(chatId);
    final doc = await ref.get();
    if (doc.exists) return;
    final sorted = [myUid, otherUid]..sort();
    await ref.set({
      'participants': sorted,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Mensajes del chat entre [myUid] y [otherUid], en vivo y en orden
  /// cronológico (el más viejo primero, como cualquier app de chat).
  Stream<List<ChatMessage>> watchMessages({required String myUid, required String otherUid}) {
    final chatId = chatIdFor(myUid, otherUid);
    return _db
        .collection(_chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendText({
    required String myUid,
    required String otherUid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final chatId = chatIdFor(myUid, otherUid);
    await _ensureChat(chatId, myUid, otherUid);
    await _db.collection(_chatsCollection).doc(chatId).collection('messages').add({
      'senderUid': myUid,
      'text': trimmed,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Sube [bytes] (ya comprimidos/leídos por la UI desde la cámara o
  /// galería) a Storage y guarda un mensaje con la URL resultante.
  Future<void> sendPhoto({
    required String myUid,
    required String otherUid,
    required Uint8List bytes,
  }) async {
    final chatId = chatIdFor(myUid, otherUid);
    await _ensureChat(chatId, myUid, otherUid);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$myUid.jpg';
    final ref = _storage.ref('chat_photos/$chatId/$fileName');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _db.collection(_chatsCollection).doc(chatId).collection('messages').add({
      'senderUid': myUid,
      'photoUrl': url,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
