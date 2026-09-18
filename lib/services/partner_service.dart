import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'settings_service.dart';

/// Excepción con un mensaje ya listo para mostrar en pantalla (en español,
/// sin jerga técnica) — mismo patrón que AuthException.
class PartnerException implements Exception {
  final String message;
  PartnerException(this.message);
  @override
  String toString() => message;
}

/// Un vínculo activo entre una cuenta "dueña" del embarazo y una cuenta
/// "socia" que puede verlo en modo solo lectura. Se usa en ambos sentidos:
/// como entrada de "quién puede ver mi embarazo" (uid = la socia) o de
/// "qué embarazos puedo ver" (uid = la dueña).
class PartnerLink {
  final String uid;
  final String email;
  final DateTime linkedAt;
  // Nombre que la DUEÑA le puso a este código al generarlo (ej. "Mi
  // pareja", "Mamá") — para que nunca se confunda entre sus hasta 2
  // socios vinculados. Solo tiene sentido en la lista de la dueña
  // ("Personas que pueden ver tu embarazo"); en "Embarazos que sigues" va
  // vacío y esa pantalla sigue mostrando el correo de la dueña.
  final String label;
  // Nombre de perfil que la DUEÑA tenía puesto (Configuración > Nombre) al
  // momento en que se generó el código — solo tiene sentido en "Embarazos
  // que sigues" (uid = la dueña), para mostrar su nombre en vez de su
  // correo. Viene vacío si ella nunca puso un nombre, o si el vínculo se
  // creó antes de que este campo existiera.
  final String ownerName;
  // Código con el que se creó este vínculo — se necesita para poder
  // anularlo (ver PartnerService.unlinkPartner): al desvincular, además de
  // borrar este documento, se marca ese código como 'revoked' para que
  // nadie pueda volver a usarlo nunca.
  final String inviteCode;

  // Si la dueña comparte con ESTA socia concreta el seguimiento del
  // embarazo (pestañas Seguimiento/Consejos) — el icono de embarazo en
  // "Invitar a un socio". true por defecto (incluso para vínculos viejos
  // que no tienen este campo guardado): antes de que existiera este
  // interruptor, vincularse ya implicaba ver todo el seguimiento, así que
  // el valor por defecto mantiene ese mismo comportamiento hasta que la
  // dueña decida apagarlo. Solo tiene sentido en la lista de la dueña.
  final bool shareTracking;

  const PartnerLink({
    required this.uid,
    required this.email,
    required this.linkedAt,
    this.label = '',
    this.ownerName = '',
    this.inviteCode = '',
    this.shareTracking = true,
  });
}

/// Invitación activa de la dueña, ya con su nombre/etiqueta — ver
/// [PartnerService.watchActiveInvite]. Si el código guardado no tiene
/// etiqueta (por ejemplo uno viejo de antes de que este campo existiera),
/// se trata como si no hubiera ningún código activo: así nunca se enseña
/// en pantalla un código sin nombre asociado.
class ActiveInvite {
  final String code;
  final String label;
  const ActiveInvite({required this.code, required this.label});
}

/// Resultado de intentar vincularse con un código (ver
/// [PartnerService.acceptInvite]): puede quedar vinculada al instante (uso
/// normal, código todavía sin usar), o quedar pendiente de que la dueña
/// apruebe una reconexión (código que ya se usó antes, pero por otra
/// sesión/cuenta anónima — ver [ReconnectRequest]).
class AcceptCodeOutcome {
  final bool linked;
  final ReconnectRequest? reconnectRequest;

  const AcceptCodeOutcome.linked()
      : linked = true,
        reconnectRequest = null;

  const AcceptCodeOutcome.pending(ReconnectRequest request)
      : linked = false,
        reconnectRequest = request;
}

/// Una solicitud de reconexión: alguien pegó un código que ya se había
/// usado antes (típicamente porque cerró sesión y volvió a entrar con una
/// cuenta anónima nueva). No se vincula sola — la dueña tiene que
/// aprobarla o rechazarla desde "Invitar a un socio" (ver
/// firestore.rules > /reconnectRequests para la protección real).
class ReconnectRequest {
  final String id;
  final String ownerUid;
  final String ownerEmail;
  final String partnerUid;
  final String partnerEmail;
  final String code;
  final String? oldPartnerUid;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime requestedAt;
  // Nombre que la dueña le puso al código original (ver PartnerLink.label)
  // — se copia al vínculo nuevo cuando se aprueba la reconexión, para que
  // no se pierda el nombre solo porque la socia cerró sesión.
  final String label;
  // Nombre de perfil de la dueña (ver PartnerLink.ownerName) — igual que
  // label, se copia al vínculo nuevo cuando se aprueba la reconexión.
  final String ownerName;

