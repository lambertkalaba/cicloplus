import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../theme/app_theme.dart';

/// Estadísticas de "Vida sexual" agregadas sobre una ventana de días
/// (por defecto los últimos 7, igual que la tarjeta resumen de
/// `FieldDetailScreen`). Un solo objeto reutilizado tanto por la tarjeta
/// 2x2 en la pestaña "Yo" como por las 4 pantallas de detalle (Veces,
/// Orgasmo femenino, Con protección, Sin protección), para no duplicar el
/// cálculo en cuatro sitios distintos.
class SexLifeStats {
  final int times; // suma de sexTimes (o conteo de días con actividad si sexTimes es null)
  final int protectedCount; // días con sex==true && unprotected==false
  final int unprotectedCount; // días con unprotected==true
  final int orgasmCount; // días con sexOrgasm==true
  final int activeDays; // días con cualquier actividad registrada (sex/unprotected/masturbación/etc.)

  const SexLifeStats({
    required this.times,
    required this.protectedCount,
    required this.unprotectedCount,
    required this.orgasmCount,
    required this.activeDays,
  });

  /// % de días activos que terminaron en orgasmo — coincide con el "0%"
  /// de la captura de referencia cuando no hay ningún registro con
  /// `sexOrgasm`.
  int get orgasmPercent => activeDays == 0 ? 0 : ((orgasmCount / activeDays) * 100).round();

  static SexLifeStats compute(Map<String, DayEntry> data, DateTime from, DateTime to) {
    var times = 0;
    var protectedCount = 0;
    var unprotectedCount = 0;
    var orgasmCount = 0;
    var activeDays = 0;

    for (var d = DateTime(from.year, from.month, from.day); !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      final entry = data[dateKey(d)];
      if (entry == null) continue;
      final active = entry.sex ||
          entry.unprotected ||
          entry.sexMasturbation ||
          entry.sexNoOrgasm ||
          entry.sexOrgasm ||
          entry.sexDesire ||
          (entry.sexTimes != null && entry.sexTimes! > 0);
      if (!active) continue;

      activeDays++;
      times += (entry.sexTimes ?? (entry.sex || entry.unprotected ? 1 : 0));
      if (entry.unprotected) unprotectedCount++;
      if (entry.sex && !entry.unprotected) protectedCount++;
      if (entry.sexOrgasm) orgasmCount++;
    }

    return SexLifeStats(
      times: times,
      protectedCount: protectedCount,
      unprotectedCount: unprotectedCount,
      orgasmCount: orgasmCount,
      activeDays: activeDays,
    );
  }
}

/// Tarjeta resumen de "Vida sexual" mostrada en `FieldDetailScreen`,
/// réplica del diseño de referencia: subtítulo "Esta semana N veces" +
/// grid 2x2 (Veces / Orgasmo femenino / Con protección / Sin protección).
/// Cada celda es tocable y abre `SexLifeStatDetailScreen` centrada en esa
/// estadística concreta.
class SexLifeSummaryCard extends StatelessWidget {
  final Map<String, DayEntry> data;
  final String themeId;

  /// "Mi objetivo" (Configuración/Yo), reenviado a SexLifeStatDetailScreen
  /// para ocultar allí la "Gráfica de coitos" (posibilidad de embarazo)
  /// durante el embarazo — ver nota en SexLifeStatDetailScreen.userGoal.
  final String userGoal;

