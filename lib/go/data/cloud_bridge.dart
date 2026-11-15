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

  /// Ids de síntomas que cambian de nombre entre los dos diseños.
  static const _symToCloud = {'cabeza': 'dolorcab'};
  static const _symFromCloud = {'dolorcab': 'cabeza'};

  Future<Map<String, DayLog>> loadAll() async {
    final snap = await _days.get();
    raw.clear();
    final out = <String, DayLog>{};
    for (final d in snap.docs) {
      raw[d.id] = Map<String, dynamic>.from(d.data());
      final log = fromCloud(raw[d.id]!);
      if (!log.isEmpty) out[d.id] = log;
    }
    return out;
  }

  /// Guarda solo los días que han cambiado.
  Future<void> sync(Map<String, DayLog> logs) async {
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

  static bool _same(DayLog a, DayLog b) => _eq(a.toJson(), b.toJson());

  static bool _eq(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      final x = a[k], y = b[k];
      if (x is List && y is List) {
        if (x.length != y.length || !x.toSet().containsAll(y)) return false;
      } else if (x != y) {
        return false;
      }
    }
    return true;
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
    if (l.breastExam) {
      j['breastSelfExam'] = old['breastSelfExam'] ?? 'normal';
    } else {
      j['breastSelfExam'] = null;
    }
    j['activity'] = l.activity == 0 ? null : l.activity;
    j.removeWhere((k, v) => v == null);
    return j;
  }
}