  const ReconnectRequest({
    required this.id,
    required this.ownerUid,
    required this.ownerEmail,
    required this.partnerUid,
    required this.partnerEmail,
    required this.code,
    required this.oldPartnerUid,
    required this.status,
    required this.requestedAt,
    this.label = '',
    this.ownerName = '',
  });

  factory ReconnectRequest.fromDoc(String ownerUid, DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReconnectRequest(
      id: doc.id,
      ownerUid: ownerUid,
      ownerEmail: data['ownerEmail'] as String? ?? '',
      partnerUid: data['partnerUid'] as String? ?? '',
      partnerEmail: data['partnerEmail'] as String? ?? '',
      code: data['code'] as String? ?? '',
      oldPartnerUid: data['oldPartnerUid'] as String?,
      status: data['status'] as String? ?? 'pending',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      label: data['label'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
    );
  }
}

/// Estado del embarazo tal como lo comparte la dueña con su socia, leído
/// desde `users/{ownerUid}/pregnancy/data`.
class PartnerPregnancyData {
  final bool enabled;
  final DateTime? lmp;
  final String bellyAppearance;
  final bool shareBabyPhotos;

  /// Embarazo múltiple (mellizos/gemelos) — ver PregnancySettings.isTwins.
  /// Se replica aquí igual que el resto de los campos para que el socio vea
  /// la fecha de parto y las semanas ya ajustadas (37 semanas), sin tener
  /// que adivinarlo del lado del cliente.
  final bool isTwins;

  const PartnerPregnancyData({
    required this.enabled,
    this.lmp,
    required this.bellyAppearance,
    required this.shareBabyPhotos,
    this.isTwins = false,
  });

  factory PartnerPregnancyData.fromMap(Map<String, dynamic> map) => PartnerPregnancyData(
        enabled: map['enabled'] as bool? ?? false,
        lmp: (map['lmp'] as Timestamp?)?.toDate(),
        bellyAppearance: map['bellyAppearance'] as String? ?? 'default',
        shareBabyPhotos: map['shareBabyPhotos'] as bool? ?? false,
        isTwins: map['isTwins'] as bool? ?? false,
      );
}

/// Gestiona "Invitar a un socio": generar/aceptar códigos de invitación,
/// mantener la lista de vínculos en ambos sentidos, y sincronizar/leer el
/// estado del embarazo que la dueña comparte en modo solo lectura.
///
/// La protección real de "solo lectura" vive en firestore.rules, no aquí:
/// la socia puede LEER `users/{ownerUid}/pregnancy/data` si existe un
/// documento suyo en `users/{ownerUid}/partners`, pero nunca puede
/// escribir ahí — aunque alguien manipulara la app, el servidor
/// rechazaría el intento. Ver comentarios en firestore.rules para el
/// detalle de cada regla.
class PartnerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SettingsService _settings = SettingsService();

  static const _usersCollection = 'users';
  static const _invitesCollection = 'partnerInvites';
  static const _reconnectRequestsCollection = 'reconnectRequests';
  static const _inviteValidity = Duration(hours: 48);

  // "Solo puede invitar a dos personas máximo": límite de socios/as con
  // acceso de solo lectura a un mismo embarazo. Esta comprobación vive del
  // lado del cliente (de mejor esfuerzo, como el resto de sincronizaciones
  // de esta clase) — la protección real de "solo lectura" sigue viviendo
  // en firestore.rules; este límite es una regla de producto, no de
  // seguridad, así que no hace falta reforzarla también en las reglas.
  static const _maxPartners = 2;

