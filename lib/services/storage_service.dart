import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_entry.dart';

/// Guarda los registros del ciclo en Firestore (en la nube, ligados a la
/// cuenta del usuario) para poder sincronizarlos entre dispositivos y,
/// más adelante, verlos también desde la página web.
///
/// También mantiene una copia en SharedPreferences (caché local) para que
/// la app siga funcionando y mostrando los últimos datos conocidos si el
/// usuario abre CicloPlus sin conexión a internet. Cloud Firestore además
/// tiene su propia caché offline integrada, así que las escrituras hechas
/// sin conexión se sincronizan solas en cuanto vuelve el internet.
class StorageService {
  static const _legacyKey = 'cicloplus_data_v1';

  final String userId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StorageService(this.userId);

  String get _cacheKey => 'cicloplus_data_cache_v1_$userId';

  CollectionReference<Map<String, dynamic>> get _daysCollection =>
      _db.collection('users').doc(userId).collection('days');

  /// Carga todos los registros desde Firestore. Si falla (sin conexión, por
  /// ejemplo), recae en la última copia guardada localmente para que la
  /// persona pueda seguir viendo su calendario.
  Future<Map<String, DayEntry>> loadAll() async {
    try {
      final snapshot = await _daysCollection.get();
      final data = <String, DayEntry>{};
      for (final doc in snapshot.docs) {
        data[doc.id] = DayEntry.fromJson(doc.data());
      }
      await _saveCache(data);
      await _migrateLegacyDataIfNeeded(data);
      return data;
    } catch (_) {
      // Sin conexión o error de red: mostramos la última copia local
      // conocida en vez de dejar la pantalla vacía.
      return _loadCache();
    }
  }

  Future<void> saveAll(Map<String, DayEntry> data) async {
    await _saveCache(data);
    // Sincroniza documento por documento. Firestore hace cola de estas
    // escrituras automáticamente si no hay conexión, y las envía cuando
    // vuelve internet.
    final batch = _db.batch();
    for (final entry in data.entries) {
      batch.set(_daysCollection.doc(entry.key), entry.value.toJson());
    }
    await batch.commit();
  }

  Future<void> saveDay(Map<String, DayEntry> data, String dateKey, DayEntry entry) async {
    final updated = Map<String, DayEntry>.from(data);
    if (entry.isEmpty) {
      updated.remove(dateKey);
      await deleteDay(data, dateKey);
    } else {
      updated[dateKey] = entry;
      await _saveCache(updated);
      await _daysCollection.doc(dateKey).set(entry.toJson());
    }
  }

  Future<void> deleteDay(Map<String, DayEntry> data, String dateKey) async {
    final updated = Map<String, DayEntry>.from(data);
    updated.remove(dateKey);
    await _saveCache(updated);
    await _daysCollection.doc(dateKey).delete();
  }

  /// Borra TODOS los registros del ciclo (todos los documentos de
  /// `days` en Firestore + la caché local), usado por "Borrar todos los
  /// datos" en Configuración. A diferencia de `saveAll({})` (que no
  /// elimina nada, solo no añade nada nuevo, dejando huérfanos los
  /// documentos ya existentes), esto sí borra cada documento existente
  /// uno por uno con un batch, igual que `saveAll` hace para escribir.
  /// No toca configuración de la cuenta (tema, PIN, perfil, idioma,
  /// recordatorios): solo el historial de días del ciclo, que es lo que
  /// la fila "Borrar todos los datos" promete borrar.
  Future<void> deleteAll() async {
    final snapshot = await _daysCollection.get();
    if (snapshot.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _saveCache(const {});
  }

  Future<void> _saveCache(Map<String, DayEntry> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(data.map((key, value) => MapEntry(key, value.toJson())));
    await prefs.setString(_cacheKey, encoded);
  }

  Future<Map<String, DayEntry>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, DayEntry.fromJson(value as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  /// Migración de una sola vez: si esta cuenta no tiene nada todavía en
  /// Firestore, pero hay datos guardados localmente de antes de que
  /// existieran las cuentas (versión "solo local" del prototipo), los
  /// subimos a la nube para no perder el historial de quien ya usaba la app.
  Future<void> _migrateLegacyDataIfNeeded(Map<String, DayEntry> currentCloudData) async {
    if (currentCloudData.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      final legacyData = decoded.map(
        (key, value) => MapEntry(key, DayEntry.fromJson(value as Map<String, dynamic>)),
      );
      if (legacyData.isEmpty) return;

      await saveAll(legacyData);
      await prefs.remove(_legacyKey);
    } catch (_) {
      // Si los datos antiguos están corruptos, no bloqueamos el arranque
      // de la app — simplemente no hay nada que migrar.
    }
  }
}
