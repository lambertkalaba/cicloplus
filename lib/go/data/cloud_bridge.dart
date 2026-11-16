import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'store.dart';

/// Puente entre los registros de día del diseño nuevo (DayLog) y los
/// documentos que CicloPlus ya guardaba en Firestore:
/// users/{uid}/days/{yyyy-mm-dd}.
///
/// Importante para no perder datos de las clientas: al guardar NO se
/// sustituye el documento entero. Se parte del documento que ya existía
/// (con temperatura, moco cervical, medicación, fotos, etc.) y solo se
/// actualizan los campos que maneja el diseño nuevo.
class CloudBridge {
  CloudBridge(this.uid);

  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Copia de cada documento tal como está en la nube.
  final Map<String, Map<String, dynamic>> raw = {};

  CollectionReference<Map<String, dynamic>> get _days => _db.collection('users').doc(uid).collection('days');

  static const _flows = ['none', 'light', 'medium', 'heavy'];
  static const _levels = ['leve', 'moderado', 'fuerte'];

  /// Campos que solo tenía CicloPlus; se editan en "Más detalles" del registro.
  static const extraKeys = [
    'temp', 'cervicalMucus', 'spotting', 'medication', 'energy', 'skinHair', 'breastSelfExam',
    'sexTimes', 'sexDesire', 'sexMasturbation', 'sexOrgasm', 'sexNoOrgasm', 'sexNone', 'diu', 'photo',
    'sleepBedtime', 'sleepWakeTime',
  ];

  /// Ids de síntomas que cambian de nombre entre los dos diseños.
  static const _symToCloud = {'cabeza': 'dolorcab'};
  static const _symFromCloud = {'dolorcab': 'cabeza'};

  /// true cuando ya se ha leído la nube. Hasta entonces no se escribe
  /// nada encima (para no pisar datos que aún no conocemos).
  bool loaded = false;

  Future<Map<String, DayLog>> loadAll() async {
    QuerySnapshot<Map<String, dynamic>> snap;
    var fromServer = true;
    try {
      snap = await _days.get().timeout(const Duration(seconds: 8));
      fromServer = !snap.metadata.isFromCache;
    } on TimeoutException {
      // Sin conexión: lo último guardado en el móvil por Firestore.
      snap = await _days.get(const GetOptions(source: Source.cache));
      fromServer = false;
    }
    // Solo se escribe cuando sabemos lo que hay de verdad en el servidor.
    loaded = fromServer;
    raw.clear();
    final out = <String, DayLog>{};
    for (final d in snap.docs) {
      raw[d.id] = Map<String, dynamic>.from(d.data());
      final log = fromCloud(raw[d.id]!);
      if (!log.isEmpty) out[d.id] = log;
    }
    return out;
  }

  /// Escribe días que vienen de las pantallas de CicloPlus (Hoy, Ajustes).
  /// Se mezclan con lo que ya había para no perder los campos del diseño
  /// nuevo (ánimo 1-5, actividad…). Un valor null borra el día.
  Future<void> putRaw(Map<String, Map<String, dynamic>?> changes) async {
    final batch = _db.batch();
    changes.forEach((k, json) {
      if (json == null) {
        batch.delete(_days.doc(k));
        raw.remove(k);
      } else {
        if (!loaded) {
          // Aún no sabemos qué hay en la nube: se mezcla en el servidor.
          batch.set(_days.doc(k), json, SetOptions(merge: true));
        } else {
          final merged = {...?raw[k], ...json}..removeWhere((_, v) => v == null);
          batch.set(_days.doc(k), merged);
          raw[k] = merged;
        }
      }
    });
    await batch.commit();
  }

  /// Guarda solo los días que han cambiado.
  Future<void> sync(Map<String, DayLog> logs) async {
    if (!loaded) return; // se sube en cuanto termine de leer la nube
    final keys = {...raw.keys, ...logs.keys};
    final batch = _db.batch();
    var ops = 0;
    for (final k in keys) {
      final log = logs[k];
      final old = raw[k];
      final oldLog = old == null ? DayLog() : fromCloud(old);
      final now = log ?? DayLog();
      if (_same(oldLog, now)) continue;
      final merged = toCloud(now, old ?? <String, dynamic>{});
      if (_cloudEmpty(merged)) {
        if (old != null) {
          batch.delete(_days.doc(k));
          raw.remove(k);
          ops++;
        }
      } else {
        batch.set(_days.doc(k), merged);
        raw[k] = merged;
        ops++;
      }
    }
    if (ops > 0) await batch.commit();
  }

  static bool _same(DayLog a, DayLog b) => _canon(a.toJson()) == _canon(b.toJson());

  /// JSON en orden fijo (claves y listas ordenadas) para comparar.
  static String _canon(dynamic v) {
    dynamic norm(dynamic x) {
      if (x is Map) {
        final keys = x.keys.map((k) => k.toString()).toList()..sort();
        return {for (final k in keys) k: norm(x[k])};
      }
      if (x is Iterable) {
        final l = x.map(norm).toList();
        l.sort((p, q) => jsonEncode(p).compareTo(jsonEncode(q)));
        return l;
      }
      return x;
    }

    return jsonEncode(norm(v));
  }

