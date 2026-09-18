import 'package:health/health.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/cycle_predictor.dart';
import '../services/health_sync_service.dart';
import '../theme/app_theme.dart';

/// Promedio de una métrica de salud para una fase concreta del ciclo,
/// junto con cuántas lecturas la componen (para poder ocultar la barra si
/// no hay datos suficientes).
class _PhaseAverage {
  final String phaseKey;
  final double average;
  final int sampleCount;
  const _PhaseAverage({required this.phaseKey, required this.average, required this.sampleCount});
}

/// Configuración de una de las 3 métricas de salud comparadas por fase
/// (variabilidad de la frecuencia cardíaca, frecuencia cardíaca en
/// reposo, o desviación de temperatura).
class PhaseHealthMetric {
  final HealthDataType healthType;
  final String title;
  final String unit;
  final Color accentColor;
  final IconData icon;
  final int decimals;
  final bool showAsDeviation;
  final String Function(AppStrings s) infoExplanationBuilder;

  const PhaseHealthMetric({
    required this.healthType,
    required this.title,
    required this.unit,
    required this.accentColor,
    required this.icon,
    required this.infoExplanationBuilder,
    this.decimals = 0,
    this.showAsDeviation = false,
  });
}

/// Grupo de tarjetas de salud por fase: gestiona cuál de las 3 está
/// "expandida" (a petición del usuario: al tocar una tarjeta, esta crece
/// y las otras 2 se encogen). Solo una puede estar expandida a la vez;
/// tocar la misma otra vez vuelve todas a su tamaño normal.
class PhaseHealthCardsGroup extends StatefulWidget {
  final List<PhaseHealthMetric> metrics;
  final String Function(String phaseName) highestLabelBuilder;
  final String Function(String phaseName) lowestLabelBuilder;
  final CyclePredictor predictor;
  final int lookbackDays;

  const PhaseHealthCardsGroup({
    super.key,
    required this.metrics,
    required this.highestLabelBuilder,
    required this.lowestLabelBuilder,
    required this.predictor,
    this.lookbackDays = 90,
  });

  @override
  State<PhaseHealthCardsGroup> createState() => _PhaseHealthCardsGroupState();
}

class _PhaseHealthCardsGroupState extends State<PhaseHealthCardsGroup> {
  int? _expandedIndex;

  void _handleTap(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.metrics.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          PhaseHealthCard(
            metric: widget.metrics[i],
            highestLabelBuilder: widget.highestLabelBuilder,
            lowestLabelBuilder: widget.lowestLabelBuilder,
            predictor: widget.predictor,
            lookbackDays: widget.lookbackDays,
            // null = tamaño normal (nada expandido); true = esta es la
            // expandida; false = otra está expandida, así que esta se
            // encoge.
            expansionState: _expandedIndex == null ? null : (_expandedIndex == i),
            onTap: () => _handleTap(i),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta que compara una métrica de salud entre las 4 fases del ciclo,
/// con un gráfico de barras + promedio general + fase con el valor más
/// alto/más bajo — al estilo de una app de referencia que el usuario
/// compartió como modelo. Los datos vienen de Apple Salud / Health
/// Connect (vía [HealthSyncService]); si no hay suficientes lecturas
/// sincronizadas para al menos 2 fases distintas, la tarjeta no se
/// muestra (a petición explícita del usuario de no mostrar tarjetas con
/// datos falsos/vacíos).
///
/// Al tocarla, se anima entre 3 tamaños: normal, expandida (más grande,
/// con ícono de información sobre qué mide y que requiere un
/// reloj/wearable conectado) y comprimida (cuando otra tarjeta del grupo
/// está expandida).
class PhaseHealthCard extends StatefulWidget {
  final PhaseHealthMetric metric;
  final String Function(String phaseName) highestLabelBuilder;
  final String Function(String phaseName) lowestLabelBuilder;
  final CyclePredictor predictor;
  final int lookbackDays;

  /// null = tamaño normal; true = expandida; false = comprimida.
  final bool? expansionState;
  final VoidCallback onTap;

  const PhaseHealthCard({
    super.key,
    required this.metric,
    required this.highestLabelBuilder,
    required this.lowestLabelBuilder,
    required this.predictor,
    required this.expansionState,
    required this.onTap,
    this.lookbackDays = 90,
  });

  @override
  State<PhaseHealthCard> createState() => _PhaseHealthCardState();
}

class _PhaseHealthCardState extends State<PhaseHealthCard> {
  final HealthSyncService _health = HealthSyncService();
  bool _loading = true;
  List<_PhaseAverage> _averages = const [];

  static const _phaseOrder = ['menstrual', 'folicular', 'ovulacion', 'lutea'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PhaseHealthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metric.healthType != widget.metric.healthType) _load();
  }

  Future<void> _load() async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: widget.lookbackDays));
    final points = await _health.readRange(widget.metric.healthType, start, end);
    if (!mounted) return;

