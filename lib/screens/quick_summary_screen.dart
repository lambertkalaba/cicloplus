import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/settings_service.dart' show AppThemeOption, PregnancySettings, themeById;
import '../theme/app_theme.dart';
import 'ovulation_test_screen.dart';
import 'pregnancy_tracking_screen.dart';
import 'stats_screen.dart';

/// Pantalla de resumen (info + evaluación/predicción) que antecede a los
/// 4 accesos del grid de "Yo" que antes navegaban directo a una pantalla
/// completa ya existente (Calendario/PregnancyTrackingScreen, StatsScreen,
/// OvulationTestScreen). Mismo patrón visual que `FieldDetailScreen`
/// (barra superior con píldora, tarjeta de valor grande, tarjeta de
/// "Evaluación"), pero aquí la píldora de la barra superior no abre un
/// editor: lleva a la pantalla completa correspondiente ("Ver calendario"/
/// "Ver estadísticas"/"Ver test").
///
/// `summaryKey` es uno de: 'periodCycle' | 'symptoms' | 'ovulationTest' |
/// 'fertility'.
class QuickSummaryScreen extends StatelessWidget {
  final String summaryKey;
  final String themeId;
  final Map<String, DayEntry> data;
  final bool irregularCycleMode;

  // Duración de ciclo/periodo autoinformadas en el cuestionario de
  // "Intentar concebir" — respaldo para CyclePredictor mientras no hay
  // suficientes datos reales (ver conceive_intake_sheet.dart).
  final int? selfReportedCycleLen;
  final int? selfReportedPeriodLen;
  final PregnancySettings pregnancy;

  // Reutilizados tal cual desde MeScreen para no duplicar la lógica de
  // navegación condicional (embarazo activo vs. calendario normal) ni el
  // cambio de pestaña del BottomNavigationBar.
  final ValueChanged<int> onNavigateToTab;

  const QuickSummaryScreen({
    super.key,
    required this.summaryKey,
    required this.themeId,
    required this.data,
    this.irregularCycleMode = false,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
    required this.pregnancy,
    required this.onNavigateToTab,
  });

  AppThemeOption get _theme => themeById(themeId);

  CyclePredictor get _predictor => CyclePredictor(
        data,
        forceIrregular: irregularCycleMode,
        selfReportedCycleLen: selfReportedCycleLen,
        selfReportedPeriodLen: selfReportedPeriodLen,
      );

  String _title(AppStrings s) {
    switch (summaryKey) {
      case 'periodCycle':
        return s.mePeriodAndCycle;
      case 'symptoms':
        return s.meSymptomsAndPredictions;
      case 'ovulationTest':
        return s.meOvulationTest;
      case 'fertility':
        return s.meFertility;
      default:
        return '';
    }
  }

