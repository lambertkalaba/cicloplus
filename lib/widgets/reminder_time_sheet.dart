import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../services/locale_controller.dart';
import '../theme/app_theme.dart';

/// Bottom sheet reutilizable para TODOS los interruptores de recordatorio
/// de ReminderScreen: al activarse un switch, en vez de guardar solo un
/// booleano "a ciegas", este sheet se abre YA PRECARGADO con un valor por
/// defecto inteligente (calculado por el llamador a partir de
/// CyclePredictor) y deja que la usuaria lo confirme tal cual (tocando
/// "Guardar") o lo ajuste antes de confirmar.
///
/// Dos modos, según lo que reciba:
/// - `initialDate` no nulo (con `initialTime`): selector de FECHA + HORA
///   completo — usado por Inicio/Fin de período, Introducir período,
///   Ventana fértil y Ovulación (todos ligados a una fecha calculada del
///   ciclo).
/// - `initialDate` nulo: selector de SOLO HORA (recurrente diaria) — usado
///   por "Recuerda beber agua" (reutiliza DailyTimeReminderSettings) y,
///   opcionalmente, por Fase del ciclo/Autoexamen si el llamador decide no
///   pasar fecha.
///
/// Sigue el patrón visual ya usado en el resto de la app (ver
/// SettingsScreen._openPredictionConfigSheet, CalendarScreen._onDayTap):
/// fondo blanco, esquinas superiores redondeadas, franja superior
/// ("handle"), y un botón "Guardar" ancho tipo pill con el color del tema
/// activo.
class ReminderTimeSheet extends StatefulWidget {
  final String title;
  final String? hint;

  /// Icono + color de fondo de la tarjeta que encabeza el sheet — mismo
  /// par usado por la fila correspondiente en ReminderScreen (ver
  /// `_iosRow`), para que el icono coincida entre la lista y el sheet que
  /// abre. Rediseño aprobado en Claude Visualize (2026-08-16): antes el
  /// encabezado era solo texto plano sin icono.
  final IconData icon;
  final Color iconColor;

  /// Fecha inicial sugerida (ya calculada por el llamador). Si es null, el
  /// sheet se muestra en modo "solo hora" (recordatorio diario recurrente).
  final DateTime? initialDate;
  final TimeOfDay initialTime;

  /// Si no-nulo, muestra además un selector "días antes de la fecha
  /// calculada" (usado por "Se aproxima periodo fértil") — el valor
  /// representa la antelación actual en días, y `onDaysBeforeChanged`
  /// recalcula `initialDate` cuando cambia.
  final int? daysBefore;
  final ValueChanged<int>? onDaysBeforeChanged;

  final Color primary;
  final ValueChanged<DateTime> onConfirmDateTime;
  final ValueChanged<TimeOfDay> onConfirmTimeOnly;

  const ReminderTimeSheet({
    super.key,
    required this.title,
    this.hint,
    required this.icon,
    required this.iconColor,
    this.initialDate,
    required this.initialTime,
    this.daysBefore,
    this.onDaysBeforeChanged,
    required this.primary,
    required this.onConfirmDateTime,
    required this.onConfirmTimeOnly,
  });

  /// Abre el sheet en modo fecha+hora. [initialDate] debe venir ya
  /// calculado por el llamador (nunca se recalcula dentro del sheet, para
  /// que la lógica de predicción viva en un solo sitio: CyclePredictor).
  static Future<void> showDateTime({
    required BuildContext context,
    required String title,
    String? hint,
    IconData icon = Icons.notifications,
    Color? iconColor,
    required DateTime initialDate,
    required TimeOfDay initialTime,
    int? daysBefore,
    ValueChanged<int>? onDaysBeforeChanged,
    required Color primary,
    required ValueChanged<DateTime> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ReminderTimeSheet(
        title: title,
        hint: hint,
        icon: icon,
        iconColor: iconColor ?? primary,
        initialDate: initialDate,
        initialTime: initialTime,
        daysBefore: daysBefore,
        onDaysBeforeChanged: onDaysBeforeChanged,
        primary: primary,
        onConfirmDateTime: onConfirm,
        onConfirmTimeOnly: (_) {},
      ),
    );
  }

  /// Abre el sheet en modo solo-hora (recordatorio diario recurrente, ej.
  /// "Recuerda beber agua").
  static Future<void> showTimeOnly({
    required BuildContext context,
    required String title,
    String? hint,
    IconData icon = Icons.notifications,
    Color? iconColor,
    required TimeOfDay initialTime,
    required Color primary,
    required ValueChanged<TimeOfDay> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ReminderTimeSheet(
        title: title,
        hint: hint,
        icon: icon,
        iconColor: iconColor ?? primary,
        initialDate: null,
        initialTime: initialTime,
        primary: primary,
        onConfirmDateTime: (_) {},
        onConfirmTimeOnly: onConfirm,
      ),
    );
  }

