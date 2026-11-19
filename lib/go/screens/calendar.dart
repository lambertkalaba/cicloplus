import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/settings_service.dart' show SettingsService;
import '../cicloplus_host.dart' show CicloData;
import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'extras.dart';
import 'more.dart';

/// Pestaña Calendario (vista Mes / Año).
class CalendarScreen extends StatefulWidget {
  final void Function([DateTime? day]) onRegister;
  const CalendarScreen({super.key, required this.onRegister});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;
  bool _year = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = dateOnly(now);
    _OvTests.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _shift(int m) =>
      setState(() => _month = DateTime(_month.year, _month.month + m));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('Calendario', 'Calendar'),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: C.text,
                  ),
                ),
              ),
              _Segmented(
                left: tr('Mes', 'Month'),
                right: tr('Año', 'Year'),
                rightSelected: _year,
                onChanged: (v) => setState(() => _year = v),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: card(radius: 12),
                  child: Icon(Icons.bar_chart_rounded, color: C.pink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_year)
            _yearView()
          else ...[
            _monthCard(),
            const SizedBox(height: 12),
            _DayCard(
              day: _selected,
              onEdit: () => widget.onRegister(_selected),
            ),
            const SizedBox(height: 14),
            PinkButton(
              label: tr('Ver análisis del ciclo', 'See cycle analysis'),
              icon: Icons.bar_chart_rounded,
              outlined: true,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AnalysisScreen())),
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthCard() {
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -200) _shift(1);
        if (v > 200) _shift(-1);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: card(),
        child: Column(
          children: [
            Row(
              children: [
                _arrow(Icons.chevron_left_rounded, () => _shift(-1)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: C.t(0xFF6B1F4A),
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${L.monthShort(_month.month).toUpperCase()} ${_month.year}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E6B34),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _arrow(Icons.chevron_right_rounded, () => _shift(1)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() {
                    _month = DateTime(now.year, now.month);
                    _selected = dateOnly(now);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFEAF6E4) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF2E9E4F),
                        width: 1.6,
                      ),
                    ),
                    child: Text(
                      tr('Hoy', 'Today'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E6B34),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: C.t(0xFFF6E4EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  for (final w in L.weekdaysShort)
                    Expanded(
                      child: Text(
                        w,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: C.t(0xFF5A2A45),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            MonthGrid(
              month: _month,
              selected: _selected,
              onTap: (d) {
                setState(() => _selected = d);
                _showDay(d);
              },
            ),
            const SizedBox(height: 8),
            Divider(color: C.pinkLine, height: 1),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: [
                _legend(
                  const Img(
                    'drop',
                    size: 18,
                    fallback: Icons.water_drop_rounded,
                  ),
                  tr('Periodo\n(regla)', 'Period'),
                ),
                _legend(
                  _blob(
                    CalColors.predicted,
                    dashed: true,
                    child: const Img('drop_empty', size: 10),
                  ),
                  tr('Periodo\nprevisto', 'Predicted\nperiod'),
                ),
                _legend(
                  _blob(CalColors.fertile),
                  tr('Días\nfértiles', 'Fertile\ndays'),
                ),
                _legend(
                  const Icon(
                    Icons.local_florist,
                    color: CalColors.flower,
                    size: 20,
                  ),
                  tr('Ovulación', 'Ovulation'),
                ),
                _legend(
                  _blob(CalColors.normal),
                  tr('Día\nnormal', 'Normal\nday'),
                ),
                _legend(
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEAF6E4),
                      border: Border.all(color: CalColors.todayDark, width: 2),
                    ),
                  ),
                  tr('Hoy', 'Today'),
                ),
                if (AppStore.instance.showSex) ...[
                  _legend(const SexMark(sex: 1, size: 18), tr('Con protección', 'Protected')),
                  _legend(const SexMark(sex: 2, size: 18), tr('Sin protección', 'Unprotected')),
                ],
              ],
            ),
            Divider(height: 26, color: C.pinkLine),
            // Atajo: el mismo ajuste que Configuración > Configuración de predicción.
            Row(children: [
              const Text('🔀', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('Mi ciclo es irregular', 'My cycle is irregular'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.text)),
                  Text(tr('Te mostramos un margen de fechas en vez de un día exacto', 'We show you a range of dates instead of an exact day'),
                      style: const TextStyle(fontSize: 12, color: C.muted)),
                ]),
              ),
              Switch(
                value: CicloData.instance.irregular,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF2FB45A),
                onChanged: (v) async {
                  CicloData.instance.irregular = v;
                  setState(() {});
                  await SettingsService().saveIrregularCycleMode(v);
                  await AppStore.instance.commit();
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showDay(DateTime d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.t(0xFFFFF2F7),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: C.pinkLine, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: AppStore.instance,
                builder: (_, __) => _DayCard(
                  day: d,
                  onEdit: () {
                    Navigator.pop(ctx);
                    widget.onRegister(d);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(Color c, {bool dashed = false, Widget? child}) {
    final b = Container(
      width: 22,
      height: 18,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(9),
      ),
      child: child == null ? null : Center(child: child),
    );
    if (!dashed) return b;
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(
        color: C.red,
        radius: 9,
        dash: 2.5,
      ),
      child: b,
    );
  }

  Widget _legend(Widget dot, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(width: 24, child: Center(child: dot)),
      const SizedBox(width: 4),
      Text(
        t,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: C.text,
          height: 1.15,
        ),
      ),
    ],
  );

  Widget _arrow(IconData i, VoidCallback f) => InkWell(
    onTap: f,
    borderRadius: BorderRadius.circular(18),
    child: CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE3F1DA),
      child: Icon(i, color: const Color(0xFF1E6B34), size: 26),
    ),
  );

  Widget _yearView() {
    final y = _month.year;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: card(),
      child: Column(
        children: [
          Row(
            children: [
              _arrow(
                Icons.chevron_left_rounded,
                () => setState(() => _month = DateTime(y - 1, _month.month)),
              ),
              Expanded(
                child: Text(
                  '$y',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: C.text,
                  ),
                ),
              ),
              _arrow(
                Icons.chevron_right_rounded,
                () => setState(() => _month = DateTime(y + 1, _month.month)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
            children: [
              for (var m = 1; m <= 12; m++)
                GestureDetector(
                  onTap: () => setState(() {
                    _month = DateTime(y, m);
                    _year = false;
                  }),
                  child: _MiniMonth(month: DateTime(y, m)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String left;
  final String right;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;
  const _Segmented({
    required this.left,
    required this.right,
    required this.rightSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget seg(String t, bool sel, bool value) => GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: sel ? pinkGradient : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          t,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: sel ? Colors.white : C.pinkDark,
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: C.pinkLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(left, !rightSelected, false),
          seg(right, rightSelected, true),
        ],
      ),
    );
  }
}

/// Cuadrícula de un mes con periodo, previstos, fértiles, ovulación y hoy.
class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime>? onTap;
  final bool mini;
  const MonthGrid({
    super.key,
    required this.month,
    this.selected,
    this.onTap,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday - 1; // lunes = 0
    final daysIn = DateTime(month.year, month.month + 1, 0).day;
    final cells = lead + daysIn;
    final rows = (cells / 7).ceil();
    final today = dateOnly(DateTime.now());
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final idx = r * 7 + c - lead;
                      if (idx < 0 || idx >= daysIn)
                        return SizedBox(height: mini ? 13 : 40);
                      final d = DateTime(month.year, month.month, idx + 1);
                      final info = s.infoFor(d);
                      final isToday = d == today;
                      final isSel = selected != null && d == selected;
                      if (mini) return _miniCell(d, info, isToday);
                      return GestureDetector(
                        onTap: onTap == null ? null : () => onTap!(d),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 3,
                            horizontal: 2.5,
                          ),
                          child: _cell(d, info, isToday, isSel),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Tipo de banda del día: periodo, previsto, fértil o nada.
  static String? _kind(AppStore s, DateTime d) {
    final i = s.infoFor(d);
    if (i.period) return 'period';
    if (i.predictedPeriod) return 'pred';
    if (i.fertile || i.ovulation) return 'fertile';
    return null;
  }

  Widget _cell(DateTime d, DayInfo info, bool isToday, bool isSel) {
    const h = 46.0;
    final log = AppStore.instance.logs[dayKey(d)];
    Color fill = CalColors.normal;
    var textColor = C.t(0xFF4A2340);
    Widget? mark;
    var dashed = false;
    if (info.period) {
      fill = CalColors.period;
      textColor = C.t(0xFFC2185B);
      mark = const Img('drop', size: 13, fallback: Icons.water_drop_rounded);
    } else if (info.predictedPeriod) {
      fill = CalColors.predicted;
      textColor = C.t(0xFFC2185B);
      dashed = true;
      mark = const Img(
        'drop_empty',
        size: 12,
        fallback: Icons.water_drop_outlined,
      );
    } else if (info.ovulation) {
      fill = CalColors.ovulation;
      textColor = const Color(0xFF5B2E91);
      mark = const Icon(Icons.local_florist, color: CalColors.flower, size: 15);
    } else if (info.fertile) {
      fill = CalColors.fertile;
      textColor = const Color(0xFF2C5A2E);
    }
    final sex = log?.sex ?? 0;
    final hasOther = log != null && !log.isEmpty && log.flow == 0 && sex == 0;
    final BoxDecoration deco;
    if (isToday) {
      textColor = Colors.white;
      deco = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E8B45), CalColors.todayDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(color: const Color(0xFFB9E3B0), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: CalColors.todayDark.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );
      if (mark == null && info.fertile) mark = null;
    } else {
      deco = BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(h / 2),
        border: isSel
            ? Border.all(color: C.pinkDark, width: 2)
            : Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: C.t(0xFFD0407A).withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    Widget cell = Container(
      height: h,
      decoration: deco,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${d.day}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.05,
                  ),
                ),
                if (mark != null)
                  Padding(padding: const EdgeInsets.only(top: 1), child: mark),
                if (mark == null && hasOther)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: CircleAvatar(
                      radius: 2.2,
                      backgroundColor: isToday ? Colors.white : C.pink,
                    ),
                  ),
              ],
            ),
          ),
          if (sex > 0 && AppStore.instance.showSex)
            Positioned(right: -3, top: -4, child: SexMark(sex: sex, size: 15)),
        ],
      ),
    );
    if (dashed && !isToday) {
      cell = CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: const Color(0xFFE5284F),
          radius: h / 2,
          dash: 3.5,
        ),
        child: cell,
      );
    }
    return cell;
  }

  Widget _miniCell(DateTime d, DayInfo info, bool isToday) {
    Color? fill;
    Color tc = C.text;
    if (info.period || info.predictedPeriod) {
      fill = info.period ? C.t(0xFFFF8DB5) : C.t(0xFFFFD6E5);
      tc = info.period ? Colors.white : C.pinkDark;
    } else if (info.ovulation) {
      fill = CalColors.flower;
      tc = Colors.white;
    } else if (info.fertile) {
      fill = CalColors.fertile;
    }
    return Container(
      height: 13,
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: C.emerald, width: 1.2) : null,
      ),
      child: Center(
        child: Text(
          '${d.day}',
          style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: tc),
        ),
      ),
    );
  }
}