  // Sin caracteres ambiguos (0/O, 1/I/L) para que el código sea fácil de
  // leer y transcribir a mano o dictar por teléfono.
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _randomCode() {
    final rnd = Random.secure();
    return List.generate(6, (_) => _codeChars[rnd.nextInt(_codeChars.length)]).join();
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection(_usersCollection).doc(uid);

  /// Cuántas personas tienen ya acceso de solo lectura a mi embarazo.
  Future<int> partnerCount(String ownerUid) async {
    final snap = await _userDoc(ownerUid).collection('partners').get();
    return snap.docs.length;
  }

  // ==================== Dueña: generar / cancelar invitación ====================

  /// Crea un código de invitación nuevo (6 caracteres, válido 48h),
  /// cancelando antes cualquier invitación pendiente anterior de esta
  /// misma cuenta. El código activo se guarda en
  /// `users/{ownerUid}.activeInviteCode` — así se puede encontrar/cancelar
  /// sin necesitar una consulta abierta a toda la colección de
  /// invitaciones (que las reglas bloquean a propósito, ver
  /// firestore.rules `allow list: false`).
  ///
  /// Lanza [PartnerException] si ya alcanzó el máximo de [_maxPartners]
  /// personas vinculadas — primero tiene que quitar a una (ver
  /// `unlinkPartner`) antes de poder invitar a alguien nuevo.
  ///
  /// [label] es el nombre que la dueña le pone a ESTE código (ej. "Mi
  /// pareja", "Mamá") para no confundirse luego entre sus hasta 2 socios
  /// — se guarda en la invitación y se copia al vínculo en cuanto alguien
  /// lo acepta (ver `acceptInvite` y `PartnerLink.label`). Es solo una
  /// etiqueta para la propia dueña, nunca se le muestra a quien acepta el
  /// código.
  Future<String> createInvite({
    required String ownerUid,
    required String ownerEmail,
    String label = '',
    String ownerName = '',
  }) async {
    if (await partnerCount(ownerUid) >= _maxPartners) {
      throw PartnerException(
        'Ya tienes $_maxPartners personas vinculadas a tu embarazo. Quita a una para poder invitar a otra.',
      );
    }
    await cancelActiveInvite(ownerUid);

    String code = _randomCode();
    var attempt = await _db.collection(_invitesCollection).doc(code).get();
    while (attempt.exists) {
      code = _randomCode();
      attempt = await _db.collection(_invitesCollection).doc(code).get();
    }

    final now = DateTime.now();
    await _db.collection(_invitesCollection).doc(code).set({
      'ownerUid': ownerUid,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName.trim(),
      'label': label.trim(),
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(_inviteValidity)),
      'status': 'pending',
    });

    // Se guarda también aquí (no solo en el documento de la invitación) para
    // que watchActiveInvite pueda leer código + etiqueta juntos de un solo
    // documento, sin una consulta extra.
    await _userDoc(ownerUid).set({
      'activeInviteCode': code,
      'activeInviteLabel': label.trim(),
    }, SetOptions(merge: true));

    return code;
  }

