import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Cada vez que la usuaria elige "Intentar concebir" como objetivo, abre
/// una hoja con un par de preguntas rápidas (fecha objetivo, tiempo
/// intentándolo, si el ciclo es irregular, si dejó anticonceptivos hace
/// poco) para poder orientarla mejor — igual que hacen otras apps de este
/// tipo en su onboarding de "trying to conceive". Se llama desde
/// `_selectGoal` cada vez que `goal == 'conceive'` (ver
/// SettingsScreen/MeScreen), no solo la primera vez.
///
/// Si ya había respuestas guardadas de una vez anterior (cambió de
/// objetivo y volvió a elegir "Intentar concebir" después), en vez de
/// forzar el cuestionario completo de 8 preguntas otra vez de entrada, se
/// pregunta primero con un diálogo corto si sigue siendo la misma
/// información — reporte de la usuaria: contestó el cuestionario, cambió
/// de objetivo, volvió a "Intentar concebir" y tuvo que rellenarlo todo de
/// nuevo.
///
/// Ese diálogo corto se salta y va directo al cuestionario completo (como
/// si fuera la primera vez) en dos casos, a pedido de la usuaria: cuando
/// de verdad es la primera vez (no hay nada guardado todavía), o cuando ya
/// pasaron 3 meses desde la última vez que se confirmó o completó el
/// cuestionario — pasado ese tiempo la situación pudo cambiar bastante
/// como para seguir asumiendo que "sigue igual" sin preguntar en detalle.
/// El cuestionario completo sigue precargando las respuestas anteriores
/// (ver `_load`) para no partir de cero en ningún caso.
const _kConceiveIntakeStaleAfter = Duration(days: 90);

Future<void> maybeShowConceiveIntake(BuildContext context, SettingsService settings) async {
  if (!context.mounted) return;
  final targetDate = await settings.loadConceiveTargetDate();
  final tryingDuration = await settings.loadConceiveTryingDuration();
  final confirmedAt = await settings.loadConceiveIntakeConfirmedAt();
  final hasPreviousAnswers = targetDate != null || tryingDuration != null;
  // Sin fecha de confirmación no se puede saber hace cuánto se contestó
  // (usuarias que ya tenían respuestas guardadas de antes de que existiera
  // este control), así que se trata igual que "pasaron los 3 meses": mejor
  // preguntar en detalle una vez más que asumir que sigue todo igual sin
  // saberlo.
  final isStale = confirmedAt == null || DateTime.now().difference(confirmedAt) > _kConceiveIntakeStaleAfter;
  if (hasPreviousAnswers && !isStale) {
    if (!context.mounted) return;
    final s = AppStrings.of(context);
    final sameAsBefore = await showDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(s.conceiveIntakeSameAsBeforeTitle),
        content: Text(s.conceiveIntakeSameAsBeforeBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.conceiveIntakeSameAsBeforeUpdate),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.conceiveIntakeSameAsBeforeYes),
          ),
        ],
      ),
    );
    // Si confirma que sigue igual (o cierra el diálogo sin elegir), no
    // hace falta abrir el cuestionario completo otra vez — pero sí se
    // renueva la fecha de confirmación, para que los próximos 3 meses se
    // cuenten desde hoy y no desde la respuesta original.
    if (sameAsBefore != false) {
      await settings.saveConceiveIntakeConfirmedAt(DateTime.now());
      return;
    }
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _ConceiveIntakeSheet(settings: settings),
  );
  // Se completó (o al menos se revisó) el cuestionario completo — cuenta
  // como una confirmación fresca de hoy, igual que responder "Sigue
  // igual" en el diálogo corto.
  await settings.saveConceiveIntakeConfirmedAt(DateTime.now());
}

class _ConceiveIntakeSheet extends StatefulWidget {
  final SettingsService settings;
  const _ConceiveIntakeSheet({required this.settings});

  @override
  State<_ConceiveIntakeSheet> createState() => _ConceiveIntakeSheetState();
}

