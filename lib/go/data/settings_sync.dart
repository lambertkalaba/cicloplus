import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copia en la nube de los ajustes y del progreso de Michi, para no perder
/// nada al cambiar de móvil. Se guarda dentro del propio documento de la
/// cuenta (users/{uid}, campo `appSettings`), que solo puede leer y escribir
/// la dueña.
///
/// Los días (regla, síntomas, notas…) ya van aparte en users/{uid}/days.
/// Se quedan SOLO en el móvil, a propósito:
///  - Tradiciones, Ramadán y santo (prometimos que serían privados).
///  - El PIN / bloqueo (para no bloquear un móvil nuevo).
///  - Rutas de fotos y cosas propias de cada aparato.
class SettingsSync {
  SettingsSync._();

  static const _field = 'appSettings';
  static const _restoredKey = 'cloud_settings_restored_uid';

  static const _skipExact = {
    'logs', 'go_uid', 'photoName', 'docsPath', _restoredKey,
    'tradition', 'santo_md', 'ramadan_on', 'ramadan_qada', 'ramadan_lead', 'michiSaint',
    'cicloplus_pin', 'cicloplus_profile_photo', 'cicloplus_health_sync_enabled',
    'cicloplus_pending_reconnect_owner_uid', 'cicloplus_pending_reconnect_request_id',
  };
  static const _skipPrefixes = ['go_upgrade', 'flutter.', 'ramadan', 'cloud_settings_'];
  static final _skipWords = RegExp(r'(^|_)(pin|lock|token|fcm|biometric)(_|$)', caseSensitive: false);

  static String? _uid;
  static Timer? _timer;
  static AppLifecycleListener? _life;

  /// Hora de la última copia subida (para "Mi cuenta").
  static final ValueNotifier<DateTime?> lastUpload = ValueNotifier(null);

  static Future<DateTime?> loadLastUpload() async {
    final p = await SharedPreferences.getInstance();
    final d = DateTime.tryParse(p.getString('cloud_settings_at') ?? '');
    if (d != null && lastUpload.value == null) lastUpload.value = d;
    return lastUpload.value;
  }

  /// Sube ya (botón "Guardar ahora").
  static Future<bool> uploadNow() async {
    final before = lastUpload.value;
    await upload();
    return lastUpload.value != null && lastUpload.value != before;
  }

  static bool _keep(String k) {
    if (_skipExact.contains(k)) return false;
    if (_skipPrefixes.any(k.startsWith)) return false;
    if (_skipWords.hasMatch(k)) return false;
    return true;
  }

  static DocumentReference<Map<String, dynamic>> _doc(String uid) => FirebaseFirestore.instance.collection('users').doc(uid);

  /// Al entrar en un móvil que aún no tiene los ajustes de esta cuenta:
  /// los trae de la nube. Devuelve true si ha cambiado algo.
  static Future<bool> restoreIfNeeded(String uid) async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_restoredKey) == uid) return false;
    try {
      final snap = await _doc(uid).get().timeout(const Duration(seconds: 25));
      final data = snap.data()?[_field];
      await p.setString(_restoredKey, uid);
      if (data is! Map) return false;
      var changed = false;
      for (final e in data.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (!_keep(k) || v is! Map) continue;
        final t = v['t'], val = v['v'];
        try {
          switch (t) {
            case 'b':
              await p.setBool(k, val as bool);
            case 'i':
              await p.setInt(k, (val as num).toInt());
            case 'd':
              await p.setDouble(k, (val as num).toDouble());
            case 's':
              await p.setString(k, val as String);
            case 'l':
              await p.setStringList(k, (val as List).map((x) => x.toString()).toList());
            default:
              continue;
          }
          changed = true;
        } catch (_) {}
      }
      return changed;
    } catch (e) {
      // Sin conexión o lenta: se vuelve a intentar antes de la próxima subida.
      debugPrint('SettingsSync restore: $e');
      return false;
    }
  }

  /// Empieza a subir los cambios de esta cuenta (con un pequeño retraso
  /// para juntar varios cambios seguidos) y al salir de la app.
  static void start(String uid) {
    _uid = uid;
    _life ??= AppLifecycleListener(onPause: () => upload(), onHide: () => upload());
    schedule();
  }

  static void stop() {
    _timer?.cancel();
    _uid = null;
  }

  static void schedule() {
    if (_uid == null) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), upload);
  }

  static Future<void> upload() async {
    final uid = _uid;
    if (uid == null) return;
    _timer?.cancel();
    try {
      final p = await SharedPreferences.getInstance();
      // No pisar la copia de la nube antes de haberla traído a este móvil:
      // si aún no se pudo leer, se intenta ahora.
      if (p.getString(_restoredKey) != uid) {
        await restoreIfNeeded(uid);
        if (p.getString(_restoredKey) != uid) return;
      }
      final out = <String, Object>{};
      var total = 0;
      for (final k in p.getKeys()) {
        if (!_keep(k)) continue;
        final v = p.get(k);
        Map<String, Object>? e;
        if (v is bool) {
          e = {'t': 'b', 'v': v};
        } else if (v is int) {
          e = {'t': 'i', 'v': v};
        } else if (v is double) {
          e = {'t': 'd', 'v': v};
        } else if (v is String) {
          if (v.length > 200000) continue;
          e = {'t': 's', 'v': v};
        } else if (v is List) {
          e = {'t': 'l', 'v': v.map((x) => x.toString()).toList()};
        }
        if (e == null) continue;
        final size = jsonEncode(e).length + k.length;
        if (total + size > 700000) continue; // bajo el límite de 1 MB del documento
        total += size;
        out[k] = e;
      }
      await _doc(uid)
          .set({_field: out, '${_field}At': FieldValue.serverTimestamp()}, SetOptions(mergeFields: [_field, '${_field}At']))
          .timeout(const Duration(seconds: 25));
      final now = DateTime.now();
      await p.setString('cloud_settings_at', now.toIso8601String());
      lastUpload.value = now;
    } catch (e) {
      debugPrint('SettingsSync upload: $e');
    }
  }
}