  IconData _icon() {
    switch (summaryKey) {
      case 'periodCycle':
        return Icons.calendar_month;
      case 'symptoms':
        return Icons.insights;
      case 'ovulationTest':
        return Icons.science_outlined;
      case 'fertility':
        return Icons.spa_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _buttonLabel(AppStrings s) {
    switch (summaryKey) {
      case 'periodCycle':
        return s.quickSummaryViewCalendarButton;
      case 'symptoms':
      case 'fertility':
        return s.quickSummaryViewStatsButton;
      case 'ovulationTest':
        return s.quickSummaryViewTestButton;
      default:
        return '';
    }
  }

  String _dateLabel(AppStrings s, DateTime date) => '${date.day} ${s.monthShort(date.month)} ${date.year}';

  String _phaseLabel(AppStrings s, String? phaseKey) {
    switch (phaseKey) {
      case 'menstrual':
      case 'folicular':
      case 'ovulacion':
      case 'lutea':
        return _phaseWord(s, phaseKey!);
      default:
        return s.quickSummaryNoDataYet;
    }
  }

  // Mismas 4 etiquetas de fase que ya usa el resto de la app (Revisión /
  // Estadísticas), traducidas a los 4 idiomas soportados.
  String _phaseWord(AppStrings s, String key) {
    const table = {
      'menstrual': {'es': 'Menstrual', 'en': 'Menstrual', 'fr': 'Menstruelle', 'de': 'Menstruation'},
      'folicular': {'es': 'Folicular', 'en': 'Follicular', 'fr': 'Folliculaire', 'de': 'Follikelphase'},
      'ovulacion': {'es': 'Ovulación', 'en': 'Ovulation', 'fr': 'Ovulation', 'de': 'Eisprung'},
      'lutea': {'es': 'Lútea', 'en': 'Luteal', 'fr': 'Lutéale', 'de': 'Lutealphase'},
    };
    final entry = table[key]!;
    return entry[s.code] ?? entry['es']!;
  }

  void _goToDestination(BuildContext context) {
    switch (summaryKey) {
      case 'periodCycle':
        if (pregnancy.enabled && pregnancy.lmp != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PregnancyTrackingScreen(lmp: pregnancy.lmp!, themeId: themeId, isTwins: pregnancy.isTwins),
            ),
          );
        } else {
          Navigator.of(context).pop();
          onNavigateToTab(1);
        }
        break;
      case 'symptoms':
      case 'fertility':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StatsScreen(data: data, themeId: themeId, inPregnancyMode: pregnancy.enabled && pregnancy.lmp != null),
          ),
        );
        break;
      case 'ovulationTest':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OvulationTestScreen(themeId: themeId)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final primary = Color(_theme.primary);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context, s, primary),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _buildContent(context, s, primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppStrings s, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              _title(s),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          InkWell(
            onTap: () => _goToDestination(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_forward, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(_buttonLabel(s), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Color _toneColor(String tone) {
    switch (tone) {
      case 'good':
        return const Color(0xFF3B6D11);
      case 'warn':
        return const Color(0xFFA32D2D);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildContent(BuildContext context, AppStrings s, Color primary) {
    switch (summaryKey) {
      case 'periodCycle':
        return _buildPeriodCycleContent(s, primary);
      case 'symptoms':
        return _buildSymptomsContent(s, primary);
      case 'ovulationTest':
        return _buildOvulationTestContent(s, primary);
      case 'fertility':
        return _buildFertilityContent(s, primary);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _valueCard({
    required AppStrings s,
    required Color primary,
    required String label,
    required String bigValue,
  }) {
    return _cardShadow(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            bigValue,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: primary, height: 1.15),
          ),
        ],
      ),
    );
  }

  Widget _evaluationCard(AppStrings s, {required String message, required String tone, IconData icon = Icons.info_outline}) {
    return _cardShadow(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: _toneColor(tone).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: _toneColor(tone)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fieldDetailEvaluationTitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- 1. Periodo y ciclo ----
  Widget _buildPeriodCycleContent(AppStrings s, Color primary) {
    final prediction = _predictor.predict();
    final nextPeriod = prediction.nextPeriodStart;
    final avgCycle = _predictor.getAvgCycleLength();
    final avgPeriod = _predictor.getAvgPeriodLength();
    final hasPrediction = nextPeriod != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _valueCard(
          s: s,
          primary: primary,
          label: s.quickSummaryNextPeriodLabel,
          bigValue: hasPrediction ? _dateLabel(s, nextPeriod) : s.quickSummaryNoDataYet,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _miniStat(s.quickSummaryAvgCycleLabel, '$avgCycle ${s.meDayUnit}', primary)),
            const SizedBox(width: 12),
            Expanded(child: _miniStat(s.quickSummaryAvgPeriodLabel, '$avgPeriod ${s.meDayUnit}', primary)),
          ],
        ),
        const SizedBox(height: 14),
        _evaluationCard(
          s,
          message: hasPrediction ? s.quickSummaryEvalPeriodCycle : s.quickSummaryEvalPeriodCycleNoData,
          tone: hasPrediction ? 'neutral' : 'warn',
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color primary) {
    return _cardShadow(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primary)),
        ],
      ),
    );
  }

  // ---- 2. Síntomas y predicciones ----
  Widget _buildSymptomsContent(AppStrings s, Color primary) {
    final phaseKey = _predictor.currentPhaseKey();
    final symptomDays = _countSymptomDaysLast30();
    final hasPhase = phaseKey != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _valueCard(
          s: s,
          primary: primary,
          label: s.quickSummaryCurrentPhaseLabel,
          bigValue: _phaseLabel(s, phaseKey),
        ),
        const SizedBox(height: 14),
        _miniStat(s.quickSummarySymptomsDaysLabel, '$symptomDays', primary),
        const SizedBox(height: 14),
        _evaluationCard(
          s,
          message: hasPhase ? s.quickSummaryEvalSymptoms : s.quickSummaryEvalSymptomsNoData,
          tone: hasPhase ? 'neutral' : 'warn',
        ),
      ],
    );
  }

  int _countSymptomDaysLast30() {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    var count = 0;
    for (final entry in data.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      final daysAgo = todayMidnight.difference(date).inDays;
      if (daysAgo < 0 || daysAgo > 30) continue;
      if (entry.value.symptoms.isNotEmpty) count++;
    }
    return count;
  }

  // ---- 3. Test de ovulación ----
  Widget _buildOvulationTestContent(AppStrings s, Color primary) {
    final phaseKey = _predictor.currentPhaseKey();
    final prediction = _predictor.predict();
    final fertileStart = prediction.fertileRangeStart;
    final fertileEnd = prediction.fertileRangeEnd;
    final fertileDates = prediction.fertileDates;

    final today = DateTime.now();
    final todayKey = dateKey(today);
    final hasData = phaseKey != null;

    bool withinWindow;
    if (fertileStart != null && fertileEnd != null) {
      withinWindow = !today.isBefore(DateTime(fertileStart.year, fertileStart.month, fertileStart.day)) &&
          !today.isAfter(DateTime(fertileEnd.year, fertileEnd.month, fertileEnd.day));
    } else {
      withinWindow = fertileDates.contains(todayKey);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _valueCard(
          s: s,
          primary: primary,
          label: s.quickSummaryCurrentPhaseLabel,
          bigValue: _phaseLabel(s, phaseKey),
        ),
        const SizedBox(height: 14),
        _evaluationCard(
          s,
          icon: withinWindow && hasData ? Icons.check_circle_outline : Icons.info_outline,
          message: !hasData
              ? s.quickSummaryOvulationNoData
              : withinWindow
                  ? s.quickSummaryOvulationNearWindow
                  : s.quickSummaryOvulationOutsideWindow,
          tone: !hasData ? 'warn' : (withinWindow ? 'good' : 'neutral'),
        ),
      ],
    );
  }

  // ---- 4. Fertilidad ----
  Widget _buildFertilityContent(AppStrings s, Color primary) {
    final prediction = _predictor.predict();
    final fertileStart = prediction.fertileRangeStart ?? prediction.ovulationDate?.subtract(const Duration(days: 5));
    final fertileEnd = prediction.fertileRangeEnd ?? prediction.ovulationDate?.add(const Duration(days: 1));
    final hasWindow = fertileStart != null && fertileEnd != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _valueCard(
          s: s,
          primary: primary,
          label: s.quickSummaryFertileWindowLabel,
          bigValue: hasWindow
              ? '${_dateLabel(s, fertileStart)} — ${_dateLabel(s, fertileEnd)}'
              : s.quickSummaryNoDataYet,
        ),
        const SizedBox(height: 14),
        _evaluationCard(
          s,
          message: hasWindow ? s.quickSummaryEvalFertility : s.quickSummaryEvalFertilityNoData,
          tone: hasWindow ? 'neutral' : 'warn',
        ),
      ],
    );
  }
}