/// Colores del calendario (como la imagen de referencia).
class CalColors {
  static Color get normal => C.t(0xFFF6E4EC);
  static const period = Color(0xFFFCC3D4); // la regla siempre en rosa
  static Color get predicted => C.t(0xFFFFEEF3);
  static const fertile = Color(0xFFD9EDC8);
  static const ovulation = Color(0xFFE4D3FA);
  static const flower = Color(0xFF9B59E0);
  static const todayDark = Color(0xFF14612C);
}

/// Corazón de relación sexual: 1 = con protección (medio corazón), 2 = sin protección (corazón entero).
class SexMark extends StatelessWidget {
  final int sex;
  final double size;
  const SexMark({super.key, required this.sex, this.size = 15});

  @override
  Widget build(BuildContext context) {
    final protected = sex == 1;
    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 3),
        ],
      ),
      child: Center(
        child: protected
            // Con protección: medio corazón (la mitad izquierda rellena).
            ? SizedBox(
                width: size,
                height: size,
                child: Stack(
                  children: [
                    Icon(Icons.favorite_border, size: size, color: const Color(0xFFE5284F)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.5,
                          child: Icon(Icons.favorite, size: size, color: const Color(0xFFE5284F)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            // Sin protección: corazón entero.
            : Icon(Icons.favorite, size: size, color: const Color(0xFFE5284F)),
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final DateTime month;
  const _MiniMonth({required this.month});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = month.year == now.year && month.month == now.month;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: current ? C.pinkSoft : const Color(0xFFFFF8FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: current ? C.pink : C.pinkLine),
      ),
      child: Column(
        children: [
          Text(
            L.month(month.month),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: C.pinkDark,
            ),
          ),
          const SizedBox(height: 3),
          MonthGrid(month: month, mini: true),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color? fill;
  final Color? ring;
  final bool dashed;
  const _Dot({this.fill, this.ring, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    final c = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: ring != null ? Border.all(color: ring!, width: 2) : null,
      ),
    );
    if (!dashed) return c;
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(
        color: C.red,
        radius: 6,
        dash: 2.5,
      ),
      child: c,
    );
  }
}

/// Borde discontinuo redondeado (días de periodo previsto).
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  DashedBorderPainter({required this.color, this.radius = 11, this.dash = 4});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final m in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < m.length) {
        canvas.drawPath(m.extractPath(dist, dist + dash), paint);
        dist += dash * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter old) => old.color != color;
}

/// Contorno discontinuo de una banda (periodo previsto), redondeado solo en los extremos.
class DashedBandPainter extends CustomPainter {
  final Color color;
  final bool leftEnd;
  final bool rightEnd;
  DashedBandPainter({
    required this.color,
    required this.leftEnd,
    required this.rightEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final l = leftEnd ? r : 0.0;
    final rr = rightEnd ? size.width - r : size.width;
    final path = Path()
      ..moveTo(l, 1)
      ..lineTo(rr, 1);
    if (rightEnd) {
      path.arcTo(
        Rect.fromCircle(center: Offset(size.width - r, r), radius: r - 1),
        -math.pi / 2,
        math.pi,
        false,
      );
    } else {
      path.moveTo(size.width, size.height - 1);
    }
    path.lineTo(l, size.height - 1);
    if (leftEnd) {
      path.arcTo(
        Rect.fromCircle(center: Offset(r, r), radius: r - 1),
        math.pi / 2,
        math.pi,
        false,
      );
    }
    for (final m in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < m.length) {
        canvas.drawPath(m.extractPath(dist, dist + 4), paint);
        dist += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBandPainter old) =>
      old.leftEnd != leftEnd || old.rightEnd != rightEnd;
}

/// Tarjeta del día seleccionado.
class _DayCard extends StatelessWidget {
  final DateTime day;
  final VoidCallback onEdit;
  const _DayCard({required this.day, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final info = s.infoFor(day);
    final log = s.logFor(day);
    final chips = <Widget>[];
    if (log.flow > 0) {
      chips.add(
        _chip(
          null,
          '🩸',
          '${tr('Flujo', 'Flow')}\n(${flowNames[log.flow].toLowerCase()})',
        ),
      );
    }
    if (log.pain > 0 && !log.symptoms.contains('dolor')) {
      chips.add(
        _chip(
          's_dolor',
          null,
          '${symptomName('dolor')}\n(${painAdj[log.pain]})',
        ),
      );
    }
    for (final k in log.symptoms) {
      var label = symptomName(k);
      if (k == 'dolor' && log.pain > 0) label += '\n(${painAdj[log.pain]})';
      chips.add(
        _chip(symptomAsset(k), symptomAsset(k) == null ? '✨' : null, label),
      );
    }
    if (log.mood > 0) {
      chips.add(
        _chip(
          moodImgs[log.mood - 1],
          null,
          '${tr('Ánimo', 'Mood')}\n(${moodNames[log.mood - 1].toLowerCase()})',
        ),
      );
    }
    if (log.water > 0)
      chips.add(_chip(null, '💧', '${log.water} ${tr('vasos', 'glasses')}'));
    if (log.sleep != null)
      chips.add(_chip(null, '🌙', '${fmtNum(log.sleep!)} h'));
    if (log.weight != null)
      chips.add(_chip(null, '⚖️', '${fmtNum(log.weight!)} kg'));
    if (log.sex > 0 && AppStore.instance.showSex) chips.add(_chip(null, '❤️', sexNames[log.sex]));
    if (log.activity > 0) chips.add(_chip(null, '🏃', '${log.activity} min'));
    final ov = _OvTests.byDay[dateOnly(day)];
    if (ov != null) {
      final res = ov == 'peak' ? tr('Pico de LH', 'LH peak') : ov == 'positive' ? tr('Positivo', 'Positive') : tr('Negativo', 'Negative');
      chips.add(_chip(null, '🧪', '${tr('Test de ovulación', 'Ovulation test')}\n($res)'));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 60,
                decoration: BoxDecoration(
                  gradient: pinkGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      L.monthShort(day.month),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.cycleDay != null
                          ? tr(
                              'Día ${info.cycleDay} del ciclo',
                              'Cycle day ${info.cycleDay}',
                            )
                          : L.dateLong(day),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: C.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (info.phase != null)
                      Pill(
                        info.predictedPeriod
                            ? tr('Periodo previsto', 'Predicted period')
                            : phaseName(info.phase!),
                        icon: info.phase == Phase.period
                            ? Icons.water_drop_rounded
                            : Icons.eco,
                        img: info.phase == Phase.period ? 'drop' : 'leaf',
                        color: info.phase == Phase.period
                            ? C.pinkDark
                            : const Color(0xFF2B5B2E),
                        bg: info.phase == Phase.period
                            ? C.pinkSoft
                            : const Color(0xFFDDF0D3),
                      ),
                  ],
                ),
              ),
              const Img('cal_heart', size: 76, fallback: Icons.event_available),
            ],
          ),
          Divider(height: 22, color: C.pinkLine),
          InkWell(
            onTap: onEdit,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            color: C.pink,
                            size: 19,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tr('Síntomas registrados', 'Logged symptoms'),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: C.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (chips.isEmpty)
                        Text(
                          tr(
                            'Nada registrado. Toca para añadir.',
                            'Nothing logged. Tap to add.',
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: C.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Wrap(spacing: 6, runSpacing: 6, children: chips),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: C.muted),
              ],
            ),
          ),
          Divider(height: 22, color: C.pinkLine),
          InkWell(
            onTap: () => _editNote(context, log.note),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: C.pink,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tr('Notas', 'Notes'),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: C.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.note.isEmpty
                            ? tr('Sin notas', 'No notes')
                            : log.note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: log.note.isEmpty ? C.muted : C.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: C.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Notas: solo escribir la nota de este día (sin abrir todo el registro).
  Future<void> _editNote(BuildContext context, String current) async {
    final c = TextEditingController(text: current);
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tr('Nota', 'Note')} · ${L.dateLong(day)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.text)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: tr('¿Cómo te sientes hoy? ¿Qué has notado?', 'How do you feel today? What did you notice?'),
                filled: true,
                fillColor: C.pinkBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.pinkLine)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.pinkLine)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.pink, width: 2)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: PinkButton(label: tr('Cancelar', 'Cancel'), outlined: true, onTap: () => Navigator.pop(ctx))),
                const SizedBox(width: 10),
                Expanded(child: PinkButton(label: tr('Guardar', 'Save'), icon: Icons.check_rounded, onTap: () => Navigator.pop(ctx, c.text))),
              ],
            ),
          ],
        ),
      ),
    );
    if (text == null) return;
    await AppStore.instance.updateLog(day, (l) => l.note = text.trim());
    if (context.mounted) toast(context, tr('Nota guardada 💗', 'Note saved 💗'));
  }

  Widget _chip(String? asset, String? emoji, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: C.pinkBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: C.pinkLine),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asset != null)
          Img(asset, size: 24)
        else
          Text(emoji ?? '', style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: C.text,
            height: 1.15,
          ),
        ),
      ],
    ),
  );
}

/// Tests de ovulación guardados (pantalla Test de ovulación), por día,
/// para mostrarlos en el detalle del día del calendario.
class _OvTests {
  static Map<DateTime, String> byDay = {};
  static Future<void> load() async {
    final list = await SettingsService().loadOvulationTests();
    final m = <DateTime, String>{};
    for (final t in list.reversed) {
      m[DateTime(t.date.year, t.date.month, t.date.day)] = t.result;
    }
    byDay = m;
  }
}
