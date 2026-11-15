import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/settings_service.dart' show AppThemeOption, themeById;
import '../theme/app_theme.dart';
import '../widgets/calendar_grid.dart' show CalendarPastel;
import '../widgets/uterus_phase_illustration.dart' show UterusPainter;

DateTime _parseKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Un ciclo pasado ya "cerrado" (tiene un ciclo siguiente que marca dónde
/// termina), listo para mostrarse en la lista de Historia: fecha de
/// inicio/fin del sangrado, duración total del ciclo hasta el siguiente
/// inicio, y si se sale del rango típico (irregular).
class _PastCycle {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int periodDays;
  final int cycleDays;
  final bool irregular;

  const _PastCycle({
    required this.periodStart,
    required this.periodEnd,
    required this.periodDays,
    required this.cycleDays,
    required this.irregular,
  });
}

/// Pestaña "Revisión": tarjetas resumen (duración media de periodo y de
/// ciclo) + lista de ciclos pasados con una barra visual periodo/ciclo,
/// al estilo de apps de referencia como Flo — a petición del usuario, que
/// mostró una captura de esa pantalla como modelo a seguir.
class ReviewScreen extends StatelessWidget {
  final Map<String, DayEntry> data;
  final String themeId;

  const ReviewScreen({super.key, required this.data, this.themeId = 'pink'});

  List<_PastCycle> _buildPastCycles(CyclePredictor predictor) {
    final cycles = predictor.getCycles();
    // Un "ciclo pasado" completo necesita un ciclo siguiente que marque
    // dónde termina (para calcular cycleDays) — el último grupo de la
    // lista es el ciclo actual/en curso y no tiene ese dato todavía, así
    // que se muestra en la lista pero sin duración de ciclo confiable si
    // es el único, o se excluye si ya se está registrando ahora mismo.
    final result = <_PastCycle>[];
    for (var i = 0; i < cycles.length - 1; i++) {
      final periodStart = _parseKey(cycles[i].first);
      final periodEnd = _parseKey(cycles[i].last);
      final nextStart = _parseKey(cycles[i + 1].first);
      final cycleDays = nextStart.difference(periodStart).inDays;
      // Mismo umbral clínico usado en CyclePredictor.isIrregular(): fuera
      // de 21-35 días se marca como irregular, para que la etiqueta de
      // esta lista coincida con el resto de la app.
      final irregular = cycleDays < 21 || cycleDays > 35;
      result.add(_PastCycle(
        periodStart: periodStart,
        periodEnd: periodEnd,
        periodDays: cycles[i].length,
        cycleDays: cycleDays,
        irregular: irregular,
      ));
    }
    // Más reciente primero, igual que en la referencia visual.
    return result.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(themeId);
    final predictor = CyclePredictor(data);
    final pastCycles = _buildPastCycles(predictor);
    final avgPeriod = predictor.getAvgPeriodLength();
    final avgCycle = predictor.getAvgCycleLength();
    final prediction = predictor.predict();
    final lastCycleDays = pastCycles.isNotEmpty ? pastCycles.first.cycleDays : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón de cerrar (✕): antes vivía DENTRO del ListView de la
            // rama "hay ciclos registrados", así que cuando todavía no
            // había ninguno (_buildEmptyState) esta pantalla se quedaba
            // sin ninguna forma de salir salvo el botón físico Atrás de
            // Android — bug reportado por la usuaria ("no hay manera de
            // volver atrás" dentro de Revisión). Se saca el botón fuera
            // del condicional para que esté siempre visible, haya o no
            // datos, y se usa el mismo ícono de cerrar que en Estadísticas
            // en vez de "← Volver".
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 22, color: Color(theme.primary)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ),
            ),
            Expanded(
              child: pastCycles.isEmpty
                  ? _buildEmptyState(s)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                  Text(s.reviewTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.reviewMyCycles,
                          style:
                              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (pastCycles.isNotEmpty)
                        Text(s.reviewBasedOnCycles,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _CyclePredictionCard(
                    s: s,
                    theme: theme,
                    prediction: prediction,
                    avgCycle: avgCycle,
                    isIrregular: predictor.isIrregular(),
                    lastCycleDays: lastCycleDays,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          value: '$avgPeriod',
                          unit: s.reviewPeriodDaysLabel,
                          label: s.reviewAvgPeriod,
                          background: Color(theme.primaryLight),
                          foreground: Color(theme.primaryDark),
                          icon: Icons.water_drop,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          value: '$avgCycle',
                          unit: s.reviewPeriodDaysLabel,
                          label: s.reviewAvgCycle,
                          background: CalendarPastel.fertileBg,
                          foreground: CalendarPastel.fertileFg,
                          icon: Icons.autorenew,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.reviewHistory,
                          style:
                              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (pastCycles.length > 1)
                        GestureDetector(
                          onTap: () => _showFullHistory(context, pastCycles, s, theme),
                          child: Text(s.reviewSeeAll,
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(theme.primary))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _CycleHistoryCarousel(cycles: pastCycles, s: s, theme: theme),
                  const SizedBox(height: 22),
                  _CycleStagesCard(
                    s: s,
                    theme: theme,
                    currentPhaseKey: predictor.currentPhaseKey(),
                    dayInCycle: predictor.currentDayInCycle(),
                    cycleLength: avgCycle,
                    periodLength: avgPeriod,
                  ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          s.reviewEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ),
      ),
    );
  }

  /// "Ver todos" de Historia: abre la lista vertical completa (el diseño
  /// original de _CycleHistoryRow, sin cambios) dentro de un bottom sheet,
  /// para no perder acceso al historial completo al convertir la vista
  /// principal en un carrusel que solo muestra unos pocos ciclos a la vez.
  void _showFullHistory(
    BuildContext context,
    List<_PastCycle> pastCycles,
    AppStrings s,
    AppThemeOption theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.reviewHistory,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: pastCycles.map((c) => _CycleHistoryRow(cycle: c, s: s, theme: theme)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta "Mis ciclos": predicción de próximo periodo + ventana fértil,
/// comparación del último ciclo con el promedio histórico, indicador de
/// regularidad y una nota educativa breve sobre cómo se calcula todo.
/// Reutiliza CyclePredictor.predict()/isIrregular() ya usados en el resto
/// de la app, así que la predicción siempre coincide con la del calendario.
class _CyclePredictionCard extends StatelessWidget {
  final AppStrings s;
  final AppThemeOption theme;
  final CyclePrediction prediction;
  final int avgCycle;
  final bool isIrregular;
  final int? lastCycleDays;

  const _CyclePredictionCard({
    required this.s,
    required this.theme,
    required this.prediction,
    required this.avgCycle,
    required this.isIrregular,
    required this.lastCycleDays,
  });

  String _formatDate(AppStrings s, DateTime d) => '${d.day} ${s.monthName(d.month)}';

  @override
  Widget build(BuildContext context) {
    final primary = Color(theme.primary);
    final hasNextPeriod = prediction.nextPeriodStart != null;
    final today = DateTime.now();
    final daysUntil = hasNextPeriod ? prediction.nextPeriodStart!.difference(DateTime(today.year, today.month, today.day)).inDays : null;

    final fertileStart = prediction.fertileRangeStart ??
        (prediction.ovulationDate != null ? prediction.ovulationDate!.subtract(const Duration(days: 5)) : null);
    final fertileEnd = prediction.fertileRangeEnd ??
        (prediction.ovulationDate != null ? prediction.ovulationDate!.add(const Duration(days: 1)) : null);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(s.reviewNextPeriodLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          if (hasNextPeriod)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(_formatDate(s, prediction.nextPeriodStart!),
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: primary)),
                const SizedBox(width: 6),
                Text(s.reviewInDays(daysUntil!.clamp(0, 999)),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            )
          else
            Text(s.reviewNoDataYet, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          if (fertileStart != null && fertileEnd != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CalendarPastel.fertileBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.egg_outlined, size: 16, color: CalendarPastel.fertileFg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.reviewFertileWindow(
                        '${_formatDate(s, fertileStart)}-${fertileEnd.day} ${s.monthName(fertileEnd.month)}',
                        prediction.ovulationDate != null ? _formatDate(s, prediction.ovulationDate!) : '—',
                      ),
                      style: TextStyle(fontSize: 12, color: CalendarPastel.fertileFg),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

}

/// Carrusel horizontal de Historia: en vez de la lista vertical completa
/// (que ahora vive detrás de "Ver todos"), muestra 2 ciclos y pico a la vez
/// con scroll libre y un indicador de puntos debajo. Reutiliza el mismo
/// _CycleHistoryRow para cada tarjeta, envuelto en un ancho fijo.
class _CycleHistoryCarousel extends StatefulWidget {
  final List<_PastCycle> cycles;
  final AppStrings s;
  final AppThemeOption theme;

  const _CycleHistoryCarousel({required this.cycles, required this.s, required this.theme});

  @override
  State<_CycleHistoryCarousel> createState() => _CycleHistoryCarouselState();
}

class _CycleHistoryCarouselState extends State<_CycleHistoryCarousel> {
  final ScrollController _scrollController = ScrollController();
  int _page = 0;

  static const double _cardWidth = 190;
  static const double _cardGap = 12;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final page = (_scrollController.offset / (_cardWidth + _cardGap)).round().clamp(0, widget.cycles.length - 1);
    if (page != _page) setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cycles.isEmpty) return const SizedBox.shrink();
    // Máximo 5 puntos indicadores en pantalla (el resto del historial
    // completo queda accesible vía "Ver todos") para no saturar la vista
    // principal con ciclos muy antiguos.
    final visibleCount = widget.cycles.length > 5 ? 5 : widget.cycles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _onScroll();
            return false;
          },
          child: SizedBox(
            height: 128,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: visibleCount,
              separatorBuilder: (_, __) => const SizedBox(width: _cardGap),
              itemBuilder: (context, index) {
                final cycle = widget.cycles[index];
                return SizedBox(
                  width: _cardWidth,
                  child: _CycleHistoryRow(cycle: cycle, s: widget.s, theme: widget.theme, compact: true),
                );
              },
            ),
          ),
        ),
        if (visibleCount > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(visibleCount, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: active ? 16 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: active ? Color(widget.theme.primary) : CalendarPastel.predictedBg,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _SummaryCard({
    required this.value,
    required this.unit,
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(icon, size: 14, color: foreground),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: foreground),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: foreground.withOpacity(0.85))),
        ],
      ),
    );
  }
}

class _CycleHistoryRow extends StatelessWidget {
  final _PastCycle cycle;
  final AppStrings s;
  final AppThemeOption theme;
  // Versión reducida usada dentro del carrusel horizontal de Historia
  // (ancho fijo ~190px): recorta paddings/márgenes verticales y el
  // tamaño de fuente de la fecha para que la tarjeta quepa completa sin
  // desbordar ni truncar la bandera "Irregular".
  final bool compact;

  const _CycleHistoryRow({required this.cycle, required this.s, required this.theme, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final sameMonth = cycle.periodStart.month == cycle.periodEnd.month;
    final dateRange = sameMonth
        ? '${cycle.periodStart.day}-${cycle.periodEnd.day} ${s.monthName(cycle.periodEnd.month)}'
        : '${s.dayLabel(cycle.periodStart.day, cycle.periodStart.month)} - ${s.dayLabel(cycle.periodEnd.day, cycle.periodEnd.month)}';

    // Proporciones de la barra, replicando la referencia con precisión:
    // un riel de fondo rosa muy pálido de un solo tono (no degradado), con
    // 2 piezas separadas encima — el bloque rosa fuerte de los días de
    // sangrado, y el óvalo amarillo/dorado de la ovulación — dejando un
    // hueco blanco visible entre ambas, tal como en la referencia (donde
    // NO se funden entre sí).
    final periodFraction = cycle.cycleDays > 0 ? (cycle.periodDays / cycle.cycleDays).clamp(0.12, 0.45) : 0.3;
    final ovulationFraction = cycle.cycleDays > 14 ? (1 - (14 / cycle.cycleDays)).clamp(periodFraction + 0.15, 0.85) : 0.65;

    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(top: 16, bottom: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: compact
                ? const EdgeInsets.fromLTRB(12, 12, 12, 14)
                : const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateRange,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: compact ? 12.5 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                SizedBox(height: compact ? 10 : 12),
                SizedBox(
                  height: 16,
                  // El LayoutBuilder envuelve el Stack completo (no solo el
                  // punto de ovulación) para que el Positioned que marca la
                  // ovulación quede como hijo DIRECTO del Stack — Positioned
                  // exige eso; anidado dentro de un LayoutBuilder que a su
                  // vez fuera hijo del Stack, Flutter lanzaba "Incorrect use
                  // of ParentDataWidget" porque el ParentData de Stack no
                  // llegaba al RenderObject a través del LayoutBuilder
                  // intermedio.
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fullWidth = constraints.maxWidth;
                      // Ancho del bloque rosa, con un pequeño margen antes
                      // del hueco blanco para que nunca toque el óvalo
                      // amarillo aunque el periodo sea muy largo.
                      final pinkWidth = (fullWidth * periodFraction).clamp(26.0, fullWidth * 0.5);
                      // Óvalo amarillo: ancho fijo pequeño (no se estira
                      // con la duración del ciclo, igual que en la
                      // referencia), centrado sobre la fracción de
                      // ovulación calculada.
                      const yellowWidth = 34.0;
                      final yellowLeft =
                          (fullWidth * ovulationFraction - yellowWidth / 2).clamp(pinkWidth + 10, fullWidth - yellowWidth);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Riel de fondo: un solo tono rosa muy pálido de
                          // punta a punta, sin degradado — el resto del
                          // ciclo sin marcar.
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: CalendarPastel.predictedBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          // Bloque rosa fuerte: días de sangrado, pegado al
                          // extremo izquierdo, con esquinas redondeadas
                          // propias (no se funde con el riel de fondo).
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: pinkWidth,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Color(theme.primary),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          // Óvalo amarillo/dorado de la ovulación, separado
                          // del bloque rosa por un hueco blanco visible del
                          // propio riel de fondo (no se tocan).
                          Positioned(
                            left: yellowLeft,
                            top: 0,
                            child: Container(
                              width: yellowWidth,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD43B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          Positioned(
                            left: yellowLeft + yellowWidth / 2 - 7,
                            top: 1,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA94D),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Bandera "Irregular" en la esquina superior derecha, con la
          // muesca diagonal característica de la referencia (se logra con
          // un ClipPath que corta la esquina inferior izquierda en punta).
          if (cycle.irregular)
            Positioned(
              top: 0,
              right: 0,
              child: ClipPath(
                clipper: _FlagClipper(),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 14, 16),
                  decoration: BoxDecoration(color: Color(theme.primary)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(s.reviewIrregular,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Recorta la esquina inferior izquierda en diagonal, dando la forma de
/// "bandera" con muesca característica de la etiqueta Irregular en la
/// referencia visual (en vez de un simple rectángulo con esquinas
/// redondeadas).
class _FlagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notch = 10.0;
    const radius = 14.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height)
      ..lineTo(notch, size.height)
      ..lineTo(0, size.height - notch)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Datos fijos de cada fase: en qué día del ciclo empieza y termina
/// (aproximado, según duración media de periodo/ciclo de la usuaria), para
/// poder calcular "cuántos días dura" y "cuántos le quedan" en el diálogo
/// de detalle. Los umbrales replican exactamente los de
/// CyclePredictor.currentPhaseKey() para que la fase resaltada siempre
/// coincida con la que muestra el resto de la app.
class _PhaseRange {
  final int startDay; // inclusive, 0-based
  final int endDay; // exclusive
  const _PhaseRange(this.startDay, this.endDay);
  int get length => endDay - startDay;
}

/// Tarjeta "Etapas del ciclo menstrual": 4 ilustraciones tipo útero/ovarios
/// (una por fase, dibujadas con CustomPaint a partir de la foto de
/// referencia que compartió el usuario) en una cuadrícula 2x2, con la fase
/// actual de la usuaria ampliada y resaltada. Al tocar cualquiera se abre
/// una hoja con la descripción, cuántos días dura típicamente esa fase y,
/// si es la fase activa, cuántos días le quedan.
class _CycleStagesCard extends StatelessWidget {
  final AppStrings s;
  final AppThemeOption theme;
  final String? currentPhaseKey;
  final int? dayInCycle;
  final int cycleLength;
  final int periodLength;

  const _CycleStagesCard({
    required this.s,
    required this.theme,
    required this.currentPhaseKey,
    required this.dayInCycle,
    required this.cycleLength,
    required this.periodLength,
  });

  /// Mismos umbrales que CyclePredictor.currentPhaseKey(), expresados como
  /// rangos [startDay, endDay) para poder calcular duración y días
  /// restantes de cada fase.
  Map<String, _PhaseRange> _phaseRanges() {
    final ovulationDay = cycleLength - 14;
    final follicularStart = periodLength;
    final follicularEnd = math.max(follicularStart, ovulationDay - 2);
    final ovulationEnd = math.max(follicularEnd, ovulationDay + 2);
    final lutealEnd = math.max(ovulationEnd, cycleLength);
    return {
      'menstrual': _PhaseRange(0, periodLength),
      'folicular': _PhaseRange(follicularStart, follicularEnd),
      'ovulacion': _PhaseRange(follicularEnd, ovulationEnd),
      'lutea': _PhaseRange(ovulationEnd, lutealEnd),
    };
  }

  void _openDetail(BuildContext context, String phaseKey) {
    final ranges = _phaseRanges();
    final range = ranges[phaseKey];
    final isActive = currentPhaseKey == phaseKey;
    int? daysLeft;
    if (isActive && dayInCycle != null && range != null) {
      daysLeft = (range.endDay - dayInCycle!).clamp(0, range.length);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _PhaseDetailSheet(
        s: s,
        theme: theme,
        phaseKey: phaseKey,
        durationDays: range?.length ?? 0,
        isActive: isActive,
        daysLeft: daysLeft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(theme.primary);
    const order = ['menstrual', 'folicular', 'ovulacion', 'lutea'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.reviewStagesTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(s.reviewStagesSubtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          // Bloque "Etapa actual" destacado arriba de la cuadrícula, con
          // fondo tintado del color de la app — a petición del usuario de
          // que el estado actual se vea primero y con más peso visual, en
          // vez del texto discreto en una sola línea que había antes.
          if (currentPhaseKey != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withOpacity(0.25), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: '${s.reviewStagesCurrentPrefix} ',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          TextSpan(
                            text: s.phaseName(currentPhaseKey!),
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(s.reviewStagesNoData,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
            ),
          const SizedBox(height: 18),
          // Cuadrícula 2x2 con las 4 fases — la activa se dibuja más
          // grande (flex 3 contra 2 de las demás) para que resalte de
          // inmediato, tal como pidió el usuario.
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _phaseTile(context, order[0], primary),
                  const SizedBox(width: 10),
                  _phaseTile(context, order[1], primary),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _phaseTile(context, order[2], primary),
                  const SizedBox(width: 10),
                  _phaseTile(context, order[3], primary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _phaseTile(BuildContext context, String phaseKey, Color primary) {
    final active = currentPhaseKey == phaseKey;
    return Expanded(
      flex: active ? 3 : 2,
      child: _PhaseTile(
        s: s,
        primary: primary,
        phaseKey: phaseKey,
        active: active,
        onTap: () => _openDetail(context, phaseKey),
      ),
    );
  }
}

/// Una celda de la cuadrícula: ilustración de la fase + nombre debajo, que
/// se agranda y resalta con el color de app cuando es la fase activa, y
/// que además reacciona al toque con un pequeño efecto de "pulso" (se
/// encoge y vuelve a su tamaño) antes de abrir el detalle — a petición del
/// usuario de que hubiera "un efecto del dibujo" al tocarlo.
class _PhaseTile extends StatefulWidget {
  final AppStrings s;
  final Color primary;
  final String phaseKey;
  final bool active;
  final VoidCallback onTap;

  const _PhaseTile({
    required this.s,
    required this.primary,
    required this.phaseKey,
    required this.active,
    required this.onTap,
  });

  @override
  State<_PhaseTile> createState() => _PhaseTileState();
}

class _PhaseTileState extends State<_PhaseTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    lowerBound: 0.0,
    upperBound: 1.0,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.06).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  String get _name {
    switch (widget.phaseKey) {
      case 'menstrual':
        return widget.s.phaseNameMenstrual;
      case 'folicular':
        return widget.s.phaseNameFollicular;
      case 'ovulacion':
        return widget.s.phaseNameOvulation;
      default:
        return widget.s.phaseNameLuteal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final primary = widget.primary;
    final illustrationSize = active ? 92.0 : 68.0;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: active ? 16 : 10, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? primary.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? primary.withOpacity(0.5) : AppColors.border, width: active ? 1.6 : 1),
          boxShadow: active
              ? [BoxShadow(color: primary.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scale,
              builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: illustrationSize,
                height: illustrationSize,
                child: CustomPaint(painter: UterusPainter(phaseKey: widget.phaseKey, primary: primary, active: active)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: active ? 12.5 : 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? primary : AppColors.textMuted,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja modal de detalle al tocar una fase: nombre, descripción breve,
/// cuántos días dura típicamente, una explicación de qué está pasando en
/// el cuerpo y, si es la fase actual de la usuaria, cuántos días le
/// quedan para pasar a la siguiente. Se anima al abrirse: la ilustración
/// grande entra con fade + escala (efecto "pop"), y el resto del
/// contenido con un fade + deslizamiento sutil hacia arriba — a petición
/// del usuario de que hubiera "efecto del dibujo y efecto de explicación"
/// al dar click.
class _PhaseDetailSheet extends StatefulWidget {
  final AppStrings s;
  final AppThemeOption theme;
  final String phaseKey;
  final int durationDays;
  final bool isActive;
  final int? daysLeft;

  const _PhaseDetailSheet({
    required this.s,
    required this.theme,
    required this.phaseKey,
    required this.durationDays,
    required this.isActive,
    required this.daysLeft,
  });

  @override
  State<_PhaseDetailSheet> createState() => _PhaseDetailSheetState();
}

class _PhaseDetailSheetState extends State<_PhaseDetailSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();

  late final Animation<double> _iconScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
  );
  late final Animation<double> _iconFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _contentFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
  );
  late final Animation<Offset> _contentSlide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.85, curve: Curves.easeOut)));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name {
    switch (widget.phaseKey) {
      case 'menstrual':
        return widget.s.phaseNameMenstrual;
      case 'folicular':
        return widget.s.phaseNameFollicular;
      case 'ovulacion':
        return widget.s.phaseNameOvulation;
      default:
        return widget.s.phaseNameLuteal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final phaseKey = widget.phaseKey;
    final isActive = widget.isActive;
    final primary = Color(widget.theme.primary);
    final tips = s.phaseTips(phaseKey);
    final happening = s.phaseHappening(phaseKey);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Row(
              children: [
                FadeTransition(
                  opacity: _iconFade,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(6),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: CustomPaint(painter: UterusPainter(phaseKey: phaseKey, primary: primary, active: true)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(20)),
                          child: Text(s.reviewStagesCurrentPrefix,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isActive)
                      // Fase que la usuaria todavía no ha alcanzado (o ya
                      // pasó) en su ciclo actual: no tiene sentido
                      // mostrarle duración ni consejos como si fuera su
                      // situación de hoy, así que solo se le avisa que no
                      // está en esa etapa — a petición explícita del
                      // usuario.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.reviewStagesNotThere,
                                style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _DetailStat(
                              icon: Icons.calendar_month,
                              label: s.reviewStagesDurationLabel,
                              value: s.reviewStagesDaysCount(widget.durationDays),
                              color: primary,
                            ),
                          ),
                          if (widget.daysLeft != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DetailStat(
                                icon: Icons.hourglass_bottom,
                                label: s.reviewStagesDaysLeftLabel,
                                value: s.reviewStagesDaysCount(widget.daysLeft!),
                                color: primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                    // Sección "Qué está pasando en tu cuerpo": explicación
                    // biológica breve del proceso de esa fase, visible
                    // siempre (sea o no la fase activa) para que la
                    // ilustración tenga contexto educativo aunque la
                    // usuaria esté explorando otra etapa.
                    Row(
                      children: [
                        Icon(Icons.favorite_border, size: 14, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          s.reviewStagesWhatsHappening,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(happening, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.55)),
                    if (isActive && tips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(tips.first, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