  /// Cancela (borra) la invitación activa de [ownerUid], si tiene alguna.
  Future<void> cancelActiveInvite(String ownerUid) async {
    final userDoc = await _userDoc(ownerUid).get();
    final oldCode = userDoc.data()?['activeInviteCode'] as String?;
    if (oldCode == null) return;
    try {
      await _db.collection(_invitesCollection).doc(oldCode).delete();
    } catch (_) {
      // Puede que ya no exista (por ejemplo, si ya se aceptó) — no pasa nada.
    }
    await _userDoc(ownerUid).set({
      'activeInviteCode': FieldValue.delete(),
      'activeInviteLabel': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Invitación activa de [ownerUid] en vivo (o null si no tiene ninguna
  /// pendiente, O si la que tiene no lleva nombre/etiqueta — ver
  /// [ActiveInvite]), para mostrarla en InvitePartnerScreen. Nunca enseña un
  /// código sin decir antes para quién es.
  Stream<ActiveInvite?> watchActiveInvite(String ownerUid) {
    return _userDoc(ownerUid).snapshots().asyncExpand((doc) {
      final code = doc.data()?['activeInviteCode'] as String?;
      final label = doc.data()?['activeInviteLabel'] as String? ?? '';
      if (code == null || label.trim().isEmpty) {
        return Stream.value(null);
      }
      // El campo de arriba puede seguir diciendo "activo" aunque el
      // código ya se haya aceptado — quien acepta no tiene permiso para
      // limpiarlo en este documento (ver comentario en acceptInvite), así
      // que se confirma aquí mirando el estado real de la invitación:
      // si ya no está "pending", se trata como si no hubiera ninguna.
      return _db.collection(_invitesCollection).doc(code).snapshots().map((inviteDoc) {
        final status = inviteDoc.data()?['status'] as String?;
        if (status != 'pending') return null;
        return ActiveInvite(code: code, label: label.trim());
      });
    });
  }

  Future<DateTime?> inviteExpiresAt(String code) async {
    final doc = await _db.collection(_invitesCollection).doc(code.trim().toUpperCase()).get();
    return (doc.data()?['expiresAt'] as Timestamp?)?.toDate();
  }

  // ==================== Socia: previsualizar / aceptar invitación ====================

  /// Devuelve el correo de la dueña de [code], sin aceptar nada todavía —
  /// para poder mostrar "vas a vincularte con ana@ejemplo.com, ¿confirmas?"
  /// antes de escribir. Lanza PartnerException con un mensaje claro si el
  /// código no existe, ya se usó, o caducó.
  Future<String> previewInvite(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      throw PartnerException('Escribe el código que te compartieron.');
    }
    final doc = await _db.collection(_invitesCollection).doc(trimmed).get();
    if (!doc.exists) {
      throw PartnerException('Ese código no existe. Revísalo e inténtalo de nuevo.');
    }
    final data = doc.data()!;
    final status = data['status'] as String?;
    // Un código "accepted" no es un error aquí: puede ser una reconexión
    // (la persona que lo usó cerró sesión y lo vuelve a pegar) — eso se
    // resuelve en acceptInvite, que decide si vincula al instante o crea
    // una solicitud pendiente. La fecha de caducidad solo aplica al primer
    // uso, mientras el código sigue "pending".
    if (status == 'revoked') {
      throw PartnerException('Ese código fue anulado y ya no es válido.');
    }
    if (status != 'pending' && status != 'accepted') {
      throw PartnerException('Ese código ya no es válido. Pide uno nuevo.');
    }
    if (status == 'pending') {
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        throw PartnerException('Ese código ya caducó. Pide uno nuevo.');
      }
    }
    return data['ownerEmail'] as String? ?? '';
  }

  /// Vincula a [partnerUid] como socia de solo lectura de la dueña del
  /// código [code] — o, si ese código ya se usó antes por otra sesión
  /// (típicamente porque quien lo aceptó cerró sesión y volvió a pegarlo),
  /// crea una solicitud de reconexión pendiente en vez de vincular al
  /// instante (ver [ReconnectRequest] y firestore.rules).
  ///
  /// Caso normal (código todavía "pending"): escribe 3 documentos en un
  /// mismo batch atómico — marca la invitación como aceptada, y crea el
  /// vínculo en ambos sentidos (`users/{ownerUid}/partners/{partnerUid}` y
  /// `users/{partnerUid}/viewerOf/{ownerUid}`). Devuelve
  /// `AcceptCodeOutcome.linked()`.
  ///
  /// Caso reconexión (código ya "accepted" por otro uid): crea
  /// `users/{ownerUid}/reconnectRequests/{code}_{partnerUid}` con estado
  /// "pending" y devuelve `AcceptCodeOutcome.pending(request)` — quien
  /// llama debe esperar a que la dueña la apruebe (ver
  /// `watchReconnectRequestDoc` + `finalizeReconnect`).
  Future<AcceptCodeOutcome> acceptInvite({
    required String code,
    required String partnerUid,
    required String partnerEmail,
  }) async {
    final trimmed = code.trim().toUpperCase();
    final inviteRef = _db.collection(_invitesCollection).doc(trimmed);
    final inviteDoc = await inviteRef.get();
    if (!inviteDoc.exists) {
      throw PartnerException('Ese código no existe. Revísalo e inténtalo de nuevo.');
    }
    final data = inviteDoc.data()!;
    final ownerUid = data['ownerUid'] as String;
    final ownerEmail = data['ownerEmail'] as String? ?? '';
    final ownerName = data['ownerName'] as String? ?? '';
    final label = data['label'] as String? ?? '';

    if (ownerUid == partnerUid) {
      throw PartnerException('No puedes vincularte a tu propia cuenta.');
    }

    final status = data['status'] as String?;

    // La dueña o la propia socia anularon este código a propósito (ver
    // unlinkPartner) — a partir de ahí no vuelve a servir para nadie,
    // aunque sea la misma persona que lo tenía antes o alguien a quien se
    // lo haya pasado por error.
    if (status == 'revoked') {
      throw PartnerException('Ese código fue anulado y ya no es válido.');
    }

    // Código ya usado antes: si fue por esta misma cuenta, ya está
    // vinculada — no hay nada más que hacer. Si fue por otra cuenta
    // (reconexión tras cerrar sesión), pasa a pedir aprobación en vez de
    // fallar con "ese código ya se usó".
    if (status == 'accepted') {
      if (data['acceptedBy'] == partnerUid) {
        return const AcceptCodeOutcome.linked();
      }
      final request = await requestReconnect(
        code: trimmed,
        ownerUid: ownerUid,
        ownerEmail: ownerEmail,
        ownerName: ownerName,
        oldPartnerUid: data['acceptedBy'] as String?,
        partnerUid: partnerUid,
        partnerEmail: partnerEmail,
        label: label,
      );
      return AcceptCodeOutcome.pending(request);
    }
    if (status != 'pending') {
      throw PartnerException('Ese código ya se usó. Pide uno nuevo.');
    }
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw PartnerException('Ese código ya caducó. Pide uno nuevo.');
    }
    // Nota: aquí NO se repite la comprobación de "máximo _maxPartners" que
    // sí hace createInvite. Antes se llamaba a partnerCount(ownerUid) —
    // pero esa función hace un .get() sin filtro sobre
    // users/{ownerUid}/partners, y firestore.rules solo permite listar esa
    // colección completa a la propia dueña (por diseño: no debe filtrarse
    // a un tercero cuántos/quiénes son los demás socios). Quien acepta el
    // código NUNCA es la dueña, así que esa llamada siempre fallaba con
    // "permission-denied" — no una PartnerException, así que se veía en la
    // pantalla como el genérico "Algo salió mal" en vez de un mensaje
    // claro, y de paso bloqueaba vincularse aunque el código fuera válido.
    // El límite ya quedó aplicado del lado correcto (createInvite, que
    // ejecuta la propia dueña y sí puede leer su lista completa); aquí ya
    // no hace falta ni es posible repetirlo de forma segura.
    final now = Timestamp.fromDate(DateTime.now());
    final batch = _db.batch();
    batch.update(inviteRef, {
      'status': 'accepted',
      'acceptedBy': partnerUid,
      'acceptedAt': now,
    });
    batch.set(_userDoc(ownerUid).collection('partners').doc(partnerUid), {
      'partnerUid': partnerUid,
      'partnerEmail': partnerEmail,
      'linkedAt': now,
      'inviteCode': trimmed,
      'label': label,
    });
    batch.set(_userDoc(partnerUid).collection('viewerOf').doc(ownerUid), {
      'ownerUid': ownerUid,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'linkedAt': now,
      'inviteCode': trimmed,
    });

    try {
      await batch.commit();
    } catch (_) {
      throw PartnerException('No se pudo vincular. Revisa tu conexión e inténtalo de nuevo.');
    }

    // Nota: aquí NO se intenta limpiar 'activeInviteCode' en el documento
    // de la dueña. Antes se hacía con un ownerDoc.get() + set(...) — pero
    // ese documento (users/{ownerUid}) solo lo puede leer o escribir la
    // propia dueña (ver firestore.rules), así que ese intento SIEMPRE
    // fallaba con permission-denied del lado de quien acepta (nunca es la
    // dueña). El código ya aceptado se sigue guardando ahí, pero
    // watchActiveInvite (más abajo) revisa también el status real de la
    // invitación y deja de mostrarla en cuanto deja de estar "pending" —
    // así la dueña nunca ve un código ya usado como si siguiera activo,
    // sin que quien acepta necesite ese permiso que no debería tener.

    return const AcceptCodeOutcome.linked();
  }

  // ==================== Reconexión (código ya usado, otra sesión) ====================

  /// Crea (o recupera, si ya existía) la solicitud de reconexión para que
  /// [partnerUid] vuelva a ver el embarazo de [ownerUid] usando un código
  /// que ya había sido aceptado antes por [oldPartnerUid]. El id del
  /// documento es determinista (`{code}_{partnerUid}`) para que pegar el
  /// mismo código varias veces mientras espera no cree solicitudes
  /// duplicadas.
  Future<ReconnectRequest> requestReconnect({
    required String code,
    required String ownerUid,
    required String ownerEmail,
    required String? oldPartnerUid,
    required String partnerUid,
    required String partnerEmail,
    String label = '',
    String ownerName = '',
  }) async {
    final requestId = '${code}_$partnerUid';
    final ref = _userDoc(ownerUid).collection(_reconnectRequestsCollection).doc(requestId);
    final existing = await ref.get();
    if (existing.exists && existing.data()?['status'] == 'pending') {
      return ReconnectRequest.fromDoc(ownerUid, existing);
    }
    final now = Timestamp.fromDate(DateTime.now());
    await ref.set({
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'partnerUid': partnerUid,
      'partnerEmail': partnerEmail,
      'code': code,
      'oldPartnerUid': oldPartnerUid,
      'status': 'pending',
      'requestedAt': now,
      'label': label,
    });
    final saved = await ref.get();
    return ReconnectRequest.fromDoc(ownerUid, saved);
  }

  /// Solicitudes de reconexión pendientes de aprobar, para mostrarlas en
  /// "Invitar a un socio" (soy la dueña).
  Stream<List<ReconnectRequest>> watchReconnectRequests(String ownerUid) {
    return _userDoc(ownerUid)
        .collection(_reconnectRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReconnectRequest.fromDoc(ownerUid, d)).toList());
  }

