import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/settings_service.dart' show AppThemeOption, SettingsService, themeById;
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'sex_life_detail_screen.dart';

/// Pantalla de detalle de solo lectura para uno de los 6 campos "simples"
/// del grid de accesos rápidos de la pestaña "Yo" (temperatura, vida
/// sexual, peso, sueño, autoexamen de mamas, agua). Rediseño estilo iOS
/// (fase "info + evaluación"): header con botón "Editar" en píldora junto
/// al título, tarjeta de valor grande + badge de tendencia, mini-gráfica
/// de los últimos registros (para los 4 campos numéricos) y una tarjeta de
/// "Evaluación" con un mensaje contextual (rango normal, meta cumplida,
/// posible ovulación, recordatorio de autoexamen, etc.) en vez de mostrar
/// solo el último valor sin interpretación.
///
/// `fieldKey` es uno de: 'weight' | 'sleep' | 'water' | 'temperature' |
/// 'sexLife' | 'breastSelfExam'. El botón "Editar" siempre abre
/// `RegisterScreen` (los 6 campos viven ahí: 'sexLife'/'breastSelfExam' en
/// su propia tarjeta, y los otros 4 comparten la tarjeta "Estilo de
/// vida"), con scroll automático a la sección vía `focusSection` — ya no se
/// usa el editor modal `DayEditorSheet` desde aquí (quedó desactualizado
/// frente al diseño de Registrar).
class FieldDetailScreen extends StatefulWidget {
  final String themeId;
  final Map<String, DayEntry> data;
  final String fieldKey;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;

  /// "Mi objetivo" (Configuración/Yo), reenviado tal cual a RegisterScreen
  /// cuando se pulsa "Editar" — ver register_screen.dart.
  final String userGoal;

  const FieldDetailScreen({
    super.key,
    required this.themeId,
    required this.data,
    required this.fieldKey,
    required this.onDataChanged,
    this.userGoal = 'period',
  });

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  // Copia local mutable de `data`, reemplazada cuando `onDataChanged` se
  // dispara desde el editor modal (peso/sueño/agua/temperatura), para que
  // esta pantalla refleje el nuevo valor sin depender de que el padre
  // (MeScreen) reconstruya este widget desde cero.
  late Map<String, DayEntry> _data;

