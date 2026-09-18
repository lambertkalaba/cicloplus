import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/daily_notification_service.dart';
import '../services/partner_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'pregnancy_tracking_screen.dart';
import 'reminder_screen.dart';

/// Las 4 secciones de "Mi salud", usadas para poder abrir HealthMenuScreen
/// mostrando solo una de ellas (ver [HealthMenuScreen.section]) — es lo
/// que usa el Drawer lateral, cuyas 4 filas llevan cada una a su propia
/// sección en vez de a las 4 juntas.
enum HealthMenuSection { profile, reminder, pill, pregnancy, appointments }

/// Pestaña "Salud": agrupa las secciones de Configuración que no encajan
/// bien mezcladas con ajustes generales, en este orden — mi perfil (solo
/// lectura: nombre, talla, peso de referencia — para editarlos hay que ir
/// a Configuración > Datos), recordatorio de anticonceptivo, modo
/// embarazo, citas médicas.
///
/// Vive en dos sitios a la vez: embebida como 4ª pestaña en
/// MainTabScreen mostrando las 4 secciones juntas ([section] = null), y
/// también accesible desde el Drawer lateral (icono ❤️ del header), donde
/// cada una de sus 4 filas abre esta misma pantalla pero con [section]
/// fijado a una sola sección — así se evita duplicar la lógica de
/// carga/guardado en dos widgets distintos.
class HealthMenuScreen extends StatefulWidget {
  final String userId;
  final HealthMenuSection? section;

  // Id del tema de color elegido en Configuración — usado en el switch
  // de "Modo embarazo" para que siga el color de app actual en vez del
  // rosa fijo de AppColors.primary.
  final String themeId;

  // Estado y callbacks del recordatorio de periodo/ovulación/días
  // fértiles — el dueño real de este estado sigue siendo MainTabScreen
  // (necesita _data e _irregularCycleMode para calcular las fechas), así
  // que aquí solo se recibe todo ya armado para abrir ReminderScreen.
  final ReminderSettings reminderSettings;
  final bool hasPeriodPrediction;
  final ValueChanged<bool> onReminderToggle;
  final ValueChanged<int> onReminderDaysChanged;
  final ValueChanged<bool> onOvulationReminderToggle;
  final ValueChanged<bool> onFertileReminderToggle;

  const HealthMenuScreen({
    super.key,
    required this.userId,
    this.section,
    this.themeId = 'pink',
    required this.reminderSettings,
    required this.hasPeriodPrediction,
    required this.onReminderToggle,
    required this.onReminderDaysChanged,
    required this.onOvulationReminderToggle,
    required this.onFertileReminderToggle,
  });

  @override
  State<HealthMenuScreen> createState() => _HealthMenuScreenState();
}

class _HealthMenuScreenState extends State<HealthMenuScreen> {
  final SettingsService _settings = SettingsService();
  final DailyNotificationService _dailyNotifications = DailyNotificationService();