  /// Un documento vacío según CicloPlus (no queda ningún dato de ninguna versión).
  static bool _cloudEmpty(Map<String, dynamic> j) {
    for (final e in j.entries) {
      final v = e.value;
      if (v == null || v == false || v == '' || v == 0) continue;
      if (e.key == 'flow' && v == 'none') continue;
      if (v is List && v.isEmpty) continue;
      if (v is Map && v.isEmpty) continue;
      return false;
    }
    return true;
  }

  static DayLog fromCloud(Map<String, dynamic> j) {
    final flow = _flows.indexOf((j['flow'] as String?) ?? 'none');
    final syms = ((j['symptoms'] as List?) ?? const []).map((e) => _symFromCloud[e.toString()] ?? e.toString()).toSet();
    final levels = (j['symptomLevels'] as Map?) ?? const {};
    var pain = (j['goPain'] as num?)?.toInt() ?? 0;
    if (pain == 0 && levels['dolor'] != null) pain = _levels.indexOf(levels['dolor'].toString()) + 1;
    var mood = (j['goMood'] as num?)?.toInt() ?? 0;
    if (mood == 0) mood = _moodFromList(((j['mood'] as List?) ?? const []).map((e) => e.toString()).toList());
    final sex = j['sex'] == true ? (j['unprotected'] == true ? 2 : 1) : 0;
    return DayLog(
      flow: flow < 0 ? 0 : flow,
      symptoms: syms,
      pain: pain < 0 ? 0 : pain,
      mood: mood,
      note: (j['note'] as String?) ?? '',
      water: (j['water'] as num?)?.toInt() ?? 0,
      sleep: (j['sleep'] as num?)?.toDouble(),
      weight: (j['weight'] as num?)?.toDouble(),
      sex: sex,
      breastExam: j['breastSelfExam'] != null,
      activity: (j['activity'] as num?)?.toInt() ?? 0,
      extra: {for (final k in extraKeys) if (j[k] != null) k: j[k] is List ? List.from(j[k] as List) : j[k]},
    );
  }

  /// Ánimo de CicloPlus (lista de estados) → escala de 1 a 5 del diseño nuevo.
  static int _moodFromList(List<String> m) {
    if (m.isEmpty) return 0;
    if (m.contains('feliz') || m.contains('enamorada')) return 5;
    if (m.contains('deprimida')) return 1;
    if (m.contains('triste') || m.contains('enfadada') || m.contains('ansiosa')) return 2;
    return 3;
  }

  static Map<String, dynamic> toCloud(DayLog l, Map<String, dynamic> old) {
    final j = Map<String, dynamic>.from(old);
    j['flow'] = _flows[l.flow.clamp(0, 3)];
    // Síntomas: los del diseño nuevo + los que solo existían en CicloPlus.
    final known = {'dolor', 'animo', 'energia', 'antojos', 'hinchazon', 'sueno', 'acne', 'dolorcab'};
    final oldSyms = ((old['symptoms'] as List?) ?? const []).map((e) => e.toString()).where((s) => !known.contains(s));
    j['symptoms'] = [...oldSyms, ...l.symptoms.map((s) => _symToCloud[s] ?? s)];
    final levels = Map<String, dynamic>.from((old['symptomLevels'] as Map?) ?? const {});
    if (l.pain > 0) {
      levels['dolor'] = _levels[(l.pain - 1).clamp(0, 2)];
    } else {
      levels.remove('dolor');
    }
    j['symptomLevels'] = levels;
    j['goPain'] = l.pain == 0 ? null : l.pain;
    j['goMood'] = l.mood == 0 ? null : l.mood;
    j['note'] = l.note;
    j['water'] = l.water == 0 ? null : l.water;
    j['sleep'] = l.sleep;
    j['weight'] = l.weight;
    j['sex'] = l.sex > 0;
    j['unprotected'] = l.sex == 2;
    for (final k in extraKeys) {
      j[k] = l.extra[k];
    }
    if (l.breastExam) {
      j['breastSelfExam'] = l.extra['breastSelfExam'] ?? old['breastSelfExam'] ?? 'normal';
    } else {
      j['breastSelfExam'] = null;
    }
    // Valores "vacíos" de CicloPlus que no hace falta guardar.
    for (final k in ['sexDesire', 'sexMasturbation', 'sexOrgasm', 'sexNoOrgasm', 'sexNone', 'diu']) {
      if (j[k] == false) j.remove(k);
    }
    if (j['medication'] is List && (j['medication'] as List).isEmpty) j.remove('medication');
    if (j['skinHair'] is List && (j['skinHair'] as List).isEmpty) j.remove('skinHair');
    j['activity'] = l.activity == 0 ? null : l.activity;
    j.removeWhere((k, v) => v == null);
    return j;
  }
}