  /// Escucha en vivo UNA solicitud de reconexión concreta (soy quien la
  /// pidió), para saber en cuanto la dueña la apruebe o la rechace.
  /// Emite `null` si el documento se borró (rechazada, o ya finalizada).
  Stream<ReconnectRequest?> watchReconnectRequestDoc({required String ownerUid, required String requestId}) {
    return _userDoc(ownerUid).collection(_reconnectRequestsCollection).doc(requestId).snapshots().map(
          (doc) => doc.exists ? ReconnectRequest.fromDoc(ownerUid, doc) : null,
        );
  }

  /// La dueña aprueba una reconexión: marca la solicitud como "approved" y
  /// de paso quita el vínculo viejo (la cuenta anónima anterior de esa
  /// misma persona, que ya cerró sesión). Quien pidió reconectar es quien
  /// termina de crear el vínculo nuevo en cuanto ve este cambio (ver
  /// `finalizeReconnect`) — así cada quien escribe solo lo que las reglas
  /// le permiten escribir.
  Future<void> approveReconnect(ReconnectRequest request) async {
    final batch = _db.batch();
    batch.update(
      _userDoc(request.ownerUid).collection(_reconnectRequestsCollection).doc(request.id),
      {'status': 'approved'},
    );
    final oldUid = request.oldPartnerUid;
    if (oldUid != null && oldUid.isNotEmpty) {
      batch.delete(_userDoc(request.ownerUid).collection('partners').doc(oldUid));
      batch.delete(_userDoc(oldUid).collection('viewerOf').doc(request.ownerUid));
    }
    await batch.commit();
  }

