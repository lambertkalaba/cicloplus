import 'package:flutter/material.dart';

import 'ui.dart';

/// Colores del calendario de CicloPlus, también usados como tema global
/// para cualquier selector de fecha del sistema que quede en la app.
DatePickerThemeData cicloDatePickerTheme() {
  final pink = C.pink;
  return DatePickerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    headerBackgroundColor: const Color(0xFF187A4C),
    headerForegroundColor: Colors.white,
    weekdayStyle: TextStyle(color: pink, fontWeight: FontWeight.w800),
    dayStyle: const TextStyle(fontWeight: FontWeight.w600),
    dayForegroundColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.selected)) return Colors.white;
      if (s.contains(WidgetState.disabled)) return const Color(0xFFC9BFC4);
      return const Color(0xFF3A2F35);
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? pink : null),
    dayOverlayColor: WidgetStateProperty.all(pink.withValues(alpha: 0.10)),
    todayForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : pink),
    todayBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? pink : null),
    todayBorder: BorderSide(color: pink, width: 1.4),
    yearForegroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : const Color(0xFF3A2F35)),
    yearBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? pink : null),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: pink),
    confirmButtonStyle: TextButton.styleFrom(foregroundColor: pink),
    dividerColor: Colors.transparent,
  );
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

/// Selector de fecha con el estilo de CicloPlus (diseño hecho con ChatGPT):
/// cabecera verde con hojas y flores, la fecha grande, el día elegido en un
/// círculo rosa y el botón "Aceptar" en una pastilla rosa.
/// Mismos parámetros que showDatePicker (los que usa la app).
Future<DateTime?> showCicloDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  var init = DateUtils.dateOnly(initialDate);
  if (init.isBefore(firstDate)) init = DateUtils.dateOnly(firstDate);
  if (init.isAfter(lastDate)) init = DateUtils.dateOnly(lastDate);
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _CicloDateDialog(initial: init, first: firstDate, last: lastDate, helpText: helpText),
  );
}

class _CicloDateDialog extends StatefulWidget {
  const _CicloDateDialog({required this.initial, required this.first, required this.last, this.helpText});
  final DateTime initial, first, last;
  final String? helpText;

  @override
  State<_CicloDateDialog> createState() => _CicloDateDialogState();
}

class _CicloDateDialogState extends State<_CicloDateDialog> {
  late DateTime _sel = widget.initial;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final base = Theme.of(context);
    final pink = C.pink;
    final size = MediaQuery.of(context).size;
    final w = size.width.clamp(0.0, 380.0) - 32;
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
              // Cabecera verde con hojas y flores
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
                          child: Text(loc.formatMediumDate(_sel),
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
              Theme(
                data: base.copyWith(
                  colorScheme: base.colorScheme.copyWith(primary: pink, onPrimary: Colors.white, onSurface: const Color(0xFF3A2F35)),
                  datePickerTheme: cicloDatePickerTheme(),
                ),
                child: SizedBox(
                  height: 330,
                  child: CalendarDatePicker(
                    initialDate: _sel,
                    firstDate: widget.first,
                    lastDate: widget.last,
                    onDateChanged: (d) => setState(() => _sel = d),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: pink),
                    child: Text(_cap(loc.cancelButtonLabel), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_sel),
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
