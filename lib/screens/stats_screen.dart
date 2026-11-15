import 'package:flutter/material.dart';
import 'package:health/health.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/pdf_report_service.dart';
import '../services/settings_service.dart';
import '../services/stats_calculator.dart';
import '../theme/app_theme.dart';
import '../widgets/phase_health_card.dart';
import '../widgets/temp_chart.dart';
import '../widgets/uterus_phase_illustration.dart';

DateTime _parseKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Pantalla de estadísticas del ciclo: métricas básicas, insights
/// automáticos, indicador de cambio térmico, comparación por año y
/// gráfica de temperatura/síntomas. Equivalente a "viewStats" del
/// prototipo web.
class StatsScreen extends StatefulWidget {
  final Map<String, DayEntry> data;

  // Id del tema de color elegido en Configuración — usado en la tarjeta
  // "Consejo de hoy" (fondo antes fijo en AppColors.primaryLight).
  final String themeId;

  // "Mi objetivo"/embarazo activo: el "Consejo de hoy" (tarjeta de fase
  // actual del ciclo) parte de contar días desde el último periodo
  // registrado, cálculo que no tiene sentido una vez hay un embarazo en
  // curso (sigue "avanzando" fases sobre un ciclo que ya no existe) — se
  // oculta solo esa tarjeta en ese caso; el resto de Estadísticas (ciclos
  // registrados, comparativas de salud por fase, etc.) sigue siendo datos
  // históricos válidos y se mantiene.
  final bool inPregnancyMode;