  /// La dueña rechaza una reconexión — simplemente se borra la solicitud;
  /// quien la pidió lo ve como "ya no existe" y sabe que no fue aceptada.
  Future<void> rejectReconnect(ReconnectRequest request) async {
    await _userDoc(request.ownerUid).collection(_reconnectRequestsCollection).doc(request.id).delete();
  }

  /// Quien pidió reconectar, tras ver que la dueña ya aprobó su solicitud:
  /// crea su propio vínculo nuevo (`partners`/`viewerOf`) y borra la
  /// solicitud ya usada.
  Future<void> finalizeReconnect(ReconnectRequest request) async {
    final now = Timestamp.fromDate(DateTime.now());
    final batch = _db.batch();
    // Actualiza a quién pertenece ahora la invitación (acceptedBy) — si no
    // se hiciera esto, el código quedaría para siempre "ligado" a la
    // identidad anónima VIEJA (la que perdió acceso), y la persona que
    // acaba de reconectar no podría luego anular el código ella misma
    // (ver firestore.rules > partnerInvites > revocar, que compara contra
    // acceptedBy). El estado sigue siendo 'accepted', solo cambia el uid.
    batch.update(_db.collection(_invitesCollection).doc(request.code), {
      'acceptedBy': request.partnerUid,
    });
    batch.set(_userDoc(request.ownerUid).collection('partners').doc(request.partnerUid), {
      'partnerUid': request.partnerUid,
      'partnerEmail': request.partnerEmail,
      'linkedAt': now,
      'inviteCode': request.code,
      'reconnectRequestId': request.id,
      'label': request.label,
    });
    batch.set(_userDoc(request.partnerUid).collection('viewerOf').doc(request.ownerUid), {
      'ownerUid': request.ownerUid,
      'ownerEmail': request.ownerEmail,
      'ownerName': request.ownerName,
      'linkedAt': now,
      'inviteCode': request.code,
      'reconnectRequestId': request.id,
    });
    batch.delete(_userDoc(request.ownerUid).collection(_reconnectRequestsCollection).doc(request.id));
    await batch.commit();
  }

  // ==================== Vínculos ya aceptados ====================

