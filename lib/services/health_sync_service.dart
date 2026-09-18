import 'package:health/health.dart';

import '../models/day_entry.dart';

/// Resultado de leer datos de salud nativos (Apple Salud / Health Connect)
/// para un día concreto — solo trae los campos que sí encontró.
class HealthDaySnapshot {
  final double? weight;
  final double? sleepHours;
  final double? temperature;

  const HealthDaySnapshot({this.weight, this.sleepHours, this.temperature});

  bool get isEmpty => weight == null && sleepHours == null && temperature == null;
}

/// Una lectura de salud fechada, usada por [HealthSyncService.readRange]
/// para poder luego agrupar por fase del ciclo (cada lectura conserva su
/// fecha original, algo que [readDay] no necesitaba porque ya trabajaba
/// con un solo día).
class HealthDataPoint {
  final DateTime date;
  final double value;

  const HealthDataPoint({required this.date, required this.value});
}

/// Sincroniza peso, sueño, temperatura basal y flujo menstrual con Apple
/// Salud (iOS, vía HealthKit) o Google Fit (Android, vía Health Connect),
/// usando el paquete `health` como capa común entre plataformas.
///
/// Todo el acceso es opcional y bajo consentimiento explícito: la persona
/// activa la sincronización desde Configuración, y solo entonces se piden
/// permisos nativos. Si el usuario no tiene Health Connect instalado
/// (frecuente en emuladores Android o dispositivos antiguos), los métodos
/// devuelven `false`/listas vacías en vez de lanzar una excepción, para que
/// el resto de la app siga funcionando con normalidad sin esta función.
class HealthSyncService {
  final Health _health = Health();
  bool _configured = false;

  static const _types = [
    HealthDataType.WEIGHT,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.MENSTRUATION_FLOW,
    // Añadidos para las tarjetas "por fase del ciclo" de Estadísticas
    // (variabilidad de la frecuencia cardíaca y frecuencia cardíaca en
    // reposo) — a petición del usuario de imitar el estilo de una app de
    // referencia que muestra estas 2 métricas comparadas entre fases.
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESTING_HEART_RATE,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Pide permiso de lectura/escritura para los 4 tipos de dato. Devuelve
  /// `false` si la persona los denegó o si la plataforma no está
  /// disponible (p. ej. Health Connect no instalado).
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      final permissions = _types.map((_) => HealthDataAccess.READ_WRITE).toList();
      return await _health.requestAuthorization(_types, permissions: permissions);
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    try {
      await _ensureConfigured();
      final permissions = _types.map((_) => HealthDataAccess.READ_WRITE).toList();
      return await _health.hasPermissions(_types, permissions: permissions) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Lee peso/sueño/temperatura ya registrados en la plataforma nativa
  /// para el día indicado (busca en la ventana [00:00, 23:59] de esa
  /// fecha). Se usa para pre-rellenar el editor de día si el usuario no
  /// ha introducido esos valores todavía.
  Future<HealthDaySnapshot> readDay(DateTime date) async {
    try {
      await _ensureConfigured();
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: start,
        endTime: end,
      );

      double? weight;
      double? temperature;
      double sleepMinutes = 0;
      bool hasSleep = false;

      for (final p in points) {
        final value = p.value;
        if (value is! NumericHealthValue) continue;
        final numeric = value.numericValue.toDouble();
        switch (p.type) {
          case HealthDataType.WEIGHT:
            weight = numeric;
            break;
          case HealthDataType.BODY_TEMPERATURE:
            temperature = numeric;
            break;
          case HealthDataType.SLEEP_ASLEEP:
            sleepMinutes += numeric;
            hasSleep = true;
            break;
          default:
            break;
        }
      }

      return HealthDaySnapshot(
        weight: weight,
        temperature: temperature,
        sleepHours: hasSleep ? sleepMinutes / 60.0 : null,
      );
    } catch (_) {
      return const HealthDaySnapshot();
    }
  }

  /// Lee un tipo de dato numérico (HRV, frecuencia cardíaca en reposo,
  /// temperatura...) en un rango de fechas, devolviendo cada lectura con
  /// su fecha original — a diferencia de [readDay], que colapsa todo un
  /// día en un solo valor. Se usa para las tarjetas de Estadísticas que
  /// comparan una métrica entre las 4 fases del ciclo: cada lectura se
  /// clasifica después según la fase en la que cayó su fecha. Si la
  /// plataforma no tiene el permiso o no hay datos, devuelve lista vacía
  /// en vez de lanzar una excepción.
  Future<List<HealthDataPoint>> readRange(HealthDataType type, DateTime start, DateTime end) async {
    try {
      await _ensureConfigured();
      final points = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: start,
        endTime: end,
      );
      final result = <HealthDataPoint>[];
      for (final p in points) {
        final value = p.value;
        if (value is! NumericHealthValue) continue;
        result.add(HealthDataPoint(date: p.dateFrom, value: value.numericValue.toDouble()));
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  /// Escribe hacia la plataforma nativa los valores que la persona
  /// registró manualmente en CicloPlus para un día (solo los campos no
  /// nulos). No falla de forma visible si la escritura no está disponible
  /// — la app sigue funcionando igual usando solo su propio
  /// almacenamiento local.
  Future<void> writeDay(DateTime date, DayEntry entry) async {
    try {
      await _ensureConfigured();

      if (entry.weight != null) {
        await _health.writeHealthData(
          value: entry.weight!,
          type: HealthDataType.WEIGHT,
          startTime: date,
          endTime: date,
          recordingMethod: RecordingMethod.manual,
        );
      }
      if (entry.temp != null) {
        await _health.writeHealthData(
          value: entry.temp!,
          type: HealthDataType.BODY_TEMPERATURE,
          startTime: date,
          endTime: date,
          recordingMethod: RecordingMethod.manual,
        );
      }
      if (entry.sleep != null) {
        final end = date;
        final start = date.subtract(Duration(minutes: (entry.sleep! * 60).round()));
        await _health.writeHealthData(
          value: entry.sleep! * 60,
          type: HealthDataType.SLEEP_ASLEEP,
          startTime: start,
          endTime: end,
          recordingMethod: RecordingMethod.manual,
        );
      }
      if (entry.flow != 'none') {
        await _health.writeHealthData(
          value: _flowToHealthValue(entry.flow).toDouble(),
          type: HealthDataType.MENSTRUATION_FLOW,
          startTime: date,
          endTime: date,
          recordingMethod: RecordingMethod.manual,
        );
      }
    } catch (_) {
      // Silencioso a propósito: escribir en la plataforma nativa es un
      // "extra" opcional, nunca debe interrumpir el guardado local del día.
    }
  }

  /// Mapea el flujo interno de CicloPlus ('light'|'medium'|'heavy') al
  /// nivel numérico esperado por HealthKit/Health Connect (1=light,
  /// 2=medium, 3=heavy, siguiendo la escala de MenstruationFlowHealthValue).
  int _flowToHealthValue(String flow) {
    switch (flow) {
      case 'light':
        return 1;
      case 'medium':
        return 2;
      case 'heavy':
        return 3;
      default:
        return 2;
    }
  }
}
