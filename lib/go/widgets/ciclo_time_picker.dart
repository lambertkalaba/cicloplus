import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui.dart';

/// Colores del reloj del sistema que quede en la app (tema global).
TimePickerThemeData cicloTimePickerTheme() {
  final pink = C.pink;
  return TimePickerThemeData(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    hourMinuteColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? pink.withValues(alpha: 0.14) : const Color(0xFFF7EEF2)),
    hourMinuteTextColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? pink : const Color(0xFF3A2F35)),
    dialHandColor: pink,
    dialBackgroundColor: const Color(0xFFFDEFF4),
    dialTextColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : const Color(0xFF3A2F35)),
    dayPeriodColor: pink.withValues(alpha: 0.14),
    dayPeriodTextColor: pink,
    entryModeIconColor: pink,
    helpTextStyle: TextStyle(color: pink, fontWeight: FontWeight.w800),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: pink),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: pink),
  );
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

/// Selector de hora con el estilo de CicloPlus (diseño hecho con ChatGPT):
/// cabecera verde con hojas y flores, la hora grande y dos ruedas (horas y
/// minutos) con la elegida en rosa. En móviles con formato de 12 horas
/// aparece también AM/PM. Mismos parámetros que showTimePicker.
Future<TimeOfDay?> showCicloTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _CicloTimeDialog(initial: initialTime, helpText: helpText),
  );
}

class _CicloTimeDialog extends StatefulWidget {
  const _CicloTimeDialog({required this.initial, this.helpText});
  final TimeOfDay initial;
  final String? helpText;

  @override
  State<_CicloTimeDialog> createState() => _CicloTimeDialogState();
}

class _CicloTimeDialogState extends State<_CicloTimeDialog> {
  late int _h = widget.initial.hour;
  late int _m = widget.initial.minute;
  bool? _h24;
  late FixedExtentScrollController _hc, _mc, _pc;

  static const _rows = 1000; // ruedas "infinitas"

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_h24 != null) return;
    _h24 = MediaQuery.of(context).alwaysUse24HourFormat;
    final hours = _h24! ? 24 : 12;
    final hIndex = _h24! ? _h : (_h % 12);
    _hc = FixedExtentScrollController(initialItem: (_rows ~/ 2) * hours + hIndex);
    _mc = FixedExtentScrollController(initialItem: (_rows ~/ 2) * 60 + _m);
    _pc = FixedExtentScrollController(initialItem: _h >= 12 ? 1 : 0);
  }

  @override
  void dispose() {
    _hc.dispose();
    _mc.dispose();
    _pc.dispose();
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  Widget _wheel({
    required FixedExtentScrollController c,
    required int count,
    required int selected,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    bool loop = true,
    double width = 76,
    bool small = false,
  }) {
    final pink = C.pink;
    return SizedBox(
      width: width,
      height: 200,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          height: 50,
          decoration: BoxDecoration(color: pink.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
        ),
        ListWheelScrollView.useDelegate(
          controller: c,
          itemExtent: 46,
          diameterRatio: 1.6,
          perspective: 0.004,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (i) {
            HapticFeedback.selectionClick();
            onChanged(i % count);
          },
          childDelegate: loop
              ? ListWheelChildBuilderDelegate(
                  childCount: _rows * count,
                  builder: (_, i) => _cell(label(i % count), i % count == selected, small),
                )
              : ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (_, i) => _cell(label(i), i == selected, small),
                ),
        ),
      ]),
    );
  }

  Widget _cell(String t, bool sel, [bool small = false]) => Center(
        child: Text(t,
            maxLines: 1,
            style: TextStyle(
              fontSize: small ? (sel ? 22 : 17) : (sel ? 30 : 21),
              fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
              color: sel ? C.pink : const Color(0xFFB9AEB4),
            )),
      );

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final pink = C.pink;
    final h24 = _h24 ?? true;
    final size = MediaQuery.of(context).size;
    final w = size.width.clamp(0.0, 380.0) - 32;
    final shownHour = h24 ? _two(_h) : _two(_h % 12 == 0 ? 12 : _h % 12);
    final period = _h >= 12 ? loc.postMeridiemAbbreviation : loc.anteMeridiemAbbreviation;
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: w,
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: 104,
                child: Stack(children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B5E3B), Color(0xFF187A4C), Color(0xFF0E6842)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(left: -10, bottom: -6, child: Img('header_flowers', size: 84, fallback: Icons.eco)),
                  Positioned(
                    right: -10,
                    bottom: -6,
                    child: Transform.flip(flipX: true, child: const Img('header_flowers', size: 84, fallback: Icons.eco)),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 70),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (widget.helpText != null)
                          Text(widget.helpText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFFD9F2E3), fontSize: 12.5, fontWeight: FontWeight.w700)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('$shownHour:${_two(_m)}${h24 ? '' : ' $period'}',
                              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _wheel(
                  c: _hc,
                  count: h24 ? 24 : 12,
                  selected: h24 ? _h : _h % 12,
                  label: (i) => h24 ? _two(i) : _two(i == 0 ? 12 : i),
                  onChanged: (i) => setState(() => _h = h24 ? i : (i + (_h >= 12 ? 12 : 0))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(':', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: pink)),
                ),
                _wheel(
                  c: _mc,
                  count: 60,
                  selected: _m,
                  label: _two,
                  onChanged: (i) => setState(() => _m = i),
                ),
                if (!h24) ...[
                  const SizedBox(width: 10),
                  _wheel(
                    c: _pc,
                    count: 2,
                    selected: _h >= 12 ? 1 : 0,
                    loop: false,
                    width: 96,
                    small: true,
                    label: (i) => i == 0 ? loc.anteMeridiemAbbreviation : loc.postMeridiemAbbreviation,
                    onChanged: (i) => setState(() => _h = (_h % 12) + (i == 1 ? 12 : 0)),
                  ),
                ],
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: pink),
                    child: Text(_cap(loc.cancelButtonLabel), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(TimeOfDay(hour: _h, minute: _m)),
                    style: FilledButton.styleFrom(
                      backgroundColor: pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      shape: const StadiumBorder(),
                      elevation: 2,
                    ),
                    child: Text(_cap(loc.okButtonLabel), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