  PregnancySettings _pregnancy = const PregnancySettings();
  DailyTimeReminderSettings _pillReminder = const DailyTimeReminderSettings(time: '08:00');
  List<MedicalAppointment> _appointments = [];
  // Perfil: solo lectura aquí (se edita en Configuración > Datos), así
  // que basta con guardar los valores planos, sin TextEditingController.
  String? _profileName;
  double? _heightCm;
  double? _referenceWeight;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pregnancy = await _settings.loadPregnancySettings();
    final pill = await _settings.loadPillReminderSettings();
    final heightCm = await _settings.loadHeightCm();
    final appointments = await _settings.loadMedicalAppointments();
    final name = await _settings.loadProfileName();
    final referenceWeight = await _settings.loadProfileReferenceWeight();
    if (!mounted) return;
    setState(() {
      _pregnancy = pregnancy;
      _pillReminder = pill;
      _heightCm = heightCm;
      _appointments = appointments;
      _profileName = name;
      _referenceWeight = referenceWeight;
      _loading = false;
    });
  }

  Future<void> _togglePregnancy(bool value) async {
    final updated = _pregnancy.copyWith(enabled: value);
    setState(() => _pregnancy = updated);
    await _settings.savePregnancySettings(updated);
    PartnerService().syncPregnancyData(widget.userId);
  }

  Future<void> _pickLmpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pregnancy.lmp ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null) return;
    final updated = _pregnancy.copyWith(lmp: picked);
    setState(() => _pregnancy = updated);
    await _settings.savePregnancySettings(updated);
    PartnerService().syncPregnancyData(widget.userId);
  }

  Future<void> _togglePillReminder(bool value) async {
    final updated = _pillReminder.copyWith(enabled: value);
    setState(() => _pillReminder = updated);
    await _settings.savePillReminderSettings(updated);
    if (value) await _dailyNotifications.requestPermissions();
    await _dailyNotifications.reschedulePillReminder(updated);
  }

  Future<void> _pickPillReminderTime() async {
    final parts = _pillReminder.time.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updated = _pillReminder.copyWith(time: time);
    setState(() => _pillReminder = updated);
    await _settings.savePillReminderSettings(updated);
    await _dailyNotifications.reschedulePillReminder(updated);
  }

  /// Mismas opciones predefinidas que day_editor.dart
  /// (_appointmentTypeOptions), replicadas aquí para que el diálogo de
  /// Configuración sea idéntico al que se abre desde un día futuro del
  /// calendario — misma lista, mismo orden, misma opción "Otro" con texto
  /// libre al final.
  List<String Function(AppStrings)> get _appointmentTypeOptions => [
        (s) => s.appointmentTypeGyno,
        (s) => s.appointmentTypeCheckup,
        (s) => s.appointmentTypeBloodTest,
        (s) => s.appointmentTypeUltrasound,
        (s) => s.appointmentTypeMidwife,
        (s) => s.appointmentTypeOther,
      ];

  Future<void> _addAppointment() async {
    final s = AppStrings.of(context);
    final otherController = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    int? selectedIndex;
    final options = _appointmentTypeOptions;
    final otherIndex = options.length - 1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final isOtherSelected = selectedIndex == otherIndex;
            final labelReady = selectedIndex != null &&
                (!isOtherSelected || otherController.text.trim().isNotEmpty);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(s.settingsAppointmentDialogTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.appointmentTypeSectionLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedIndex,
                          hint: Text(s.appointmentTypeSectionLabel, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                          items: List.generate(
                            options.length,
                            (i) => DropdownMenuItem<int>(
                              value: i,
                              child: Text(options[i](s), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            ),
                          ),
                          onChanged: (value) => setDialogState(() => selectedIndex = value),
                        ),
                      ),
                    ),
                    if (isOtherSelected) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: otherController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(hintText: s.appointmentTypeOtherHint),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: pickedDate ?? now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 3),
                        );
                        if (date == null) return;
                        if (!dialogContext.mounted) return;
                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: pickedTime ?? TimeOfDay.now(),
                        );
                        if (time == null) return;
                        setDialogState(() {
                          pickedDate = date;
                          pickedTime = time;
                        });
                      },
                      child: Text(
                        pickedDate == null || pickedTime == null
                            ? s.settingsAppointmentPickDate
                            : '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year} · ${pickedTime!.hour.toString().padLeft(2, '0')}:${pickedTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(s.cancel)),
                TextButton(
                  onPressed: !labelReady || pickedDate == null || pickedTime == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: Text(s.settingsAppointmentSave),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || pickedDate == null || pickedTime == null) return;
    final isOtherSelected = selectedIndex == otherIndex;
    final label = isOtherSelected ? otherController.text.trim() : options[selectedIndex!](s);
    final picked = DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      pickedTime!.hour,
      pickedTime!.minute,
    );
    final appointment = MedicalAppointment(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      dateTime: picked,
    );
    final updated = [..._appointments, appointment];
    setState(() => _appointments = updated);
    await _settings.saveMedicalAppointments(updated);
    await _dailyNotifications.requestPermissions();
    await _dailyNotifications.scheduleAppointment(appointment);
  }

  Future<void> _deleteAppointment(MedicalAppointment appointment) async {
    final updated = _appointments.where((a) => a.id != appointment.id).toList();
    setState(() => _appointments = updated);
    await _settings.saveMedicalAppointments(updated);
    await _dailyNotifications.cancelAppointment(appointment.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final s = AppStrings.of(context);
    final section = widget.section;

    // Sin sección fijada (embebida como 4ª pestaña): se muestran las 4
    // juntas, con el título general arriba. Con sección fijada (abierta
    // desde una fila del Drawer): se muestra solo ese bloque.
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (section == null) ...[
          Text(s.healthMenuTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
        ],
        if (section == null || section == HealthMenuSection.profile) ...[
          ..._buildProfileSection(s),
          if (section == null) const SizedBox(height: 24),
        ],
        if (section == null || section == HealthMenuSection.reminder) ...[
          ..._buildReminderSection(s),
          if (section == null) const SizedBox(height: 24),
        ],
        if (section == null || section == HealthMenuSection.pill) ...[
          ..._buildPillSection(s),
          if (section == null) const SizedBox(height: 24),
        ],
        if (section == null || section == HealthMenuSection.pregnancy) ...[
          ..._buildPregnancySection(s),
          if (section == null) const SizedBox(height: 24),
        ],
        if (section == null || section == HealthMenuSection.appointments) ...[
          ..._buildAppointmentsSection(s),
        ],
      ],
    );
  }

  List<Widget> _buildProfileSection(AppStrings s) => [
        _sectionTitle(s.settingsProfileTitle),
        const SizedBox(height: 4),
        Text(s.settingsDataHint, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 10),
        _readOnlyRow(
          label: s.profileNameLabel,
          value: (_profileName == null || _profileName!.isEmpty) ? s.profileNotSet : _profileName!,
        ),
        const SizedBox(height: 8),
        _readOnlyRow(
          label: s.settingsHeightLabel,
          value: _heightCm != null ? '${_heightCm!.toStringAsFixed(0)} cm' : s.profileNotSet,
        ),
        const SizedBox(height: 8),
        _readOnlyRow(
          label: s.profileReferenceWeightLabel,
          value: _referenceWeight != null ? '${_referenceWeight!.toStringAsFixed(1)} kg' : s.profileNotSet,
        ),
      ];

  /// Fila que abre la pantalla "Obtener Recordatorio" (rediseño con fondo
  /// degradado y 3 interruptores: Periodo, Ovulación, Días fértiles). El
  /// recordatorio en sí vivía antes como tarjeta compacta en la pantalla
  /// de Inicio; ahora solo tiene este acceso desde Mi salud.
  List<Widget> _buildReminderSection(AppStrings s) => [
        _sectionTitle(s.reminderTitle),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReminderScreen(
                settings: widget.reminderSettings,
                hasPrediction: widget.hasPeriodPrediction,
                onPeriodToggle: widget.onReminderToggle,
                onDaysChanged: widget.onReminderDaysChanged,
                onOvulationToggle: widget.onOvulationReminderToggle,
                onFertileToggle: widget.onFertileReminderToggle,
                themeId: widget.themeId,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: Color(themeById(widget.themeId).primary)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.reminderScreenEntry,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ];

  List<Widget> _buildPillSection(AppStrings s) => [
        _sectionTitle(s.settingsPillTitle),
        const SizedBox(height: 4),
        _switchRow(
          title: s.settingsPillToggle,
          subtitle: _pillReminder.enabled ? s.settingsActiveAt(_pillReminder.time) : s.off_,
          value: _pillReminder.enabled,
          onChanged: _togglePillReminder,
        ),
        if (_pillReminder.enabled) ...[
          const SizedBox(height: 10),
          _timeRow(label: s.settingsHour, time: _pillReminder.time, onTap: _pickPillReminderTime),
        ],
      ];

  List<Widget> _buildPregnancySection(AppStrings s) => [
        _sectionTitle(s.settingsPregnancyTitle),
        const SizedBox(height: 4),
        _switchRow(
          title: s.settingsPregnancyToggle,
          subtitle: _pregnancy.enabled ? s.on_ : s.off_,
          value: _pregnancy.enabled,
          onChanged: _togglePregnancy,
        ),
        if (_pregnancy.enabled) ...[
          const SizedBox(height: 10),
          _dateRow(
            label: s.settingsLmpLabel,
            value: _pregnancy.lmp,
            chooseLabel: s.settingsChooseDate,
            onTap: _pickLmpDate,
          ),
        ],
        if (_pregnancy.enabled && _pregnancy.lmp != null) ...[
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PregnancyTrackingScreen(lmp: _pregnancy.lmp!, themeId: widget.themeId, isTwins: _pregnancy.isTwins),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.pregnant_woman, color: Color(themeById(widget.themeId).primary)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.pregnancyTrackingEntry,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ];

  List<Widget> _buildAppointmentsSection(AppStrings s) => [
        _sectionTitle(s.settingsAppointmentsTitle),
        const SizedBox(height: 4),
        Text(s.settingsAppointmentsHint, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 10),
        if (_appointments.isEmpty)
          Text(s.settingsAppointmentsEmpty, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
        else
          Column(
            children: _appointments.map((a) {
              final d = a.dateTime;
              final dateLabel =
                  '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(dateLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteAppointment(a),
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                      tooltip: s.settingsAppointmentDelete,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _addAppointment,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primaryLight),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(s.settingsAppointmentAdd, style: const TextStyle(fontSize: 12)),
        ),
      ];

  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        Switch(value: value, activeColor: Color(themeById(widget.themeId).primary), onChanged: onChanged),
      ],
    );
  }

  /// Fila de solo lectura para el perfil (nombre, talla, peso): sin
  /// InkWell ni onTap, porque estos datos ya no se editan desde aquí,
  /// solo desde Configuración > Datos.
  Widget _readOnlyRow({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _dateRow({
    required String label,
    required DateTime? value,
    required String chooseLabel,
    required VoidCallback onTap,
  }) {
    final text = value == null ? chooseLabel : '${value.day}/${value.month}/${value.year}';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _timeRow({required String label, required String time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