  @override
  State<ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends State<ReminderTimeSheet> {
  late DateTime? _date;
  late TimeOfDay _time;
  late int? _daysBefore;
  bool _use24h = false;

  bool get _isDateMode => widget.initialDate != null;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _time = widget.initialTime;
    _daysBefore = widget.daysBefore;
    _Use24hPref.load().then((value) {
      if (mounted) setState(() => _use24h = value);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await ReminderDatePickerSheet.show(
      context: context,
      initialDate: _date ?? now,
      // firstDate en el pasado reciente (no `now`) para no bloquear el
      // ajuste manual si la fecha sugerida por CyclePredictor cayera unos
      // días atrás (ciclo corto/irregular) — la propia programación de la
      // notificación ya ignora fechas pasadas más adelante.
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: DateTime(now.year + 2),
      primary: widget.iconColor,
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      // Al cambiar la fecha a mano, ya no tiene sentido mantener un
      // "días antes" derivado de la fecha calculada original.
      _daysBefore = null;
    });
  }

  /// Reemplaza el showTimePicker nativo de Material (reloj analógico gris,
  /// "Select time" en inglés — desentonaba con el rediseño iOS aprobado)
  /// por ReminderTimePickerSheet, un selector propio con carretes de hora/minuto
  /// y un interruptor 12h/24h. Rediseño aprobado en Claude Visualize
  /// (2026-08-16).
  Future<void> _pickTime() async {
    final picked = await ReminderTimePickerSheet.show(
      context: context,
      initialTime: _time,
      primary: widget.primary,
    );
    if (picked == null) return;
    setState(() => _time = picked);
  }

  void _changeDaysBefore(int days) {
    setState(() => _daysBefore = days);
    widget.onDaysBeforeChanged?.call(days);
  }

  void _confirm() {
    if (_isDateMode) {
      final base = _date ?? widget.initialDate!;
      widget.onConfirmDateTime(DateTime(base.year, base.month, base.day, _time.hour, _time.minute));
    } else {
      widget.onConfirmTimeOnly(_time);
    }
    Navigator.of(context).pop();
  }

  // ---- Nombres de mes localizados (solo para el formato largo "13 de
  // agosto, 2026" del rediseño — no hacía falta antes porque el formato
  // viejo era numérico puro "13/08/2026"). No vive en AppStrings porque es
  // formato de fecha, no una cadena de UI independiente.
  static const Map<String, List<String>> _months = {
    'es': ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'],
    'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'fr': ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
    'de': ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'],
  };

  String _formatDateLong(DateTime d, String languageCode) {
    final months = _months[languageCode] ?? _months['en']!;
    final month = months[d.month - 1];
    switch (languageCode) {
      case 'es':
        return '${d.day} de $month, ${d.year}';
      case 'fr':
        return '${d.day} $month ${d.year}';
      case 'de':
        return '${d.day}. $month ${d.year}';
      default:
        return '$month ${d.day}, ${d.year}';
    }
  }

  String _formatTimeLong(TimeOfDay t) {
    if (_use24h) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:${t.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    // Idioma ACTIVO de la app (elegido en Configuración vía LocaleController),
    // no el locale del sistema operativo — Localizations.localeOf(context)
    // devolvía el idioma del dispositivo porque MaterialApp no declara
    // supportedLocales/locale (AppStrings es un sistema de i18n propio, no
    // el de Flutter), así que el formato largo de fecha salía en inglés
    // aunque la app estuviera en español.
    final lang = LocaleController.instance.languageCode;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFD1D1D6), borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: widget.iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(widget.icon, size: 22, color: widget.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.hint ?? (_isDateMode ? s.reminderTimeSheetSuggestedHint : s.reminderTimeSheetSuggestedHintTimeOnly),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (_daysBefore != null) ...[
            Text(
              s.reminderDaysBeforeLabel.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93), letterSpacing: 0.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF7F7F9), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _StepperButton(icon: Icons.remove, onTap: () => _changeDaysBefore((_daysBefore! - 1).clamp(1, 14)), color: widget.iconColor),
                  Expanded(
                    child: Center(
                      child: Text('${_daysBefore!}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                    ),
                  ),
                  _StepperButton(icon: Icons.add, onTap: () => _changeDaysBefore((_daysBefore! + 1).clamp(1, 14)), color: widget.iconColor),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_isDateMode) ...[
            Text(
              s.reminderTimeSheetDateLabel.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93), letterSpacing: 0.4),
            ),
            const SizedBox(height: 8),
            _pickerRow(
              icon: Icons.calendar_today_outlined,
              label: _formatDateLong(_date ?? widget.initialDate!, lang),
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),
          ],
          Text(
            s.reminderTimeSheetTimeLabel.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93), letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          _pickerRow(icon: Icons.access_time, label: _formatTimeLong(_time), onTap: _pickTime),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                s.reminderTimeSheetSave,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF8E8E93), padding: const EdgeInsets.symmetric(vertical: 10)),
              child: Text(s.cancel, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF7F7F9), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 19, color: widget.iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
            ),
            const Icon(Icons.chevron_right, size: 17, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _StepperButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

/// Preferencia global "usar formato 24h" para ReminderTimePickerSheet — persistida
/// en SharedPreferences directamente (no vía SettingsService) porque es
/// puramente una preferencia de presentación del selector, no un dato del
/// ciclo/perfil. Se comparte entre todas las instancias del sheet: si la
/// usuaria elige 24h una vez, el resto de recordatorios que abra después ya
/// respetan esa elección sin tener que repetirla.
class _Use24hPref {
  static const _key = 'reminder_time_sheet_use_24h';

  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> save(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// Selector de hora propio que reemplaza showTimePicker (Material nativo,
/// reloj analógico + "Select time" en inglés — desentonaba con el
/// rediseño iOS). Diseño aprobado en Claude Visualize (2026-08-16): dos
/// carretes verticales (hora / minuto) con el valor central resaltado en
/// el color de acento y los vecinos atenuados, más un interruptor 12h/24h
/// arriba — en 12h aparece además un selector AM/PM; en 24h el carrete de
/// horas cubre 00-23 y no hay AM/PM.
class ReminderTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final Color primary;

  const ReminderTimePickerSheet({required this.initialTime, required this.primary});

  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
    required Color primary,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => ReminderTimePickerSheet(initialTime: initialTime, primary: primary),
    );
  }

  @override
  State<ReminderTimePickerSheet> createState() => ReminderTimePickerSheetState();
}