    // Agrupa cada lectura según la fase del ciclo en la que cayó su
    // fecha, usando el mapeo histórico de CyclePredictor.phaseKeyForDate.
    final byPhase = <String, List<double>>{for (final p in _phaseOrder) p: []};
    for (final point in points) {
      final phase = widget.predictor.phaseKeyForDate(point.date);
      if (phase == null || !byPhase.containsKey(phase)) continue;
      byPhase[phase]!.add(point.value);
    }

    final averages = <_PhaseAverage>[];
    for (final phase in _phaseOrder) {
      final values = byPhase[phase]!;
      if (values.isEmpty) continue;
      final avg = values.reduce((a, b) => a + b) / values.length;
      averages.add(_PhaseAverage(phaseKey: phase, average: avg, sampleCount: values.length));
    }

    setState(() {
      _averages = averages;
      _loading = false;
    });
  }

  void _showInfoSheet(AppStrings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.metric.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.metric.icon, size: 17, color: widget.metric.accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.metric.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.metric.infoExplanationBuilder(s),
                style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.metric.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.watch_outlined, size: 16, color: widget.metric.accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.statsRequiresWearableBadge,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: widget.metric.accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final metric = widget.metric;

    // Con menos de 2 fases con datos no hay nada útil que comparar. En vez
    // de ocultar la tarjeta, se muestra igualmente con barras en 0 y un
    // aviso de que hace falta un reloj/wearable conectado — así la
    // persona siempre ve que la métrica existe, aunque aún no tenga datos.
    final hasEnoughData = !_loading && _averages.length >= 2;

    final sorted = hasEnoughData ? ([..._averages]..sort((a, b) => a.average.compareTo(b.average))) : const <_PhaseAverage>[];
    final lowest = hasEnoughData ? sorted.first : null;
    final highest = hasEnoughData ? sorted.last : null;
    final overallAvg = hasEnoughData ? _averages.map((a) => a.average).reduce((a, b) => a + b) / _averages.length : 0.0;
    final maxValue = hasEnoughData ? _averages.map((a) => a.average).reduce((a, b) => a > b ? a : b) : 0.0;

    final isExpanded = widget.expansionState == true;
    final isCompact = widget.expansionState == false;

    String fmt(double v) {
      final display = metric.showAsDeviation ? v - overallAvg : v;
      final sign = metric.showAsDeviation && display > 0 ? '+' : '';
      return '$sign${display.toStringAsFixed(metric.decimals)}${metric.unit}';
    }

    // Tamaños que se interpolan con AnimatedContainer/AnimatedDefaultTextStyle
    // según el estado: normal (sin nada expandido), expandida (esta
    // tarjeta) o comprimida (otra tarjeta expandida).
    final barMaxHeight = isExpanded ? 74.0 : (isCompact ? 40.0 : 58.0);
    final chartRowHeight = isExpanded ? 140.0 : (isCompact ? 100.0 : 116.0);
    final titleSize = isExpanded ? 14.5 : (isCompact ? 11.5 : 13.0);
    final valueSize = isExpanded ? 20.0 : (isCompact ? 14.0 : 17.0);
    final vPad = isExpanded ? 18.0 : (isCompact ? 10.0 : 14.0);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: vPad),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isExpanded ? metric.accentColor.withOpacity(0.45) : AppColors.border, width: isExpanded ? 2 : 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isExpanded
              ? [BoxShadow(color: metric.accentColor.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: metric.accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                  child: Icon(metric.icon, size: 15, color: metric.accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 320),
                        style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w700, height: 1.25),
                        child: Text(metric.title, maxLines: isCompact ? 1 : 2, overflow: TextOverflow.ellipsis),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          hasEnoughData
                              ? widget.highestLabelBuilder(s.phaseName(highest!.phaseKey))
                              : s.statsRequiresWearableBadge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasEnoughData ? metric.accentColor : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Ícono de información: solo visible cuando esta tarjeta
                // está expandida, con una pequeña animación de aparición.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: isExpanded
                      ? GestureDetector(
                          key: const ValueKey('info'),
                          onTap: () => _showInfoSheet(s),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(color: metric.accentColor.withOpacity(0.14), shape: BoxShape.circle),
                            child: Icon(Icons.info_outline, size: 15, color: metric.accentColor),
                          ),
                        )
                      : const SizedBox(key: ValueKey('noinfo'), width: 0, height: 0),
                ),
              ],
            ),
            if (!isCompact) const Divider(height: 22, color: AppColors.border) else const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: chartRowHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _phaseOrder.map((phaseKey) {
                        final entry = hasEnoughData ? _averages.where((a) => a.phaseKey == phaseKey).toList() : const <_PhaseAverage>[];
                        final has = entry.isNotEmpty;
                        final value = has ? entry.first.average : 0.0;
                        final heightFraction = maxValue > 0 && has ? (value / maxValue).clamp(0.08, 1.0) : 0.0;
                        final isHighest = has && phaseKey == highest?.phaseKey;
                        final isLowest = has && phaseKey == lowest?.phaseKey;
                        final barColor = isHighest
                            ? metric.accentColor
                            : isLowest
                                ? metric.accentColor.withOpacity(0.35)
                                : metric.accentColor.withOpacity(0.6);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (!isCompact)
                                  SizedBox(
                                    height: 13,
                                    child: has
                                        ? Text(value.toStringAsFixed(metric.decimals),
                                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
                                        : null,
                                  ),
                                const SizedBox(height: 4),
                                // Expanded + Align en vez de una altura animada
                                // fija: así la barra siempre cabe en el
                                // espacio restante del Column (evita overflow
                                // transitorio mientras chartRowHeight y
                                // barMaxHeight se animan en paralelo con
                                // curvas independientes).
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 320),
                                      curve: Curves.easeOutCubic,
                                      height: barMaxHeight * heightFraction,
                                      decoration: BoxDecoration(
                                        color: has ? barColor : AppColors.background,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isCompact) ...[
                                  const SizedBox(height: 6),
                                  Text(s.phaseAbbrev(phaseKey),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: chartRowHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (!isCompact) Text(s.statsPhaseAverageLabel, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 320),
                          style: TextStyle(
                            fontSize: valueSize,
                            fontWeight: FontWeight.w800,
                            color: hasEnoughData ? AppColors.textPrimary : AppColors.textMuted,
                          ),
                          child: Text(hasEnoughData ? fmt(overallAvg) : '—'),
                        ),
                        if (!isCompact && hasEnoughData) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: metric.accentColor, shape: BoxShape.circle)),
                              Expanded(child: Text(s.phaseName(highest!.phaseKey), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                              Text(fmt(highest.average), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: metric.accentColor.withOpacity(0.35), shape: BoxShape.circle)),
                              Expanded(child: Text(s.phaseName(lowest!.phaseKey), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                              Text(fmt(lowest.average), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ] else if (!isCompact) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.watch_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  s.statsRequiresWearableBadge,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isExpanded && hasEnoughData) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: metric.accentColor.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.watch_outlined, size: 13, color: metric.accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.statsRequiresWearableBadge,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: metric.accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