  const StatsScreen({super.key, required this.data, this.themeId = 'pink', this.inPregnancyMode = false});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _exportingPdf = false;
  double? _heightCm;
  int _openEducationIndex = -1;
  bool _wellnessEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHeight();
    _loadWellnessPref();
  }

  Future<void> _loadHeight() async {
    final value = await _settingsService.loadHeightCm();
    if (mounted) setState(() => _heightCm = value);
  }

  Future<void> _loadWellnessPref() async {
    final value = await _settingsService.loadWellnessEnabled();
    if (mounted) setState(() => _wellnessEnabled = value);
  }

  /// Último peso registrado en el diario (fecha más reciente con dato).
  double? _latestWeight() {
    final keys = widget.data.keys.toList()..sort();
    for (final key in keys.reversed) {
      final w = widget.data[key]?.weight;
      if (w != null) return w;
    }
    return null;
  }

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final predictor = CyclePredictor(widget.data);
      final s = AppStrings.of(context);
      await PdfReportService().exportAndShare(predictor, s);
    } catch (_) {
      if (mounted) {
        final s = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.exportPdfError)),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void _openChartZoom(AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.tempAndSymptomsTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TempChart(data: widget.data, big: true),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(s.chartTempBasalLegend, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(width: 12),
                Text(s.chartPeriodLegend, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(widget.themeId);
    final predictor = CyclePredictor(widget.data);
    final calc = StatsCalculator(widget.data);
    final cycles = predictor.getCycles();
    final cycleLens = calc.cycleLengthDiffs();

    final avgCycle = cycleLens.isNotEmpty
        ? (cycleLens.reduce((a, b) => a + b) / cycleLens.length).round()
        : null;
    final minCycle = cycleLens.isNotEmpty ? cycleLens.reduce((a, b) => a < b ? a : b) : null;
    final maxCycle = cycleLens.isNotEmpty ? cycleLens.reduce((a, b) => a > b ? a : b) : null;
    final avgPeriod = predictor.getAvgPeriodLength();

    final insights = calc.computeInsights();
    final yearRows = calc.computeYearComparison();

    // Esta pantalla se abre con Navigator.push directo (sin Scaffold
    // propio, ver comentario de la clase) — el InkWell de las filas
    // desplegables de "Entiende tu cuerpo" (_buildEducationCard) necesita
    // un Material ancestro para pintar el efecto de tap, y al no haber
    // ningún Scaffold entre esta pantalla y el Navigator no lo encontraba
    // ("No Material widget found"), lo que rompía esa tarjeta en pantalla
    // roja en cuanto había algún ítem educativo que mostrar. Este
    // `Material` transparente no cambia nada visualmente (sin color propio
    // ni elevación), solo resuelve ese ancestro que faltaba.
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón de cerrar (✕): antes era un TextButton "Volver" (flecha +
          // texto) que no funcionaba bien porque esta pantalla no tenía
          // SafeArea — en varios teléfonos el header quedaba debajo de la
          // cámara/notch, tapando el botón y dejando la pantalla sin forma
          // de salir salvo el botón físico Atrás de Android (reportado por
          // la usuaria: "no me dejó retroceder"). Se envuelve todo el
          // contenido en SafeArea para que nada quede bajo el notch, y se
          // cambia el botón por un ícono de cerrar suelto, con un área de
          // toque de 44x44 fácil de acertar.
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, size: 22, color: Color(theme.primary)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              splashRadius: 22,
            ),
          ),
          const SizedBox(height: 4),
          if (_wellnessEnabled) ...[
            _buildPhaseHealthCards(s, predictor),
            const SizedBox(height: 20),
          ],
          Text(s.statsTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            // Bajado de 1.7 a 1.5 para dar más alto a la tarjeta: el
            // número ahora es más grande (24px) y necesita algo más de
            // espacio vertical para no quedar apretado.
            childAspectRatio: 1.5,
            children: [
              _StatCard(num: '${cycles.length}', label: s.statCyclesLogged),
              _StatCard(num: avgCycle?.toString() ?? '—', label: s.statAvgDuration),
              _StatCard(num: '$avgPeriod', label: s.statPeriodDuration),
              _StatCard(
                num: '${minCycle ?? '—'} – ${maxCycle ?? '—'}',
                label: s.statCycleRange,
              ),
            ],
          ),
          if (_wellnessEnabled) ...[
            const SizedBox(height: 14),
            _buildBmiCard(s),
          ],
          if (cycleLens.length >= 2 && maxCycle != null && minCycle != null && (maxCycle - minCycle) > 8) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(12)),
              child: Text(
                s.cycleVariationWarning(minCycle, maxCycle),
                style: const TextStyle(fontSize: 11, color: Color(0xFF7A5C00)),
              ),
            ),
          ],
          if (!widget.inPregnancyMode) ...[
            const SizedBox(height: 14),
            _buildPhaseTipCard(s, predictor),
          ],
          const SizedBox(height: 14),
          _buildEducationCard(s, avgCycle: avgCycle, minCycle: minCycle, maxCycle: maxCycle),
          if (_wellnessEnabled) ...[
            const SizedBox(height: 14),
            _buildThermalShiftCard(s, calc, cycles),
          ],
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...insights.map((e) => _InsightCard(symptom: e.key, percent: e.value)),
          ],
          if (yearRows.length >= 2) ...[
            const SizedBox(height: 18),
            Text(s.yearComparisonTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _buildYearCompare(s, yearRows),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _exportingPdf ? null : _exportPdf,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.primary, style: BorderStyle.solid),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 46),
            ),
            child: Text(
              _exportingPdf ? s.exportPdfGenerating : s.exportPdfButton,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (_wellnessEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.tempAndSymptomsTitle,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: () => _openChartZoom(s),
                        icon: const Icon(Icons.search, size: 16, color: AppColors.primary),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.background,
                          minimumSize: const Size(28, 28),
                        ),
                      ),
                    ],
                  ),
                  TempChart(data: widget.data),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(s.chartTempBasalLegend, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(width: 12),
                      Text(s.chartPeriodLegend, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildBmiCard(AppStrings s) {
    final weight = _latestWeight();
    if (weight == null || _heightCm == null || _heightCm! <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          weight == null ? s.bmiRegisterWeightHint : s.bmiAddHeightHint,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
        ),
      );
    }

    final heightM = _heightCm! / 100;
    final bmi = weight / (heightM * heightM);

    String category;
    Color color;
    if (bmi < 18.5) {
      category = s.bmiCategoryUnderweight;
      color = const Color(0xFF1C7ED6);
    } else if (bmi < 25) {
      category = s.bmiCategoryNormal;
      color = const Color(0xFF2F9E44);
    } else if (bmi < 30) {
      category = s.bmiCategoryOverweight;
      color = const Color(0xFFF59F00);
    } else {
      category = s.bmiCategoryObesity;
      color = const Color(0xFFE03131);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.bmiTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  s.bmiWithValues(weight.toStringAsFixed(1), _heightCm!.toStringAsFixed(0)),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(bmi.toStringAsFixed(1), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              Text(category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  /// Consejos y explicaciones educativas para ayudar a entender las
  /// propias cifras del ciclo, basados en información pública del
  /// American College of Obstetricians and Gynecologists (ACOG) y Mayo
  /// Clinic. Es contenido general, no un diagnóstico ni sustituto de
  /// consulta médica.
  /// Orden fijo de las 4 fases, reutilizado tanto para la fila de
  /// ilustraciones como para los 4 ítems desplegables que le siguen — el
  /// mismo orden cronológico que usa el resto de la app (Revisión,
  /// CyclePredictor, PhaseHealthCardsGroup).
  static const _phaseOrder = ['menstrual', 'folicular', 'ovulacion', 'lutea'];

  List<_EducationItem> _educationItems(AppStrings s, {int? avgCycle, int? minCycle, int? maxCycle}) {
    final items = <_EducationItem>[
      // Un ítem por fase, con la misma ilustración anatómica y el mismo
      // texto ya usados y traducidos a los 9 idiomas de la app en la
      // tarjeta "Etapas del ciclo menstrual" de Revisión (s.phaseHappening)
      // — a petición de la usuaria de que "Entiende tu cuerpo" tuviera un
      // esquema, no solo texto suelto.
      for (final phaseKey in _phaseOrder)
        _EducationItem(
          emoji: '',
          phaseKey: phaseKey,
          title: s.phaseName(phaseKey),
          body: s.phaseHappening(phaseKey),
        ),
      _EducationItem(
        emoji: '📅',
        title: s.eduNormalCycleTitle,
        body: s.eduNormalCycleBody,
      ),
      _EducationItem(
        emoji: '🌡️',
        title: s.eduBasalTempTitle,
        body: s.eduBasalTempBody,
      ),
      _EducationItem(
        emoji: '🩺',
        title: s.eduWhenToSeeDoctorTitle,
        body: s.eduWhenToSeeDoctorBody,
      ),
      _EducationItem(
        emoji: '🔥',
        title: s.eduLutealPhaseTitle,
        body: s.eduLutealPhaseBody,
      ),
    ];

    if (avgCycle != null && minCycle != null && maxCycle != null && (maxCycle - minCycle) > 8) {
      items.insert(
        0,
        _EducationItem(
          emoji: '📊',
          title: s.eduVariationTitle,
          body: s.eduVariationBody(minCycle, maxCycle),
        ),
      );
    }

    return items;
  }

  /// Tarjeta de "consejo de hoy": muestra un tip contextual según la fase
  /// actual del ciclo (calculada con CyclePredictor.currentPhaseKey), con
  /// el mismo criterio de rotación determinística por día que ya se usa
  /// en la tarjeta de fase de la pantalla principal — así el contenido
  /// educativo de Estadísticas no queda estático, sino que se adapta a
  /// dónde está la persona en su ciclo hoy.
  Widget _buildPhaseTipCard(AppStrings s, CyclePredictor predictor) {
    final phaseKey = predictor.currentPhaseKey();
    if (phaseKey == null) return const SizedBox.shrink();

    final tips = s.phaseTips(phaseKey);
    if (tips.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final dayOfYear = int.parse(
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
    final tipText = tips[dayOfYear % tips.length];
    final phaseName = s.phaseName(phaseKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color(themeById(widget.themeId).primaryLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.statsPhaseTipTitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                s.statsPhaseTipPhaseLabel(phaseName),
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(tipText, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildEducationCard(AppStrings s, {int? avgCycle, int? minCycle, int? maxCycle}) {
    final items = _educationItems(s, avgCycle: avgCycle, minCycle: minCycle, maxCycle: maxCycle);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.educationCardTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            s.educationCardSubtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          // Esquema de las 4 fases del ciclo (ilustración anatómica +
          // nombre), a modo de resumen visual antes del texto desplegable
          // de abajo — mismo dibujo que ya usa la tarjeta "Etapas del
          // ciclo menstrual" de Revisión (ver UterusPhaseIllustration),
          // para que "Entiende tu cuerpo" no sea solo texto.
          Row(
            children: [
              for (final phaseKey in _phaseOrder)
                Expanded(
                  child: Column(
                    children: [
                      UterusPhaseIllustration(phaseKey: phaseKey, primary: AppColors.primary, size: 44),
                      const SizedBox(height: 4),
                      Text(
                        s.phaseName(phaseKey),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 4),
          ...List.generate(items.length, (i) {
            final item = items[i];
            final open = _openEducationIndex == i;
            return Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _openEducationIndex = open ? -1 : i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        item.phaseKey != null
                            ? UterusPhaseIllustration(phaseKey: item.phaseKey!, primary: AppColors.primary, size: 22)
                            : Text(item.emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                        Icon(
                          open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(item.body, style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.45)),
                  ),
                  secondChild: const SizedBox(width: double.infinity, height: 0),
                ),
                if (i < items.length - 1) const Divider(height: 1, color: AppColors.border),
              ],
            );
          }),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Text(
              s.educationCardFooter,
              style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalShiftCard(AppStrings s, StatsCalculator calc, List<List<String>> cycles) {
    if (cycles.isEmpty) return const SizedBox.shrink();

    final entries = calc.currentCycleTemps();
    String body;
    if (entries.length < 9) {
      body = s.thermalShiftTrackMore(entries.length);
    } else {
      final shift = StatsCalculator.findThermalShift(entries);
      final shiftDate = shift != null ? _parseKey(shift.dateKey) : null;
      body = shiftDate != null
          ? s.thermalShiftConfirmed(s.dayLabel(shiftDate.day, shiftDate.month))
          : s.thermalShiftNotDetected;
    }
    final title = entries.length < 9
        ? s.thermalShiftTitle
        : (StatsCalculator.findThermalShift(entries) != null ? s.thermalShiftDetectedTitle : s.thermalShiftTitle);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ovulation)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Text(
              s.thermalShiftDisclaimer,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// 3 tarjetas que comparan una métrica de salud (variabilidad de la
  /// frecuencia cardíaca, frecuencia cardíaca en reposo, desviación de
  /// temperatura) entre las 4 fases del ciclo, con datos reales
  /// sincronizados desde Apple Salud/Health Connect — a petición del
  /// usuario, que compartió una app de referencia con este mismo diseño.
  /// Cada tarjeta se auto-oculta si no hay suficientes datos (lo resuelve
  /// PhaseHealthCard internamente), así que este método simplemente las
  /// apila; si ninguna tiene datos, el bloque completo colapsa a un
  /// tamaño mínimo sin dejar huecos vacíos.
  Widget _buildPhaseHealthCards(AppStrings s, CyclePredictor predictor) {
    return PhaseHealthCardsGroup(
      predictor: predictor,
      highestLabelBuilder: s.statsHighestInPhase,
      lowestLabelBuilder: s.statsLowestInPhase,
      metrics: [
        PhaseHealthMetric(
          healthType: HealthDataType.HEART_RATE_VARIABILITY_SDNN,
          title: s.statsHrvTitle,
          unit: 'ms',
          accentColor: const Color(0xFF9C6ADE),
          icon: Icons.monitor_heart_outlined,
          decimals: 0,
          infoExplanationBuilder: (s) => s.statsHrvInfoExplanation,
        ),
        PhaseHealthMetric(
          healthType: HealthDataType.RESTING_HEART_RATE,
          title: s.statsRestingHrTitle,
          unit: 'bpm',
          accentColor: const Color(0xFFE8607A),
          icon: Icons.favorite_border,
          decimals: 0,
          infoExplanationBuilder: (s) => s.statsRestingHrInfoExplanation,
        ),
        PhaseHealthMetric(
          healthType: HealthDataType.BODY_TEMPERATURE,
          title: s.statsTempDeviationTitle,
          unit: '°C',
          accentColor: const Color(0xFF20A39E),
          icon: Icons.thermostat_outlined,
          decimals: 2,
          showAsDeviation: true,
          infoExplanationBuilder: (s) => s.statsTempDeviationInfoExplanation,
        ),
      ],
    );
  }

  Widget _buildYearCompare(AppStrings s, List<YearComparisonRow> rows) {
    final maxAvg = rows.map((r) => r.avg).reduce((a, b) => a > b ? a : b);
    return Column(
      children: rows.map((r) {
        final fraction = maxAvg > 0 ? r.avg / maxAvg : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text('${r.year}', style: const TextStyle(fontSize: 12))),
              Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.ovulation, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              ),
              Text(s.yearDays(r.avg), style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Un consejo/explicación educativa dentro de la tarjeta "Entiende tu
/// cuerpo" en Estadísticas.
class _EducationItem {
  final String emoji;
  final String title;
  final String body;

  /// Cuando no es null ('menstrual' | 'folicular' | 'ovulacion' | 'lutea'),
  /// la fila de este ítem muestra la ilustración anatómica de esa fase
  /// (ver UterusPhaseIllustration) en vez del [emoji] — usado en los 4
  /// ítems de "¿Qué pasa en cada fase?" para que el esquema del útero
  /// acompañe también al texto expandido, no solo al resumen de arriba.
  final String? phaseKey;

  const _EducationItem({required this.emoji, required this.title, required this.body, this.phaseKey});
}

class _StatCard extends StatelessWidget {
  final String num;
  final String label;

  const _StatCard({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(num, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String symptom;
  final int percent;

  const _InsightCard({required this.symptom, required this.percent});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final emoji = kSymptomEmoji[symptom] ?? '';
    final label = s.symptomLabelFor(symptom);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '$emoji ${s.insightPrefix}'),
                  TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: s.insightSuffix(percent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
