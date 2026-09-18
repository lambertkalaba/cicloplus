import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart';
import '../services/settings_service.dart' show AppThemeOption, PregnancySettings, themeById;
import '../theme/app_theme.dart';

/// Pantalla de detalle de "Etapa corporal", abierta al tocar la tarjeta
/// ETAPA CORPORAL de la pestaña Hoy. Calca el comportamiento (no el arte)
/// de dos capturas de referencia de otra app: arriba un círculo con el
/// ícono de la fase actual + arco de progreso y una descripción
/// expandible (sin cambios respecto a la versión anterior); más abajo la
/// tarjeta de probabilidad de concepción fue reemplazada por el diseño
/// completo aprobado en v0 (`components/body-stage-screen.tsx`): una
/// curva suavizada de probabilidad (Alta/Media/Baja) en una tarjeta, y en
/// una segunda tarjeta separada un slider arrastrable de "Día del ciclo"
/// con segmentos de color (período/ventana fértil), un marcador fijo que
/// siempre señala el día real de hoy, un mango arrastrable con píldora
/// "Hoy"/número de día, y un bloque de texto que explica la fase del día
/// seleccionado en vivo. Solo se navega aquí cuando NO está en modo
/// embarazo (esa tarjeta reemplaza a la de embarazo).
class BodyStageDetailScreen extends StatefulWidget {
  final Map<String, DayEntry> data;
  final PregnancySettings pregnancy;
  final bool irregularCycleMode;
  final String themeId;
  // "Mi objetivo" (Configuración/Yo): la tarjeta de "Probabilidad de
  // concepción" de abajo solo se muestra con "Intentar concebir" — con
  // "Seguir mi periodo" no aporta y se oculta (ver build()).
  final String userGoal;

  const BodyStageDetailScreen({
    super.key,
    required this.data,
    required this.pregnancy,
    required this.irregularCycleMode,
    required this.themeId,
    this.userGoal = 'period',
  });

  @override
  State<BodyStageDetailScreen> createState() => _BodyStageDetailScreenState();
}