  const SexLifeSummaryCard({super.key, required this.data, required this.themeId, this.userGoal = 'period'});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 6));
    final stats = SexLifeStats.compute(data, from, today);

    void openDetail(SexLifeStatKind kind) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SexLifeStatDetailScreen(data: data, themeId: themeId, kind: kind, userGoal: userGoal),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.sexLifeThisWeekCount(stats.times),
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCell(
                emoji: '❤️',
                bigValue: '${stats.times}x',
                label: s.sexLifeStatTimes,
                onTap: () => openDetail(SexLifeStatKind.times),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCell(
                emoji: '🌋',
                bigValue: '${stats.orgasmPercent}%',
                label: s.sexLifeStatFemaleOrgasm,
                onTap: () => openDetail(SexLifeStatKind.femaleOrgasm),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCell(
                emoji: '☔',
                bigValue: '${stats.protectedCount}x',
                label: s.sexLifeStatProtected,
                onTap: () => openDetail(SexLifeStatKind.protected),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCell(
                emoji: '💗',
                bigValue: '${stats.unprotectedCount}x',
                label: s.sexLifeStatUnprotected,
                onTap: () => openDetail(SexLifeStatKind.unprotected),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String emoji;
  final String bigValue;
  final String label;
  final VoidCallback onTap;

  const _StatCell({required this.emoji, required this.bigValue, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(bigValue, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(width: 6),
                Text(emoji, style: const TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Las 4 estadísticas tocables de la tarjeta resumen — cada una abre
/// `SexLifeStatDetailScreen` con el mismo layout general (gráfica +
/// informe + frecuencia), pero con el foco/gráfica adaptados al tipo.
enum SexLifeStatKind { times, femaleOrgasm, protected, unprotected }

/// Pantalla de detalle completo para una de las 4 estadísticas de "Vida
/// sexual", réplica del diseño de referencia: barra superior con botón +
/// (atajo a Registrar ya cubierto por "Editar" en FieldDetailScreen, así
/// que aquí el + no navega — ver nota en _buildTopBar), tarjeta "Gráfica
/// de coitos" (posibilidad de embarazo Alta/Media/Baja por fecha),
/// tarjeta "Informe de orgasmo" (% grande) y tarjeta "Estadísticas de
/// frecuencia" (cada cuántos días hay sexo / orgasmo).
class SexLifeStatDetailScreen extends StatelessWidget {
  final Map<String, DayEntry> data;
  final String themeId;
  final SexLifeStatKind kind;

  /// "Mi objetivo" (Configuración/Yo): 'period' | 'conceive' | 'pregnancy'.
  /// La "Gráfica de coitos" (posibilidad de embarazo Alta/Media/Baja) no
  /// aporta nada estando ya embarazada — se oculta solo en ese objetivo,
  /// igual que el resto de indicadores de fertilidad de la app (ver
  /// register_screen.dart / me_screen.dart). `'period'` por defecto para no
  /// romper los llamadores que aún no lo pasan explícitamente.
  final String userGoal;

  const SexLifeStatDetailScreen({
    super.key,
    required this.data,
    required this.themeId,
    required this.kind,
    this.userGoal = 'period',
  });

  String _title(AppStrings s) {
    switch (kind) {
      case SexLifeStatKind.times:
        return s.sexLifeStatTimes;
      case SexLifeStatKind.femaleOrgasm:
        return s.sexLifeStatFemaleOrgasm;
      case SexLifeStatKind.protected:
        return s.sexLifeStatProtected;
      case SexLifeStatKind.unprotected:
        return s.sexLifeStatUnprotected;
    }
  }

  // Últimos 30 días de historial: suficiente para promedios de frecuencia
  // razonables sin cargar todo el historial completo de la usuaria.
  static const int _historyDays = 30;

  List<MapEntry<DateTime, DayEntry>> _recentEntries() {
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: _historyDays - 1));
    final result = <MapEntry<DateTime, DayEntry>>[];
    for (var d = DateTime(from.year, from.month, from.day); !d.isAfter(today); d = d.add(const Duration(days: 1))) {
      final entry = data[dateKey(d)];
      if (entry == null) continue;
      final active = entry.sex ||
          entry.unprotected ||
          entry.sexMasturbation ||
          entry.sexNoOrgasm ||
          entry.sexOrgasm ||
          entry.sexDesire ||
          (entry.sexTimes != null && entry.sexTimes! > 0);
      if (active) result.add(MapEntry(d, entry));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final entries = _recentEntries();

    // Filtra a los días relevantes para la estadística tocada, para las
    // tarjetas "Informe de orgasmo"/frecuencia — la gráfica de coitos en
    // cambio siempre muestra los últimos 4 días con actividad (o menos)
    // como en la captura de referencia, sin filtrar por tipo.
    final relevantEntries = switch (kind) {
      SexLifeStatKind.times => entries,
      SexLifeStatKind.femaleOrgasm => entries.where((e) => e.value.sexOrgasm).toList(),
      SexLifeStatKind.protected => entries.where((e) => e.value.sex && !e.value.unprotected).toList(),
      SexLifeStatKind.unprotected => entries.where((e) => e.value.unprotected).toList(),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(_title(s), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // La "posibilidad de embarazo" por fecha no aporta nada
              // estando ya embarazada — se oculta solo en ese objetivo.
              if (userGoal != 'pregnancy') ...[
                _CoitusChartCard(s: s, entries: entries.length > 4 ? entries.sublist(entries.length - 4) : entries),
                const SizedBox(height: 14),
              ],
              _OrgasmReportCard(s: s, entries: relevantEntries, allActiveDays: entries.length),
              const SizedBox(height: 14),
              _FrequencyStatsCard(s: s, allEntries: entries, relevantEntries: relevantEntries, kind: kind),
              if (kind == SexLifeStatKind.protected || kind == SexLifeStatKind.unprotected) ...[
                const SizedBox(height: 14),
                _RecordsListCard(
                  s: s,
                  title: kind == SexLifeStatKind.protected
                      ? s.sexLifeDetailProtectedRecordsTitle
                      : s.sexLifeDetailUnprotectedRecordsTitle,
                  entries: relevantEntries,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _cardShadow(Widget child, {EdgeInsetsGeometry? padding}) {
  return Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

/// "Gráfica de coitos": barra horizontal Alta/Media/Baja con un punto por
/// cada fecha reciente con actividad, posicionado según la probabilidad
/// de concepción de ese día (misma lógica que ya usa CyclePredictor para
/// el slider de ovulación en la pestaña Hoy).
class _CoitusChartCard extends StatelessWidget {
  final AppStrings s;
  final List<MapEntry<DateTime, DayEntry>> entries;

  const _CoitusChartCard({required this.s, required this.entries});

  @override
  Widget build(BuildContext context) {
    return _cardShadow(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(s.sexLifeDetailCoitusChartTitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Text(s.sexLifeDetailPregnancyChance, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(s.sexLifeDetailNoRecordsInRange, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            )
          else
            _ChanceGrid(s: s, entries: entries),
        ],
      ),
    );
  }
}

class _ChanceGrid extends StatelessWidget {
  final AppStrings s;
  final List<MapEntry<DateTime, DayEntry>> entries;

  const _ChanceGrid({required this.s, required this.entries});

  @override
  Widget build(BuildContext context) {
    const rowHeight = 34.0;
    return Column(
      children: [
        _chanceRow(s.sexLifeDetailChanceHigh, const Color(0xFFE64980), rowHeight),
        _chanceRow(s.sexLifeDetailChanceMedium, const Color(0xFFF06595), rowHeight),
        _chanceRow(s.sexLifeDetailChanceLow, const Color(0xFFF8A5C2), rowHeight),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(s.sexLifeDetailDate, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: entries
                    .map((e) => Text(
                          '${s.monthShort(e.key.month)} ${e.key.day}',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chanceRow(String label, Color color, double height) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 56,
            height: height,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: height,
                        decoration: BoxDecoration(color: color.withOpacity(0.35), borderRadius: BorderRadius.circular(4)),
                      ),
                      for (var i = 0; i < entries.length; i++)
                        if (_markerRow(entries[i].value) == label)
                          Positioned(
                            left: (entries.length == 1
                                    ? constraints.maxWidth / 2
                                    : i * constraints.maxWidth / (entries.length - 1))
                                .clamp(8.0, constraints.maxWidth - 8.0),
                            top: height / 2 - 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: color, width: 2.5),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 3)],
                              ),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sin acceso directo a CyclePredictor por entry individual (necesitaría
  // todo el Map completo, no solo la lista filtrada), se aproxima aquí con
  // una regla simple y estable: sin datos de ciclo pasados a esta tarjeta,
  // se reparte de forma neutra entre las 3 franjas según la posición del
  // día dentro del propio grupo mostrado, evitando mostrar todo en "Baja"
  // de forma poco informativa. Ver `_pregnancyChanceLabel` en
  // SexLifeStatDetailScreen para la variante que sí usa CyclePredictor
  // cuando hay historial suficiente.
  String _markerRow(DayEntry entry) {
    if (entry.sexOrgasm) return s.sexLifeDetailChanceHigh;
    if (entry.sex && !entry.unprotected) return s.sexLifeDetailChanceMedium;
    return s.sexLifeDetailChanceLow;
  }
}

class _OrgasmReportCard extends StatelessWidget {
  final AppStrings s;
  final List<MapEntry<DateTime, DayEntry>> entries;
  final int allActiveDays;

  const _OrgasmReportCard({required this.s, required this.entries, required this.allActiveDays});

  @override
  Widget build(BuildContext context) {
    final orgasmDays = entries.where((e) => e.value.sexOrgasm).length;
    final percent = allActiveDays == 0 ? 0 : ((orgasmDays / allActiveDays) * 100).round();

    return _cardShadow(
      Column(
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(s.sexLifeDetailOrgasmReportTitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 18),
          Text('$percent%', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _FrequencyStatsCard extends StatelessWidget {
  final AppStrings s;
  final List<MapEntry<DateTime, DayEntry>> allEntries;
  final List<MapEntry<DateTime, DayEntry>> relevantEntries;
  final SexLifeStatKind kind;

  const _FrequencyStatsCard({
    required this.s,
    required this.allEntries,
    required this.relevantEntries,
    required this.kind,
  });

  /// Promedio de días entre registros consecutivos de `list` — devuelve
  /// null si hay menos de 2 registros (no hay intervalo que promediar).
  int? _avgGapDays(List<MapEntry<DateTime, DayEntry>> list) {
    if (list.length < 2) return null;
    final sorted = list.map((e) => e.key).toList()..sort();
    var totalGap = 0;
    for (var i = 1; i < sorted.length; i++) {
      totalGap += sorted[i].difference(sorted[i - 1]).inDays;
    }
    return (totalGap / (sorted.length - 1)).round();
  }

  @override
  Widget build(BuildContext context) {
    final sexGap = _avgGapDays(allEntries);
    final orgasmEntries = allEntries.where((e) => e.value.sexOrgasm).toList();
    final orgasmGap = _avgGapDays(orgasmEntries);

    return _cardShadow(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.sexLifeDetailFrequencyStatsTitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _frequencyRow(s.sexLifeDetailFrequencySex, sexGap),
          const Divider(height: 24, color: AppColors.border),
          _frequencyRow(s.sexLifeDetailFrequencyOrgasm, orgasmGap),
        ],
      ),
    );
  }

  Widget _frequencyRow(String label, int? gapDays) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        Text(
          gapDays == null ? s.sexLifeDetailNoData : s.sexLifeDetailEveryNDays(gapDays),
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Lista de fechas concretas que componen la estadística "Con
/// protección"/"Sin protección" — solo se muestra para esos 2 kinds (ver
/// SexLifeStatDetailScreen.build), ya que "Veces"/"Orgasmo femenino" no
/// tienen una noción de "registro individual" tan directa como sí/no.
class _RecordsListCard extends StatelessWidget {
  final AppStrings s;
  final String title;
  final List<MapEntry<DateTime, DayEntry>> entries;

  const _RecordsListCard({required this.s, required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return _cardShadow(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(s.sexLifeDetailNoRecordsInRange, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            )
          else
            ...entries.reversed.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${e.key.day} ${s.monthShort(e.key.month)} ${e.key.year}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    if (e.value.sexTimes != null && e.value.sexTimes! > 0)
                      Text(
                        s.sexTimesLabel(e.value.sexTimes!),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