class _ConceiveIntakeSheetState extends State<_ConceiveIntakeSheet> {
  DateTime? _targetDate;
  String? _tryingDuration;
  bool _irregularCycle = false;
  bool? _recentContraception;
  // Valores por defecto iguales a kDefaultCycleLen/kDefaultPeriodLen en
  // cycle_predictor.dart — se sobrescriben en _load() si ya había una
  // respuesta guardada.
  int _avgCycleLen = 28;
  int _avgPeriodLen = 5;
  bool? _usesOvulationTests;
  Set<String> _diagnosedConditions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final targetDate = await widget.settings.loadConceiveTargetDate();
    final duration = await widget.settings.loadConceiveTryingDuration();
    final irregular = await widget.settings.loadIrregularCycleMode();
    final contraception = await widget.settings.loadConceiveRecentContraception();
    final avgCycleLen = await widget.settings.loadConceiveAvgCycleLength();
    final avgPeriodLen = await widget.settings.loadConceiveAvgPeriodLength();
    final usesOvulationTests = await widget.settings.loadConceiveUsesOvulationTests();
    final diagnosedConditions = await widget.settings.loadConceiveDiagnosedConditions();
    if (!mounted) return;
    setState(() {
      _targetDate = targetDate;
      _tryingDuration = duration;
      _irregularCycle = irregular;
      _recentContraception = contraception;
      if (avgCycleLen != null) _avgCycleLen = avgCycleLen;
      if (avgPeriodLen != null) _avgPeriodLen = avgPeriodLen;
      _usesOvulationTests = usesOvulationTests;
      _diagnosedConditions = diagnosedConditions.toSet();
      _loading = false;
    });
  }

  // Selector de fecha estilo iOS (rueda + barra "Cancelar"/"Listo") en vez
  // del calendario cuadriculado de Material que usaba antes — pedido de la
  // usuaria para que se vea como iOS igual que el resto de la hoja.
  Future<void> _pickTargetDate() async {
    final s = AppStrings.of(context);
    final now = DateTime.now();
    final initial = _targetDate ?? now.add(const Duration(days: 90));
    var tempDate = initial;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(s.cancel, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        onPressed: () => Navigator.of(ctx).pop(tempDate),
                        child: Text(
                          s.reminderTimeSheetDone,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ovulation),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(brightness: Brightness.light),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initial,
                      minimumDate: now,
                      maximumDate: DateTime(now.year + 3),
                      onDateTimeChanged: (value) => tempDate = value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
      await widget.settings.saveConceiveTargetDate(picked);
    }
  }

  Future<void> _selectDuration(String value) async {
    setState(() => _tryingDuration = value);
    await widget.settings.saveConceiveTryingDuration(value);
  }

  Future<void> _toggleIrregular(bool value) async {
    setState(() => _irregularCycle = value);
    await widget.settings.saveIrregularCycleMode(value);
  }

  Future<void> _selectContraception(bool value) async {
    setState(() => _recentContraception = value);
    await widget.settings.saveConceiveRecentContraception(value);
  }

  Future<void> _changeCycleLen(int delta) async {
    final value = (_avgCycleLen + delta).clamp(15, 60);
    setState(() => _avgCycleLen = value);
    await widget.settings.saveConceiveAvgCycleLength(value);
  }

  Future<void> _changePeriodLen(int delta) async {
    final value = (_avgPeriodLen + delta).clamp(1, 15);
    setState(() => _avgPeriodLen = value);
    await widget.settings.saveConceiveAvgPeriodLength(value);
  }

  Future<void> _selectUsesOvulationTests(bool value) async {
    setState(() => _usesOvulationTests = value);
    await widget.settings.saveConceiveUsesOvulationTests(value);
  }

  // "Ninguna" es excluyente con el resto: marcarla borra cualquier otra
  // condición seleccionada, y marcar cualquier otra quita "Ninguna" —
  // no tendría sentido tener ambas a la vez.
  Future<void> _toggleCondition(String value) async {
    setState(() {
      if (value == 'none') {
        _diagnosedConditions = _diagnosedConditions.contains('none') ? {} : {'none'};
      } else if (_diagnosedConditions.contains(value)) {
        _diagnosedConditions = {..._diagnosedConditions}..remove(value);
      } else {
        _diagnosedConditions = {..._diagnosedConditions..remove('none'), value};
      }
    });
    await widget.settings.saveConceiveDiagnosedConditions(_diagnosedConditions.toList());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (_loading) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('💗', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.conceiveIntakeTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s.conceiveIntakeSubtitle,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Pregunta 1: fecha objetivo.
              Text(
                s.conceiveIntakeTargetDateQuestion,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTargetDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18, color: AppColors.ovulation),
                      const SizedBox(width: 10),
                      Text(
                        _targetDate != null
                            ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                            : s.conceiveIntakePickDate,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _targetDate != null ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pregunta 2: tiempo intentándolo.
              Text(
                s.conceiveIntakeDurationQuestion,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('<3m', s.conceiveDurationUnder3),
                  ('3-6m', s.conceiveDuration3to6),
                  ('6-12m', s.conceiveDuration6to12),
                  ('12m+', s.conceiveDurationOver12),
                ].map((o) {
                  final selected = _tryingDuration == o.$1;
                  return ChoiceChip(
                    label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => _selectDuration(o.$1),
                    selectedColor: AppColors.ovulation,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: AppColors.background,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Pregunta 3: ciclo irregular — lee/escribe el MISMO
              // interruptor que ya existe en Configuración
              // (SettingsService.loadIrregularCycleMode/
              // saveIrregularCycleMode), solo preguntado aquí también
              // para no obligar a ir a buscarlo por separado. Mismo estilo
              // de interruptor "tipo iOS" que ya usa ReminderScreen
              // (pista verde/gris clara, pulgar blanco, sin contorno) en
              // vez del switch de Material por defecto, para que se vea
              // igual en toda la app.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.conceiveIntakeIrregularQuestion,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _irregularCycle,
                      onChanged: _toggleIrregular,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF34C759),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFE9E9EB),
                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pregunta 4: anticoncepción reciente.
              Text(
                s.conceiveIntakeContraceptionQuestion,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _yesNoChip(
                      label: s.conceiveYes,
                      selected: _recentContraception == true,
                      onTap: () => _selectContraception(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _yesNoChip(
                      label: s.conceiveNo,
                      selected: _recentContraception == false,
                      onTap: () => _selectContraception(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pregunta 5: duración promedio del ciclo — respaldo para
              // CyclePredictor.getAvgCycleLength() mientras no hay
              // suficientes periodos registrados todavía (ver
              // selfReportedCycleLen), para que el cálculo sea más exacto
              // desde el primer día en vez de asumir 28 días por defecto.
              Text(
                s.conceiveIntakeCycleLengthQuestion,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              _stepperRow(
                value: _avgCycleLen,
                unit: s.conceiveIntakeDaysUnit,
                onDecrement: () => _changeCycleLen(-1),
                onIncrement: () => _changeCycleLen(1),
              ),
              const SizedBox(height: 20),

              // Pregunta 6: duración promedio del periodo — mismo respaldo
              // pero para CyclePredictor.getAvgPeriodLength().
              Text(
                s.conceiveIntakePeriodLengthQuestion,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              _stepperRow(
                value: _avgPeriodLen,
                unit: s.conceiveIntakeDaysUnit,
                onDecrement: () => _changePeriodLen(-1),
                onIncrement: () => _changePeriodLen(1),
              ),
              const SizedBox(height: 20),

              // Pregunta 7: uso de tests de ovulación (OPK) — por ahora solo
              // informativa, no alimenta ningún cálculo todavía.
              Text(
                s.conceiveIntakeOvulationTestsQuestion,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _yesNoChip(
                      label: s.conceiveYes,
                      selected: _usesOvulationTests == true,
                      onTap: () => _selectUsesOvulationTests(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _yesNoChip(
                      label: s.conceiveNo,
                      selected: _usesOvulationTests == false,
                      onTap: () => _selectUsesOvulationTests(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pregunta 8: condiciones diagnosticadas que afectan el ciclo
              // — también informativa por ahora; "Ninguna" es excluyente
              // con el resto (ver _toggleCondition).
              Text(
                s.conceiveIntakeConditionsQuestion,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('pcos', s.conceiveConditionPcos),
                  ('endometriosis', s.conceiveConditionEndometriosis),
                  ('thyroid', s.conceiveConditionThyroid),
                  ('other', s.conceiveConditionOther),
                  ('none', s.conceiveConditionNone),
                ].map((o) {
                  final selected = _diagnosedConditions.contains(o.$1);
                  return ChoiceChip(
                    label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => _toggleCondition(o.$1),
                    selectedColor: AppColors.ovulation,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: AppColors.background,
                  );
                }).toList(),
              ),
              if (_diagnosedConditions.isNotEmpty && !_diagnosedConditions.contains('none')) ...[
                const SizedBox(height: 6),
                Text(
                  s.conceiveIntakeConditionsNote,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ovulation,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(s.reminderTimeSheetDone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yesNoChip({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ovulation : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.ovulation : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }

  /// Control "-  N días  +" para las preguntas de duración de ciclo/periodo
  /// — más rápido de responder con precisión que escribir un número, y
  /// evita valores fuera de rango gracias al clamp ya aplicado en
  /// _changeCycleLen/_changePeriodLen.
  Widget _stepperRow({
    required int value,
    required String unit,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _stepperButton(icon: Icons.remove, onTap: onDecrement),
          Expanded(
            child: Center(
              child: Text(
                '$value $unit',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ),
          _stepperButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: AppColors.ovulation),
      ),
    );
  }
}