class _BodyStageDetailScreenState extends State<BodyStageDetailScreen> {
  late CyclePredictor _predictor;
  late int _todayDayInCycle;
  late int _selectedDayInCycle;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _predictor = CyclePredictor(widget.data, forceIrregular: widget.irregularCycleMode);
    _todayDayInCycle = _predictor.currentDayInCycle() ?? 0;
    _selectedDayInCycle = _todayDayInCycle;
  }

  String? _phaseKeyForDay(int dayInCycle) {
    final periodLen = _predictor.getAvgPeriodLength();
    final cycleLen = _predictor.getAvgCycleLength();
    final ovulationDay = cycleLen - 14;
    if (dayInCycle < periodLen) return 'menstrual';
    if (dayInCycle < ovulationDay - 2) return 'folicular';
    if (dayInCycle <= ovulationDay + 1) return 'ovulacion';
    return 'lutea';
  }

  IconData _iconForPhase(String? phase) {
    switch (phase) {
      case 'menstrual':
        return Icons.water_drop;
      case 'folicular':
        return Icons.eco;
      case 'ovulacion':
        return Icons.egg_alt;
      case 'lutea':
        return Icons.nightlight_round;
      default:
        return Icons.water_drop;
    }
  }

  String _stageName(AppStrings s, String? phase) {
    switch (phase) {
      case 'menstrual':
        return s.todayLegendPeriod;
      case 'folicular':
        return s.todayStageFollicular;
      case 'ovulacion':
        return s.todayLegendOvulation;
      case 'lutea':
        return s.bodyStageLutealMotivation.isNotEmpty ? _lutealName(s) : s.todayStageLuteal;
      default:
        return s.todayTellUsMore;
    }
  }

  // La captura de referencia usa un nombre corto de fase ("Período",
  // "Fase folicular", etc.) en vez de la frase larga "Estás en..." que ya
  // existe para la tarjeta de Hoy — se arma aquí a partir de piezas cortas
  // ya traducidas para no duplicar cadenas i18n innecesarias.
  String _lutealName(AppStrings s) => s.todayStageLuteal;

  String _descriptionForPhase(AppStrings s, String? phase) {
    switch (phase) {
      case 'menstrual':
        return s.bodyStageMenstrualDescription;
      case 'folicular':
        return s.bodyStageFollicularDescription;
      case 'ovulacion':
        return s.bodyStageOvulationDescription;
      case 'lutea':
        return s.bodyStageLutealDescription;
      default:
        return s.bodyStageMenstrualDescription;
    }
  }

  String _motivationForPhase(AppStrings s, String? phase) {
    switch (phase) {
      case 'menstrual':
        return s.bodyStageMenstrualMotivation;
      case 'folicular':
        return s.bodyStageFollicularMotivation;
      case 'ovulacion':
        return s.bodyStageOvulationMotivation;
      case 'lutea':
        return s.bodyStageLutealMotivation;
      default:
        return s.bodyStageMenstrualMotivation;
    }
  }

  String _symptomsForPhase(AppStrings s, String? phase) {
    switch (phase) {
      case 'menstrual':
        return s.bodyStageMenstrualSymptoms;
      case 'folicular':
        return s.bodyStageFollicularSymptoms;
      case 'ovulacion':
        return s.bodyStageOvulationSymptoms;
      case 'lutea':
        return s.bodyStageLutealSymptoms;
      default:
        return s.bodyStageMenstrualSymptoms;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(widget.themeId);
    final phase = _phaseKeyForDay(_todayDayInCycle);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCloseButton(context),
              const SizedBox(height: 8),
              _buildPhaseHero(s, theme, phase),
              const SizedBox(height: 18),
              _buildSymptomsCard(s, phase),
              if (widget.userGoal == 'conceive') ...[
                const SizedBox(height: 20),
                _buildConceptionCurveCard(s, theme),
              ],
              const SizedBox(height: 16),
              _buildCycleSliderCard(s, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildPhaseHero(AppStrings s, AppThemeOption theme, String? phase) {
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);
    final cycleLen = _predictor.getAvgCycleLength();
    final progress = cycleLen > 0 ? (_todayDayInCycle / cycleLen).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        SizedBox(
          width: 168,
          height: 168,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(168, 168),
                painter: _ProgressArcPainter(progress: progress.toDouble()),
              ),
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primary, primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(_iconForPhase(phase), color: Colors.white, size: 46),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '${s.bodyStageDayLabel}: ${_todayDayInCycle + 1}',
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          _stageName(s, phase),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _descriptionForPhase(s, phase),
            textAlign: TextAlign.center,
            maxLines: _descriptionExpanded ? null : 2,
            overflow: _descriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _descriptionExpanded ? s.bodyStageHide : s.bodyStageSeeMore,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: primaryDark),
              ),
              Icon(
                _descriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: primaryDark,
              ),
            ],
          ),
        ),
        if (_descriptionExpanded) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _motivationForPhase(s, phase),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSymptomsCard(AppStrings s, String? phase) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.bodyStageSymptomsHeader,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _symptomsForPhase(s, phase),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ---- Tarjeta 1 (v0 "Conception probability card"): curva suavizada de
  // probabilidad de concepción con etiquetas Alta/Media/Baja a la
  // izquierda, marcador punteado vertical + punto en el día seleccionado,
  // y debajo el nivel + "Probabilidad de concepción". ----
  Widget _buildConceptionCurveCard(AppStrings s, AppThemeOption theme) {
    final cycleLen = _predictor.getAvgCycleLength();
    final probability = _predictor.conceptionProbabilityForCycleDay(_selectedDayInCycle);
    final level = _predictor.conceptionLevelLabel(probability);

    final levelLabel = switch (level) {
      'alta' => s.bodyStageHighProbability,
      'media' => s.bodyStageMediumProbability,
      _ => s.bodyStageLowProbability,
    };
    final levelColor = switch (level) {
      'alta' => AppColors.ovulation,
      'media' => AppColors.fertile,
      _ => AppColors.textMuted,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  height: 116,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.bodyStageHighProbability, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(s.bodyStageMediumProbability, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(s.bodyStageLowProbability, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _ConceptionCurvePainter(
                      cycleLen: cycleLen,
                      selectedDay: _selectedDayInCycle,
                      probabilityForDay: _predictor.conceptionProbabilityForCycleDay,
                      lineColor: const Color(0xFFE91E8C),
                      levelColor: levelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: levelLabel,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: levelColor, height: 1.2),
                ),
                TextSpan(
                  text: ' · ${s.bodyStageConceptionProbability}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Tarjeta 2 (v0 "Cycle-day slider card"): encabezado "Hoy · Día
  // N"/"Día N · fecha", slider arrastrable con segmentos de color, marca
  // fija de "hoy" siempre visible + mango arrastrable, extremos "Día
  // 1"/"Día N", y explicación de fase en vivo para el día seleccionado. ----
  Widget _buildCycleSliderCard(AppStrings s, AppThemeOption theme) {
    final cycleLen = _predictor.getAvgCycleLength();
    final periodLen = _predictor.getAvgPeriodLength();
    final isToday = _selectedDayInCycle == _todayDayInCycle;
    final selectedDate = _dateForCycleDay(_selectedDayInCycle);
    final phase = _phaseKeyForDay(_selectedDayInCycle);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              children: isToday
                  ? [
                      TextSpan(text: s.bodyStageToday, style: const TextStyle(color: Color(0xFFE91E8C))),
                      TextSpan(
                        text: ' · ${s.bodyStageDayLabel}: ${_selectedDayInCycle + 1}',
                        style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ]
                  : [
                      TextSpan(text: '${s.bodyStageDayLabel} ${_selectedDayInCycle + 1}'),
                      TextSpan(
                        text: ' · ${s.dayLabel(selectedDate.day, selectedDate.month)}',
                        style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 20),
          _buildDraggableCycleSlider(s, theme, cycleLen, periodLen),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${s.bodyStageDayLabel} 1', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text('${s.bodyStageDayLabel} $cycleLen', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stageName(s, phase),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  _descriptionForPhase(s, phase),
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fecha calendario concreta para un día 0-based dentro del ciclo
  /// actual, contando desde el inicio del último ciclo registrado (o
  /// desde hoy si no hay historial). Equivale a `dateForCycleDay` de
  /// v0's lib/cycle.ts.
  DateTime _dateForCycleDay(int dayInCycle) {
    final cycleLen = _predictor.getAvgCycleLength();
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final cycleStart = todayMidnight.subtract(Duration(days: _todayDayInCycle.clamp(0, cycleLen)));
    return cycleStart.add(Duration(days: dayInCycle));
  }

  Widget _buildDraggableCycleSlider(AppStrings s, AppThemeOption theme, int cycleLen, int periodLen) {
    final periodFraction = cycleLen > 0 ? (periodLen / cycleLen).clamp(0.0, 1.0) : 0.0;
    final ovulationDay = cycleLen - 14;
    final fertileStartFraction = cycleLen > 0 ? ((ovulationDay - 5) / cycleLen).clamp(0.0, 1.0) : 0.0;
    final fertileEndFraction = cycleLen > 0 ? ((ovulationDay + 1) / cycleLen).clamp(0.0, 1.0) : 0.0;
    final selectedFraction = cycleLen > 0 ? (_selectedDayInCycle / cycleLen).clamp(0.0, 1.0) : 0.0;
    final todayFraction = cycleLen > 0 ? (_todayDayInCycle / cycleLen).clamp(0.0, 1.0) : 0.0;
    final isToday = _selectedDayInCycle == _todayDayInCycle;

    return LayoutBuilder(
      builder: (context, constraints) {
        const trackHeight = 12.0;
        const handleSize = 26.0;
        const todayMarkerSize = 14.0;
        final width = constraints.maxWidth;

        void updateFromDx(double dx) {
          final clampedDx = dx.clamp(0.0, width);
          final fraction = width > 0 ? clampedDx / width : 0.0;
          final newDay = (fraction * cycleLen).round().clamp(0, cycleLen - 1);
          if (newDay != _selectedDayInCycle) {
            setState(() => _selectedDayInCycle = newDay);
          }
        }

        final handleX = (selectedFraction * width).clamp(handleSize / 2, width - handleSize / 2);
        final todayMarkerX = (todayFraction * width).clamp(todayMarkerSize / 2, width - todayMarkerSize / 2);

        // Un único GestureDetector cubre toda la barra (padding vertical
        // extra para un área de toque más generosa) y maneja tanto el tap
        // directo como el arrastre horizontal con la posición absoluta del
        // dedo (`details.localPosition.dx`), en vez de anidar otro
        // GestureDetector dentro del mango — evita que el
        // SingleChildScrollView padre robe el gesto de arrastre.
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragDown: (details) => updateFromDx(details.localPosition.dx),
            onHorizontalDragUpdate: (details) => updateFromDx(details.localPosition.dx),
            onTapDown: (details) => updateFromDx(details.localPosition.dx),
            child: SizedBox(
              height: handleSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                    child: Container(height: trackHeight, color: const Color(0xFFECE4F2)),
                  ),
                  if (periodFraction > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: periodFraction,
                        child: ClipRRect(
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(trackHeight / 2)),
                          child: Container(height: trackHeight, color: const Color(0xFFF5A0CD)),
                        ),
                      ),
                    ),
                  if (fertileEndFraction > fertileStartFraction)
                    Positioned(
                      left: fertileStartFraction * width,
                      width: (fertileEndFraction - fertileStartFraction) * width,
                      child: Container(height: trackHeight, color: const Color(0xFFFFD54A)),
                    ),
                  // Marcador fijo del día real de hoy — permanece visible
                  // en su posición aunque el mango arrastrable se mueva a
                  // explorar otro día del ciclo.
                  if (!isToday)
                    Positioned(
                      left: todayMarkerX - todayMarkerSize / 2,
                      child: IgnorePointer(
                        child: Container(
                          width: todayMarkerSize,
                          height: todayMarkerSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.textPrimary, width: 2),
                          ),
                        ),
                      ),
                    ),
                  // Mango arrastrable con píldora "Hoy"/número de día.
                  Positioned(
                    left: handleX - handleSize / 2,
                    child: IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              isToday ? s.bodyStageToday : '${_selectedDayInCycle + 1}',
                              style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            width: handleSize,
                            height: handleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: AppColors.textPrimary, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Arco de progreso simbólico (violeta/rosa/amarillo) alrededor del
/// círculo de la fase actual, no pretende ser exacto — solo da sensación
/// visual de "recorrido dentro del ciclo".
class _ProgressArcPainter extends CustomPainter {
  final double progress;

  _ProgressArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final backgroundPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = const SweepGradient(
      colors: [AppColors.ovulation, AppColors.primary, Color(0xFFFFC94D), AppColors.ovulation],
      stops: [0.0, 0.4, 0.75, 1.0],
    );
    final sweepPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.141592653589793 * progress.clamp(0.02, 1.0);
    canvas.drawArc(rect, -3.141592653589793 / 2, sweepAngle, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Curva de probabilidad de concepción suavizada (spline tipo Catmull-Rom
/// convertida a segmentos cúbicos, igual que el `smoothPath` de
/// v0/lib/cycle.ts + components/body-stage-screen.tsx), con relleno
/// degradado bajo la curva, líneas guía horizontales en 15%/50%/85%, y una
/// línea vertical punteada + punto marcando el día seleccionado.
///
/// La FORMA de la curva viene de [probabilityForDay] (normalmente
/// `CyclePredictor.conceptionProbabilityForCycleDay`, una campana
/// triangular simple centrada en el día de ovulación real calculado con
/// los datos de la usuaria) en vez del array de 28 valores fijos y
/// "hand-tuned" que usa el prototipo v0 (pensado solo para una demo con
/// fecha fija) — se prefiere mantener `CyclePredictor` como única fuente
/// de verdad del cálculo de ciclo, ya que la usan también Hoy y
/// Estadísticas, y así ambas pantallas siempre coinciden en la predicción.
class _ConceptionCurvePainter extends CustomPainter {
  final int cycleLen;
  final int selectedDay;
  final double Function(int dayInCycle) probabilityForDay;
  final Color lineColor;
  final Color levelColor;

  _ConceptionCurvePainter({
    required this.cycleLen,
    required this.selectedDay,
    required this.probabilityForDay,
    required this.lineColor,
    required this.levelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cycleLen <= 0) return;

    // Líneas guía horizontales en 15%, 50% y 85% de la altura, igual que
    // v0 ([0.15, 0.5, 0.85].map(...)).
    final guidePaint = Paint()
      ..color = const Color(0xFFEFE7F6)
      ..strokeWidth = 1;
    for (final fraction in [0.15, 0.5, 0.85]) {
      final y = size.height * (1 - fraction);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    // Un punto muestreado por día del ciclo (igual granularidad que v0,
    // que genera CYCLE_DAYS puntos, uno por día entero).
    final points = <Offset>[];
    for (var i = 0; i < cycleLen; i++) {
      final probability = probabilityForDay(i).clamp(0.0, 1.0);
      final x = ((i + 0.5) / cycleLen) * size.width;
      final y = size.height * (1 - probability);
      points.add(Offset(x, y));
    }
    if (points.isEmpty) return;

    final path = _smoothPath(points);

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [levelColor.withOpacity(0.22), levelColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Línea vertical punteada + punto sobre la curva en el día
    // seleccionado, coloreados con el color del nivel (Alta/Media/Baja).
    final selectedIndex = selectedDay.clamp(0, cycleLen - 1);
    final selectedPoint = points[selectedIndex];

    final markerLinePaint = Paint()
      ..color = levelColor
      ..strokeWidth = 1.5;
    _drawDashedLine(canvas, Offset(selectedPoint.dx, 0), Offset(selectedPoint.dx, size.height), markerLinePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = levelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(selectedPoint, 7, dotPaint);
    canvas.drawCircle(selectedPoint, 7, dotBorderPaint);
  }

  /// Traza una curva suave tipo Catmull-Rom (convertida a curvas cúbicas
  /// de Bézier) a través de [points], igual que la función `smoothPath`
  /// de v0's body-stage-screen.tsx.
  Path _smoothPath(List<Offset> points) {
    final path = Path();
    if (points.length < 2) {
      if (points.isNotEmpty) path.moveTo(points.first.dx, points.first.dy);
      return path;
    }
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final c1x = p1.dx + (p2.dx - p0.dx) / 6;
      final c1y = p1.dy + (p2.dy - p0.dy) / 6;
      final c2x = p2.dx - (p3.dx - p1.dx) / 6;
      final c2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(c1x, c1y, c2x, c2y, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 3.0;
    const gapLength = 3.0;
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    var distance = 0.0;
    while (distance < totalLength) {
      final segmentEnd = (distance + dashLength).clamp(0.0, totalLength);
      canvas.drawLine(start + direction * distance, start + direction * segmentEnd, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _ConceptionCurvePainter oldDelegate) =>
      oldDelegate.selectedDay != selectedDay ||
      oldDelegate.cycleLen != cycleLen ||
      oldDelegate.levelColor != levelColor;
}