  final SettingsService _settingsService = SettingsService();
  double? _heightCm;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    if (widget.fieldKey == 'weight') _loadHeight();
  }

  Future<void> _loadHeight() async {
    final h = await _settingsService.loadHeightCm();
    if (!mounted) return;
    setState(() => _heightCm = h);
  }

  AppThemeOption get _theme => themeById(widget.themeId);

  bool get _isNumeric =>
      widget.fieldKey == 'weight' ||
      widget.fieldKey == 'sleep' ||
      widget.fieldKey == 'water' ||
      widget.fieldKey == 'temperature';

  /// Título del campo (reutiliza los mismos strings que ya usa el grid de
  /// "Yo" en me_screen.dart).
  String _title(AppStrings s) {
    switch (widget.fieldKey) {
      case 'weight':
        return s.meWeight;
      case 'sleep':
        return s.meSleep;
      case 'water':
        return s.meDrinkWater;
      case 'temperature':
        return s.meTemperature;
      case 'sexLife':
        return s.meSexLife;
      case 'breastSelfExam':
        return s.meBreastSelfExam;
      default:
        return '';
    }
  }

  /// Mismo IconData que usa cada entrada del grid en me_screen.dart, para
  /// que el ícono grande de esta pantalla coincida con el que la usuaria
  /// tocó para llegar aquí.
  IconData _icon() {
    switch (widget.fieldKey) {
      case 'weight':
        return Icons.monitor_weight_outlined;
      case 'sleep':
        return Icons.bedtime_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      case 'temperature':
        return Icons.thermostat;
      case 'sexLife':
        return Icons.favorite_border;
      case 'breastSelfExam':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.info_outline;
    }
  }

  /// True si el DayEntry tiene un valor poblado para este campo concreto.
  bool _hasValue(DayEntry entry) {
    switch (widget.fieldKey) {
      case 'weight':
        return entry.weight != null;
      case 'sleep':
        return entry.sleep != null;
      case 'water':
        return entry.water != null;
      case 'temperature':
        return entry.temp != null;
      case 'sexLife':
        // "Vida sexual" se considera registrada si hubo cualquier
        // interacción marcada ese día (mismos campos que el formulario).
        return entry.sex ||
            entry.unprotected ||
            entry.sexMasturbation ||
            entry.sexNoOrgasm ||
            entry.sexOrgasm ||
            entry.sexDesire ||
            (entry.sexTimes != null && entry.sexTimes! > 0);
      case 'breastSelfExam':
        return entry.breastSelfExam != null && entry.breastSelfExam!.isNotEmpty;
      default:
        return false;
    }
  }

  /// Busca el registro más reciente (fecha descendente) que tenga este
  /// campo poblado. Devuelve (fecha, entry) o null si no hay ninguno.
  MapEntry<DateTime, DayEntry>? _findLatest() {
    final keys = _data.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final key in keys) {
      final entry = _data[key];
      if (entry == null) continue;
      if (_hasValue(entry)) {
        final date = DateTime.tryParse(key);
        if (date == null) continue;
        return MapEntry(date, entry);
      }
    }
    return null;
  }

  /// Últimos N registros con valor numérico para este campo (fecha, valor),
  /// en orden cronológico ascendente — usados para la mini-gráfica de
  /// tendencia y para calcular el cambio respecto al registro anterior.
  List<MapEntry<DateTime, double>> _numericSeries({int maxPoints = 7}) {
    final keys = _data.keys.toList()..sort();
    final series = <MapEntry<DateTime, double>>[];
    for (final key in keys) {
      final entry = _data[key];
      if (entry == null || !_hasValue(entry)) continue;
      final date = DateTime.tryParse(key);
      if (date == null) continue;
      final v = switch (widget.fieldKey) {
        'weight' => entry.weight,
        'sleep' => entry.sleep,
        'water' => entry.water?.toDouble(),
        'temperature' => entry.temp,
        _ => null,
      };
      if (v == null) continue;
      series.add(MapEntry(date, v));
    }
    if (series.length <= maxPoints) return series;
    return series.sublist(series.length - maxPoints);
  }

  /// Valor grande + unidad para los 4 campos numéricos.
  String _bigValue(DayEntry entry) {
    switch (widget.fieldKey) {
      case 'weight':
        return _formatNum(entry.weight!);
      case 'sleep':
        return _formatNum(entry.sleep!);
      case 'water':
        return '${entry.water}';
      case 'temperature':
        return _formatNum(entry.temp!);
      default:
        return '';
    }
  }

  String _unit() {
    switch (widget.fieldKey) {
      case 'weight':
        return 'kg';
      case 'sleep':
        return 'h';
      case 'water':
        return 'vasos';
      case 'temperature':
        return '°C';
      default:
        return '';
    }
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  /// Descripción de texto para vida sexual: lista los toggles activos ese
  /// día, mismo vocabulario que usa RegisterScreen/day_editor.
  String _sexLifeDescription(AppStrings s, DayEntry entry) {
    final parts = <String>[];
    if (entry.unprotected) parts.add(s.sexUnprotectedFullLabel);
    if (entry.sex && !entry.unprotected) parts.add(s.sexProtectedLabel);
    if (entry.sexMasturbation) parts.add(s.sexMasturbationLabel);
    if (entry.sexNoOrgasm) parts.add(s.sexNoOrgasmLabel);
    if (entry.sexOrgasm) parts.add(s.sexOrgasmLabel);
    if (entry.sexDesire) parts.add(s.sexDesireLabel);
    if (entry.sexTimes != null && entry.sexTimes! > 0) {
      parts.add(s.sexTimesLabel(entry.sexTimes!));
    }
    if (parts.isEmpty) return s.sexNoneLabel;
    return parts.join(' · ');
  }

  String _breastSelfExamDescription(AppStrings s, DayEntry entry) {
    final id = entry.breastSelfExam;
    if (id == null) return '';
    final catalogEntry = kBreastSelfExamCatalog.firstWhere(
      (m) => m['id'] == id,
      orElse: () => const {},
    );
    final emoji = catalogEntry['emoji'] ?? '';
    return '$emoji ${s.breastSelfExamLabelFor(id)}'.trim();
  }

  String _dateLabel(AppStrings s, DateTime date) => '${date.day} ${s.monthShort(date.month)} ${date.year}';

  /// Evaluación contextual mostrada en la tarjeta "Evaluación". Devuelve
  /// (mensaje, tono) donde tono determina el color del badge/tarjeta:
  /// 'good' (verde), 'warn' (ámbar/rojo) o 'neutral' (gris/rosa).
  ({String message, String tone}) _evaluation(AppStrings s, DayEntry entry) {
    switch (widget.fieldKey) {
      case 'weight':
        if (_heightCm == null || _heightCm! <= 0) {
          return (message: s.evalWeightNoHeight, tone: 'neutral');
        }
        final heightM = _heightCm! / 100;
        final bmi = entry.weight! / (heightM * heightM);
        if (bmi < 18.5) return (message: s.evalWeightLow, tone: 'warn');
        if (bmi > 24.9) return (message: s.evalWeightHigh, tone: 'warn');
        return (message: s.evalWeightNormal, tone: 'good');
      case 'sleep':
        final h = entry.sleep!;
        if (h < 7) return (message: s.evalSleepLow, tone: 'warn');
        if (h > 9) return (message: s.evalSleepHigh, tone: 'warn');
        return (message: s.evalSleepGood, tone: 'good');
      case 'water':
        final glasses = entry.water ?? 0;
        if (glasses < 8) return (message: s.evalWaterLow, tone: 'warn');
        return (message: s.evalWaterGood, tone: 'good');
      case 'temperature':
        final series = _numericSeries(maxPoints: 5);
        if (series.length >= 3) {
          final last = series.last.value;
          final priorAvg =
              series.sublist(0, series.length - 1).map((e) => e.value).reduce((a, b) => a + b) / (series.length - 1);
          if (last - priorAvg >= 0.2) return (message: s.evalTempShift, tone: 'neutral');
        }
        return (message: s.evalTempNormal, tone: 'good');
      case 'sexLife':
        return (message: s.evalSexLifeSummary, tone: 'neutral');
      case 'breastSelfExam':
        final latest = _findLatest();
        if (latest == null) return (message: s.evalBreastSelfExamReminder, tone: 'neutral');
        final daysSince = DateTime.now().difference(latest.key).inDays;
        if (daysSince > 30) return (message: s.evalBreastSelfExamOverdue, tone: 'warn');
        return (message: s.evalBreastSelfExamReminder, tone: 'good');
      default:
        return (message: '', tone: 'neutral');
    }
  }

  void _goEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          data: _data,
          onDataChanged: _handleDataChanged,
          themeId: widget.themeId,
          focusSection: widget.fieldKey,
          showCloseButton: true,
          userGoal: widget.userGoal,
        ),
      ),
    );
  }

  /// Recibe el Map actualizado (desde RegisterScreen), lo sube al padre vía
  /// `widget.onDataChanged` y actualiza el estado local para refrescar la
  /// tarjeta al instante.
  void _handleDataChanged(Map<String, DayEntry> updated) {
    setState(() => _data = updated);
    widget.onDataChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final primary = Color(_theme.primary);
    final latest = _findLatest();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(s, primary),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: latest == null
                    ? _buildEmptyState(s, primary)
                    : _buildValueState(s, primary, latest.key, latest.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra superior estilo iOS: flecha atrás, título centrado, y botón
  /// "Editar" en píldora — reemplaza el AppBar plano + botón grande al pie
  /// que tenía la versión anterior.
  Widget _buildTopBar(AppStrings s, Color primary) {
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
            onTap: _goEdit,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(s.fieldDetailEditButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Color(_theme.primaryLight), shape: BoxShape.circle),
              child: Icon(_icon(), color: primary, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              s.fieldDetailEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _goEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(s.fieldDetailEmptyButton),
            ),
          ],
        ),
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

  Widget _buildValueState(AppStrings s, Color primary, DateTime date, DayEntry entry) {
    // "Vida sexual" reemplaza toda la tarjeta de valor único + tendencia +
    // evaluación por la tarjeta 2x2 (Veces/Orgasmo femenino/Con
    // protección/Sin protección), cada estadística tocable hacia su
    // propia pantalla de detalle — mismo patrón de la captura de
    // referencia, mucho más informativo que la descripción de texto plano
    // que había antes.
    if (widget.fieldKey == 'sexLife') {
      return _cardShadow(
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SexLifeStatDetailScreen(data: _data, themeId: widget.themeId, kind: SexLifeStatKind.times, userGoal: widget.userGoal),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_title(s), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 4),
              SexLifeSummaryCard(data: _data, themeId: widget.themeId, userGoal: widget.userGoal),
            ],
          ),
        ),
      );
    }

    final description = widget.fieldKey == 'breastSelfExam' ? _breastSelfExamDescription(s, entry) : '';
    final series = _isNumeric ? _numericSeries() : const <MapEntry<DateTime, double>>[];
    final eval = _evaluation(s, entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardShadow(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          Column(
            children: [
              Text(
                '${s.fieldDetailLastRecord} · ${_dateLabel(s, date)}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (_isNumeric)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _bigValue(entry),
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: primary, height: 1.0),
                      ),
                      TextSpan(
                        text: ' ${_unit()}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              if (_isNumeric && series.length >= 2) ...[
                const SizedBox(height: 12),
                _trendBadge(s, series),
              ],
            ],
          ),
        ),
        if (_isNumeric) ...[
          const SizedBox(height: 14),
          _cardShadow(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fieldDetailTrendTitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                if (series.length < 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(s.fieldDetailNotEnoughTrend, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  )
                else
                  SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: CustomPaint(painter: _MiniTrendPainter(series: series, color: primary)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _cardShadow(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: _toneColor(eval.tone).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.info_outline, size: 16, color: _toneColor(eval.tone)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.fieldDetailEvaluationTitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(eval.message, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _trendBadge(AppStrings s, List<MapEntry<DateTime, double>> series) {
    final last = series.last.value;
    final prev = series[series.length - 2].value;
    final diff = last - prev;
    final absDiff = diff.abs();
    final formatted = absDiff == absDiff.roundToDouble() ? absDiff.toInt().toString() : absDiff.toStringAsFixed(1);
    final isUp = diff > 0.01;
    final isDown = diff < -0.01;
    final direction = isUp ? s.fieldDetailTrendUp : (isDown ? s.fieldDetailTrendDown : s.fieldDetailTrendStable);
    final bg = isUp ? const Color(0xFFFAEEDA) : (isDown ? const Color(0xFFEAF3DE) : const Color(0xFFF1EFE8));
    final fg = isUp ? const Color(0xFF854F0B) : (isDown ? const Color(0xFF3B6D11) : const Color(0xFF5F5E5A));
    final icon = isUp ? Icons.trending_up : (isDown ? Icons.trending_down : Icons.trending_flat);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            absDiff == 0 ? direction : s.fieldDetailTrendChange(direction, '$formatted ${_unit()}'),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Mini-gráfica de línea (sin ejes ni etiquetas) para la tendencia de los
/// últimos registros numéricos — versión compacta del mismo patrón usado
/// en la gráfica de evolución de la pantalla de Peso.
class _MiniTrendPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> series;
  final Color color;
  _MiniTrendPainter({required this.series, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.map((e) => e.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    const padding = 6.0;
    final stepX = series.length > 1 ? (size.width - padding * 2) / (series.length - 1) : 0.0;

    final points = <Offset>[];
    for (var i = 0; i < series.length; i++) {
      final x = padding + i * stepX;
      final normalized = (series[i].value - minV) / range;
      final y = size.height - padding - normalized * (size.height - padding * 2);
      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 4, dotPaint);
    canvas.drawCircle(points.last, 4, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.color != color;
}