  /// Personas que pueden ver MI embarazo (soy la dueña).
  Stream<List<PartnerLink>> watchMyPartners(String ownerUid) {
    return _userDoc(ownerUid).collection('partners').snapshots().map(
          (snap) => snap.docs
              .map((d) => PartnerLink(
                    uid: d.data()['partnerUid'] as String? ?? d.id,
                    email: d.data()['partnerEmail'] as String? ?? '',
                    linkedAt: (d.data()['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    label: d.data()['label'] as String? ?? '',
                    inviteCode: d.data()['inviteCode'] as String? ?? '',
                    shareTracking: d.data()['shareTracking'] as bool? ?? true,
                  ))
              .toList(),
        );
  }

  /// Prende/apaga, para UNA socia concreta, si comparte con ella el
  /// seguimiento del embarazo (ver [PartnerLink.shareTracking] y el
  /// icono de embarazo en "Invitar a un socio"). No afecta al chat ni a
  /// los deseos — esos siguen disponibles aunque esto esté apagado.
  Future<void> setShareTracking({
    required String ownerUid,
    required String partnerUid,
    required bool enabled,
  }) async {
    await _userDoc(ownerUid).collection('partners').doc(partnerUid).update({
      'shareTracking': enabled,
    });
  }

  /// Embarazos que puedo ver (soy socia/viewer).
  Stream<List<PartnerLink>> watchPregnanciesIFollow(String partnerUid) {
    return _userDoc(partnerUid).collection('viewerOf').snapshots().map(
          (snap) => snap.docs
              .map((d) => PartnerLink(
                    uid: d.data()['ownerUid'] as String? ?? d.id,
                    email: d.data()['ownerEmail'] as String? ?? '',
                    ownerName: d.data()['ownerName'] as String? ?? '',
                    linkedAt: (d.data()['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    inviteCode: d.data()['inviteCode'] as String? ?? '',
                  ))
              .toList(),
        );
  }

  /// Rompe el vínculo en ambos sentidos Y anula el código para siempre —
  /// puede llamarlo cualquiera de las dos personas (la dueña para "quitar
  /// acceso", la socia para "ya no quiero seguir este embarazo"). Pasar
  /// [inviteCode] (ver PartnerLink.inviteCode) marca esa invitación como
  /// 'revoked': a partir de ahí ese código deja de servir para siempre,
  /// ni para la misma persona que lo tenía ni para nadie a quien se lo
  /// haya compartido por error — ver acceptInvite/previewInvite, que
  /// rechazan explícitamente cualquier código en ese estado.
  Future<void> unlinkPartner({
    required String ownerUid,
    required String partnerUid,
    String? inviteCode,
  }) async {
    final batch = _db.batch();
    batch.delete(_userDoc(ownerUid).collection('partners').doc(partnerUid));
    batch.delete(_userDoc(partnerUid).collection('viewerOf').doc(ownerUid));
    final trimmedCode = inviteCode?.trim().toUpperCase() ?? '';
    if (trimmedCode.isNotEmpty) {
      batch.update(_db.collection(_invitesCollection).doc(trimmedCode), {
        'status': 'revoked',
        'revokedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  // ==================== Sincronizar / leer el embarazo compartido ====================

  /// Sube a `users/{ownerUid}/pregnancy/data` el estado actual guardado
  /// localmente (SettingsService). Se llama cada vez que la dueña cambia
  /// algo relevante (activar/desactivar embarazo, fecha de última regla,
  /// o el interruptor de compartir fotos), y también cada vez que abre
  /// "Invitar a un socio", para que la vista de su socia nunca quede
  /// desactualizada por mucho tiempo.
  ///
  /// Los errores de red se ignoran a propósito: es una sincronización de
  /// "mejor esfuerzo" que nunca debe bloquear ni mostrar un error en una
  /// pantalla donde la usuaria solo estaba cambiando un ajuste local — se
  /// reintentará en el próximo cambio.
  Future<void> syncPregnancyData(String ownerUid) async {
    try {
      final pregnancy = await _settings.loadPregnancySettings();
      final bellyAppearance = await _settings.loadBellyAppearance();
      final shareBabyPhotos = await _settings.loadShareBabyPhotos();
      await _userDoc(ownerUid).collection('pregnancy').doc('data').set({
        'enabled': pregnancy.enabled,
        'lmp': pregnancy.lmp != null ? Timestamp.fromDate(pregnancy.lmp!) : null,
        'bellyAppearance': bellyAppearance,
        'shareBabyPhotos': shareBabyPhotos,
        'isTwins': pregnancy.isTwins,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      // Sin conexión u otro fallo transitorio: se reintentará más tarde.
    }
  }

  /// Escucha en vivo el embarazo de la dueña [ownerUid], para la pantalla
  /// de solo lectura de la socia. Devuelve `null` mientras no exista el
  /// documento (por ejemplo, si la dueña nunca activó/sincronizó el modo
  /// embarazo).
  Stream<PartnerPregnancyData?> watchPregnancyData(String ownerUid) {
    return _userDoc(ownerUid).collection('pregnancy').doc('data').snapshots().map(
          (doc) => doc.exists ? PartnerPregnancyData.fromMap(doc.data()!) : null,
        );
  }

  // ==================== Sincronizar / leer el ciclo compartido (fuera del embarazo) ====================
  //
  // Igual que hacen otras apps del rubro (p. ej. Flo): "Invitar a un socio"
  // no es exclusivo del embarazo — con "Seguir mi periodo" o "Intentar
  // concebir" también se comparte, en modo solo lectura, un resumen del
  // calendario de ciclo (previsto/ventana fértil), NUNCA los síntomas que
  // la dueña registró día a día (esos siguen siendo privados). Documento
  // separado de `pregnancy/data` para no mezclar ambos modos ni arrastrar
  // datos de un modo viejo cuando cambia de objetivo.

  /// Sube a `users/{ownerUid}/cycle/data` un resumen YA CALCULADO de la
  /// predicción (ver CyclePredictor.predict() en cycle_predictor.dart) —
  /// nunca el Map<String, DayEntry> crudo, que incluye síntomas y notas
  /// personales que la dueña nunca decidió compartir. Mismo patrón de
  /// "mejor esfuerzo" que [syncPregnancyData]: los errores de red se
  /// ignoran a propósito, se reintenta en la próxima llamada.
  Future<void> syncCycleData({
    required String ownerUid,
    required String userGoal,
    required int cycleLen,
    required int periodLen,
    int? currentDayInCycle,
    DateTime? nextPeriodStart,
    DateTime? ovulationDate,
    DateTime? fertileRangeStart,
    DateTime? fertileRangeEnd,
    bool isIrregular = false,
  }) async {
    try {
      await _userDoc(ownerUid).collection('cycle').doc('data').set({
        'userGoal': userGoal,
        'cycleLen': cycleLen,
        'periodLen': periodLen,
        'currentDayInCycle': currentDayInCycle,
        'nextPeriodStart': nextPeriodStart != null ? Timestamp.fromDate(nextPeriodStart) : null,
        'ovulationDate': ovulationDate != null ? Timestamp.fromDate(ovulationDate) : null,
        'fertileRangeStart': fertileRangeStart != null ? Timestamp.fromDate(fertileRangeStart) : null,
        'fertileRangeEnd': fertileRangeEnd != null ? Timestamp.fromDate(fertileRangeEnd) : null,
        'isIrregular': isIrregular,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      // Sin conexión u otro fallo transitorio: se reintentará más tarde.
    }
  }

  /// Escucha en vivo el resumen de ciclo de la dueña [ownerUid], para la
  /// pantalla de solo lectura de la socia. Devuelve `null` mientras no
  /// exista el documento (por ejemplo, si la dueña está en modo embarazo y
  /// nunca sincronizó datos de ciclo, o si InvitePartnerScreen no llegó a
  /// abrirse todavía tras cambiar de objetivo).
  Stream<PartnerCycleData?> watchCycleData(String ownerUid) {
    return _userDoc(ownerUid).collection('cycle').doc('data').snapshots().map(
          (doc) => doc.exists ? PartnerCycleData.fromMap(doc.data()!) : null,
        );
  }
}

/// Resumen de solo lectura del ciclo que la dueña comparte con su socia
/// cuando NO está en modo embarazo — ver [PartnerService.syncCycleData].
class PartnerCycleData {
  /// 'period' | 'conceive' — para que la socia sepa si además está
  /// intentando concebir (mismo resalte que ve la propia dueña en Hoy).
  final String userGoal;
  final int cycleLen;
  final int periodLen;
  final int? currentDayInCycle;
  final DateTime? nextPeriodStart;
  final DateTime? ovulationDate;
  final DateTime? fertileRangeStart;
  final DateTime? fertileRangeEnd;
  final bool isIrregular;
  final DateTime updatedAt;

  const PartnerCycleData({
    required this.userGoal,
    required this.cycleLen,
    required this.periodLen,
    this.currentDayInCycle,
    this.nextPeriodStart,
    this.ovulationDate,
    this.fertileRangeStart,
    this.fertileRangeEnd,
    this.isIrregular = false,
    required this.updatedAt,
  });

  factory PartnerCycleData.fromMap(Map<String, dynamic> map) => PartnerCycleData(
        userGoal: map['userGoal'] as String? ?? 'period',
        // 28/5: mismos valores por defecto que kDefaultCycleLen/
        // kDefaultPeriodLen en cycle_predictor.dart — no se importa esa
        // constante aquí para no acoplar el modelo de datos de Firestore a
        // la capa de predicción local.
        cycleLen: map['cycleLen'] as int? ?? 28,
        periodLen: map['periodLen'] as int? ?? 5,
        currentDayInCycle: map['currentDayInCycle'] as int?,
        nextPeriodStart: (map['nextPeriodStart'] as Timestamp?)?.toDate(),
        ovulationDate: (map['ovulationDate'] as Timestamp?)?.toDate(),
        fertileRangeStart: (map['fertileRangeStart'] as Timestamp?)?.toDate(),
        fertileRangeEnd: (map['fertileRangeEnd'] as Timestamp?)?.toDate(),
        isIrregular: map['isIrregular'] as bool? ?? false,
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