class ReminderTimePickerSheetState extends State<ReminderTimePickerSheet> {
  static const double _itemExtent = 40;

  late bool _use24h;
  late int _hour24; // 0-23, siempre la fuente de verdad internamente
  late int _minute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _use24h = false;
    _hour24 = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _displayHour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _Use24hPref.load().then((value) {
      if (!mounted || value == _use24h) return;
      setState(() {
        _use24h = value;
        // Re-centrar el carrete de horas: el índice cambia de significado
        // entre modos (12h muestra 1-12, 24h muestra 0-23).
        _hourController.jumpToItem(_displayHour);
      });
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  bool get _isAm => _hour24 < 12;

  /// Índice mostrado en el carrete de horas: en 24h es directamente
  /// _hour24 (0-23); en 12h es la hora de 12 horas menos 1 (para que el
  /// índice 0 del carrete sea "1", ya que ListWheelScrollView siempre
  /// empieza en 0).
  int get _displayHour {
    if (_use24h) return _hour24;
    final h12 = _hour24 % 12 == 0 ? 12 : _hour24 % 12;
    return h12 - 1;
  }

  void _onHourWheelChanged(int index) {
    setState(() {
      if (_use24h) {
        _hour24 = index;
      } else {
        final h12 = index + 1; // 1-12
        final isPm = !_isAm;
        _hour24 = h12 == 12 ? (isPm ? 12 : 0) : (isPm ? h12 + 12 : h12);
      }
    });
  }

  void _toggleFormat(bool use24h) {
    if (use24h == _use24h) return;
    setState(() => _use24h = use24h);
    _Use24hPref.save(use24h);
    _hourController.jumpToItem(_displayHour);
  }

  void _togglePeriod(bool am) {
    if (am == _isAm) return;
    setState(() => _hour24 = am ? _hour24 - 12 : _hour24 + 12);
  }

  void _confirm() {
    Navigator.of(context).pop(TimeOfDay(hour: _hour24, minute: _minute));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final hourCount = _use24h ? 24 : 12;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: const Color(0xFFD1D1D6), borderRadius: BorderRadius.circular(3)),
          ),
          Text(
            s.reminderTimeSheetPickTimeTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          const SizedBox(height: 16),
          // Interruptor 12h/24h — segmented control estilo iOS.
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: const Color(0xFFF7F7F9), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormatChip(label: s.reminderTimeSheet12h, selected: !_use24h, onTap: () => _toggleFormat(false)),
                _FormatChip(label: s.reminderTimeSheet24h, selected: _use24h, onTap: () => _toggleFormat(true)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: _itemExtent * 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _wheelColumn(
                  controller: _hourController,
                  itemCount: hourCount,
                  labelBuilder: (i) => (_use24h ? i : i + 1).toString().padLeft(2, '0'),
                  onChanged: _onHourWheelChanged,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(':', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.85))),
                ),
                _wheelColumn(
                  controller: _minuteController,
                  itemCount: 60,
                  labelBuilder: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (i) => setState(() => _minute = i),
                ),
                if (!_use24h) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF7F7F9), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PeriodChip(label: 'AM', selected: _isAm, color: widget.primary, onTap: () => _togglePeriod(true)),
                        const SizedBox(height: 4),
                        _PeriodChip(label: 'PM', selected: !_isAm, color: widget.primary, onTap: () => _togglePeriod(false)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(s.reminderTimeSheetDone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF8E8E93), padding: const EdgeInsets.symmetric(vertical: 10)),
              child: Text(s.cancel, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheelColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      width: 76,
      decoration: BoxDecoration(color: const Color(0xFFF7F7F9), borderRadius: BorderRadius.circular(16)),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        perspective: 0.003,
        diameterRatio: 1.3,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final selectedIndex = controller.hasClients && controller.positions.isNotEmpty
                    ? (controller.selectedItem)
                    : index;
                final isSelected = index == selectedIndex;
                return Center(
                  child: Text(
                    labelBuilder(index),
                    style: TextStyle(
                      fontSize: isSelected ? 28 : 15,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? widget.primary : const Color(0xFFC7C7CC),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Selector de fecha propio con ruedas día/mes/año, mismo lenguaje visual
/// que ReminderTimePickerSheet — reemplaza el showDatePicker nativo de
/// Material (calendario genérico rosa claro) usado antes en _pickDate() y
/// en el flujo de "Nueva cita médica". Rediseño aprobado en Claude
/// Visualize (2026-08-16).
class ReminderDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color primary;

  const ReminderDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.primary,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required Color primary,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => ReminderDatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        primary: primary,
      ),
    );
  }

  @override
  State<ReminderDatePickerSheet> createState() => _ReminderDatePickerSheetState();
}

class _ReminderDatePickerSheetState extends State<ReminderDatePickerSheet> {
  static const double _itemExtent = 40;
  static const _monthsShort = {
    'es': ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'],
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'fr': ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'],
    'de': ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'],
  };

  late int _year; // índice absoluto de año (no de wheel)
  late int _month; // 1-12
  late int _day; // 1-31

  late List<int> _years;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
    _years = [for (var y = widget.firstDate.year; y <= widget.lastDate.year; y++) y];
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(initialItem: _years.indexOf(_year));
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  void _clampDay() {
    if (_day > _daysInMonth) {
      _day = _daysInMonth;
      _dayController.jumpToItem(_day - 1);
    }
  }

  void _confirm() {
    final clamped = DateTime(_year, _month, _day);
    final result = clamped.isBefore(widget.firstDate)
        ? widget.firstDate
        : (clamped.isAfter(widget.lastDate) ? widget.lastDate : clamped);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lang = LocaleController.instance.languageCode;
    final months = _monthsShort[lang] ?? _monthsShort['en']!;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: const Color(0xFFD1D1D6), borderRadius: BorderRadius.circular(3)),
          ),
          Text(
            s.reminderDateSheetPickDateTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: _itemExtent * 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _wheelColumn(
                  width: 56,
                  controller: _dayController,
                  itemCount: 31,
                  labelBuilder: (i) => '${i + 1}',
                  onChanged: (i) => setState(() {
                    _day = i + 1;
                  }),
                ),
                const SizedBox(width: 6),
                _wheelColumn(
                  width: 84,
                  controller: _monthController,
                  itemCount: 12,
                  labelBuilder: (i) => months[i],
                  onChanged: (i) => setState(() {
                    _month = i + 1;
                    _clampDay();
                  }),
                ),
                const SizedBox(width: 6),
                _wheelColumn(
                  width: 76,
                  controller: _yearController,
                  itemCount: _years.length,
                  labelBuilder: (i) => '${_years[i]}',
                  onChanged: (i) => setState(() {
                    _year = _years[i];
                    _clampDay();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(s.reminderTimeSheetDone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF8E8E93), padding: const EdgeInsets.symmetric(vertical: 10)),
              child: Text(s.cancel, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheelColumn({
    required double width,
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(color: const Color(0xFFF7F7F9), borderRadius: BorderRadius.circular(16)),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        perspective: 0.003,
        diameterRatio: 1.3,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final selectedIndex = controller.hasClients && controller.positions.isNotEmpty
                    ? (controller.selectedItem)
                    : index;
                final isSelected = index == selectedIndex;
                return Center(
                  child: Text(
                    labelBuilder(index),
                    style: TextStyle(
                      fontSize: isSelected ? 20 : 15,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? widget.primary : const Color(0xFFC7C7CC),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 3, offset: const Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.black : const Color(0xFF8E8E93)),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: selected ? color : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF8E8E93)),
        ),
      ),
    );
  }
}
