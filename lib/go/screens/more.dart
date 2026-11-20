import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import '../cicloplus_host.dart';
import 'extras.dart';
import 'month_summary.dart';
import 'michi_more.dart' show MichiDiaryScreen;
import 'register.dart';
import '../widgets/ciclo_date_picker.dart';
import '../widgets/premium.dart';

const _title = TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.text);
const _body = TextStyle(fontSize: 13, color: C.text, fontWeight: FontWeight.w600, height: 1.35);
const _muted = TextStyle(fontSize: 12, color: C.muted, fontWeight: FontWeight.w600, height: 1.3);

void _push(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

Widget _box(Widget child, {EdgeInsets padding = const EdgeInsets.all(14)}) =>
    Container(margin: const EdgeInsets.only(bottom: 12), padding: padding, decoration: card(), child: child);

Widget _empty(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          const Img('hibiscus', size: 56, fallback: Icons.local_florist),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: _muted),
        ],
      ),
    );

/// Fila de enlace con icono, texto y flecha.
class LinkRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool divider;
  /// Muestra la etiqueta dorada «👑 Premium» si la usuaria no es Premium.
  final bool premium;
  const LinkRow({super.key, required this.icon, required this.title, this.subtitle, this.trailing, required this.onTap, this.divider = true, this.premium = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: C.pinkLine)) : null),
          child: Row(
            children: [
              SizedBox(width: 32, child: Center(child: icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text)),
                    if (subtitle != null) Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: _muted),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (premium && !Premium.active)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF5DE9E)),
                  ),
                  child: const Text('👑 Premium', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8A6512))),
                ),
              const Icon(Icons.chevron_right_rounded, color: C.text),
            ],
          ),
        ),
      );
}

// ───────────────────────────── Mi salud ─────────────────────────────

class MyHealthScreen extends StatelessWidget {
  const MyHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <List<Object>>[
      if (!AppStore.instance.pregnant) ['q_period', tr('Periodo\ny ciclo', 'Period\n& cycle'), const PeriodCycleScreen()],
      if (!AppStore.instance.pregnant) ['q_symptoms', tr('Síntomas y\npredicciones', 'Symptoms &\npredictions'), const ReportScreen()],
      if (AppStore.instance.showSex) ['q_sex', tr('Vida\nsexual', 'Sex\nlife'), const SexLifeScreen()],
      ['q_weight', tr('Peso', 'Weight'), const MetricScreen(kind: Metric.weight)],
      ['q_sleep', tr('Sueño', 'Sleep'), const MetricScreen(kind: Metric.sleep)],
      ['q_breast', tr('Autoexamen\nde mamas', 'Breast\nself-exam'), const BreastExamScreen()],
      ['q_water', tr('Bebe\nagua', 'Drink\nwater'), const MetricScreen(kind: Metric.water)],
      ['q_timeline', tr('Cronología', 'Timeline'), const TimelineScreen()],
    ];
    return SubPage(
      title: tr('Mi salud', 'My health'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _box(
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
              children: [
                for (final it in items)
                  GestureDetector(
                    onTap: () => _push(context, it[2] as Widget),
                    child: Container(
                      decoration: tile(),
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                      child: Column(
                        children: [
                          Img(it[0] as String, size: 50),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Center(
                              child: Text(it[1] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: C.text, height: 1.1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _box(
            Column(
              children: [
                LinkRow(
                  icon: const Img('cal_check', size: 28),
                  title: tr('Registrar mi día', 'Log my day'),
                  onTap: () => _push(context, RegisterScreen(day: DateTime.now())),
                ),
                LinkRow(
                  icon: Icon(Icons.menu_book_rounded, color: C.pink),
                  title: tr('Mi diario', 'My diary'),
                  divider: false,
                  onTap: () => _push(context, const DiaryScreen()),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Informes y tendencias ─────────────────────────────

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) => SubPage(
        title: tr('Informes y tendencias', 'Reports & trends'),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _box(
              Column(
                children: [
                  if (AppStore.instance.goal != 'pregnancy') LinkRow(
                    icon: Icon(Icons.bar_chart_rounded, color: C.pink, size: 26),
                    title: tr('Análisis del ciclo', 'Cycle analysis'),
                    subtitle: tr('Ciclo, síntomas y estado de ánimo', 'Cycle, symptoms and mood'),
                    premium: true,
                    onTap: () => _push(context, const AnalysisScreen()),
                  ),
                  LinkRow(
                    icon: Icon(Icons.show_chart_rounded, color: C.pink, size: 26),
                    title: tr('Tendencias y bienestar', 'Trends & wellbeing'),
                    subtitle: tr('Energía, ánimo, sueño y dolor', 'Energy, mood, sleep and pain'),
                    premium: true,
                    onTap: () => _push(context, const TrendsScreen()),
                  ),
                  if (AppStore.instance.goal != 'pregnancy') LinkRow(
                    icon: const Img('report_chart', size: 30),
                    title: tr('Informe del ciclo', 'Cycle report'),
                    subtitle: tr('Resumen completo y predicciones', 'Full summary and predictions'),
                    divider: false,
                    premium: true,
                    onTap: () => _push(context, const ReportScreen()),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            ),
          ],
        ),
      );
}

// ───────────────────────────── Análisis del ciclo ─────────────────────────────

class _AnalysisScreenBody extends StatefulWidget {
  final int initialTab;
  const _AnalysisScreenBody({super.key, this.initialTab = 0});

  @override
  State<_AnalysisScreenBody> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<_AnalysisScreenBody> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final tabs = [tr('Ciclo', 'Cycle'), tr('Síntomas', 'Symptoms'), tr('Estado de ánimo', 'Mood')];
    return SubPage(
      title: tr('Análisis del ciclo', 'Cycle analysis'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(color: _tab == i ? C.pinkSoft : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                        child: Text(tabs[i],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _tab == i ? C.pinkDark : C.text)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_tab == 0) ..._cycle(),
          if (_tab == 0 && !Premium.active) PremiumTeaser(text: tr('Premium: historial completo de tus ciclos, síntomas y estado de ánimo.', 'Premium: full history of your cycles, symptoms and mood.')),
          if (_tab == 1) ..._symptoms(),
          if (_tab == 2) ..._moods(),
        ],
      ),
    );
  }

  Widget _pattern(String text) => _box(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Tu patrón', 'Your pattern'), style: _title),
                  const SizedBox(height: 3),
                  Text(text, style: _body),
                ],
              ),
            ),
          ],
        ),
      );

  List<Widget> _cycle() {
    final s = AppStore.instance;
    final starts = s.periodStarts;
    final bars = <MapEntry<String, int>>[];
    for (var i = 1; i < starts.length; i++) {
      final len = daysBetween(starts[i - 1], starts[i]);
      if (len >= 15 && len <= 60) bars.add(MapEntry(L.monthShort(starts[i - 1].month), len));
    }
    final keep = Premium.active ? 6 : 3;
    final recent = bars.length > keep ? bars.sublist(bars.length - keep) : bars;
    final reg = s.isRegular;
    String pattern;
    if (recent.isEmpty) {
      pattern = tr('Registra al menos dos periodos para ver tu patrón.', 'Log at least two periods to see your pattern.');
    } else if (reg == false) {
      pattern = tr('Tus ciclos varían más de 7 días (media de ${s.avgCycle} días). Sigue registrando y, si te preocupa, consulta con tu ginecóloga.',
          'Your cycles vary by more than 7 days (average ${s.avgCycle} days). Keep logging and talk to your doctor if worried.');
    } else {
      pattern = tr('Tu ciclo es regular (${s.avgCycle} días) y se mantiene estable. ¡Muy bien! 💗',
          'Your cycle is regular (${s.avgCycle} days) and stable. Great! 💗');
    }
    return [
      _box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Premium.active ? tr('Duración del ciclo (últimos 6)', 'Cycle length (last 6)') : tr('Duración del ciclo (últimos 3)', 'Cycle length (last 3)'), style: _title),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              _empty(tr('Aún no hay ciclos completos.', 'No complete cycles yet.'))
            else
              _VBars(values: [for (final e in recent) e.value.toDouble()], labels: [for (final e in recent) e.key]),
          ],
        ),
      ),
      Row(
        children: [
          _stat('${s.avgCycle}', tr('Ciclo medio', 'Avg. cycle')),
          const SizedBox(width: 8),
          _stat('${s.avgPeriod}', tr('Periodo medio', 'Avg. period')),
          const SizedBox(width: 8),
          _stat(s.variability == null ? '—' : '±${s.variability}', tr('Variabilidad', 'Variability')),
        ],
      ),
      const SizedBox(height: 12),
      _pattern(pattern),
    ];
  }

  Widget _stat(String v, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: tile(),
          child: Column(
            children: [
              Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.pinkDark)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _muted),
            ],
          ),
        ),
      );

  List<Widget> _symptoms() {
    final counts = AppStore.instance.symptomCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = counts.take(Premium.active ? 8 : 3).toList();
    final max = top.isEmpty ? 1 : top.first.value;
    return [
      _box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Síntomas más frecuentes', 'Most frequent symptoms'), style: _title),
            const SizedBox(height: 10),
            if (top.isEmpty)
              _empty(tr('Registra tus síntomas en "Registrar mi día".', 'Log your symptoms in "Log my day".'))
            else
              for (final e in top)
                _HBar(
                  icon: symptomAsset(e.key) != null ? Img(symptomAsset(e.key)!, size: 26) : const Text('✨', style: TextStyle(fontSize: 18)),
                  label: symptomName(e.key),
                  value: e.value,
                  fraction: e.value / max,
                ),
          ],
        ),
      ),
      _pattern(top.isEmpty
          ? tr('Cuando registres síntomas verás cuáles se repiten más.', 'Once you log symptoms you will see which repeat most.')
          : tr('Tu síntoma más habitual es "${symptomName(top.first.key).toLowerCase()}" (${top.first.value} veces).',
              'Your most common symptom is "${symptomName(top.first.key).toLowerCase()}" (${top.first.value} times).')),
      if (!Premium.active) PremiumTeaser(text: tr('Premium: historial completo de tus ciclos, síntomas y estado de ánimo.', 'Premium: full history of your cycles, symptoms and mood.')),
    ];
  }

  List<Widget> _moods() {
    if (!Premium.active) return [PremiumTeaser(text: tr('Premium: historial completo de tus ciclos, síntomas y estado de ánimo.', 'Premium: full history of your cycles, symptoms and mood.'))];
    final counts = AppStore.instance.moodCounts;
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final max = counts.values.fold<int>(1, (a, b) => math.max(a, b));
    var best = 0;
    counts.forEach((k, v) {
      if (best == 0 || v > (counts[best] ?? 0)) best = k;
    });
    return [
      _box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Cómo te has sentido', 'How you have felt'), style: _title),
            const SizedBox(height: 10),
            if (total == 0)
              _empty(tr('Elige cómo te sientes en la pestaña Hoy.', 'Pick how you feel on the Today tab.'))
            else
              for (var i = 0; i < 5; i++)
                _HBar(icon: Img(moodImgs[i], size: 26), label: moodNames[i], value: counts[i + 1] ?? 0, fraction: (counts[i + 1] ?? 0) / max),
          ],
        ),
      ),
      _pattern(total == 0
          ? tr('Cuando registres tu ánimo verás cómo cambia durante el ciclo.', 'Once you log your mood you will see how it changes.')
          : tr('La mayoría de días te has sentido "${moodNames[best - 1].toLowerCase()}" ($total días registrados).',
              'Most days you felt "${moodNames[best - 1].toLowerCase()}" ($total days logged).')),
    ];
  }
}

class _VBars extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  const _VBars({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final mx = values.reduce(math.max);
    final mn = values.reduce(math.min);
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(values[i].round().toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 4),
                  Container(
                    width: 16,
                    height: 40 + (mx == mn ? 60 : (values[i] - mn) / (mx - mn) * 80),
                    decoration: BoxDecoration(gradient: pinkGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i], style: _muted),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HBar extends StatelessWidget {
  final Widget icon;
  final String label;
  final int value;
  final double fraction;
  const _HBar({required this.icon, required this.label, required this.value, required this.fraction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(width: 30, child: Center(child: icon)),
            const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.text)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: C.pinkSoft,
                  valueColor: AlwaysStoppedAnimation(C.pink),
                ),
              ),
            ),
            SizedBox(width: 34, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800, color: C.text))),
          ],
        ),
      );
}

// ───────────────────────────── Tendencias ─────────────────────────────

class _Trend {
  final String img;
  final String name;
  final Color color;
  final String unit;
  final double? Function(DayLog l) value;
  final String help;
  const _Trend(this.img, this.name, this.color, this.unit, this.value, this.help);
}

List<_Trend> get _trends => [
      _Trend('s_energia', tr('Energía', 'Energy'), const Color(0xFF3DBE7A), '/5', (l) => l.mood > 0 ? moodEnergy[l.mood - 1].toDouble() : null,
          tr('Calculada a partir de cómo te sientes cada día.', 'Based on how you feel each day.')),
      _Trend('m4', tr('Ánimo', 'Mood'), const Color(0xFF9B6BE0), '/5', (l) => l.mood > 0 ? moodScore[l.mood - 1].toDouble() : null,
          tr('Media semanal de tu estado de ánimo.', 'Weekly average of your mood.')),
      _Trend('s_sueno', tr('Sueño', 'Sleep'), C.blue, ' h', (l) => l.sleep,
          tr('Horas de sueño registradas (Mi salud › Sueño).', 'Logged sleep hours (My health › Sleep).')),
      _Trend('s_dolor', tr('Dolor', 'Pain'), C.pink, '/3', (l) => l.pain > 0 ? l.pain.toDouble() : (l.symptoms.contains('dolor') ? 1.0 : null),
          tr('Intensidad media del dolor los días que lo registraste.', 'Average pain intensity on the days you logged it.')),
    ];

class _TrendsScreenBody extends StatelessWidget {
  const _TrendsScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return SubPage(
      title: tr('Tendencias', 'Trends'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(tr('Últimas 6 semanas', 'Last 6 weeks'), style: _muted),
          const SizedBox(height: 8),
          _box(
            Column(
              children: [
                for (var i = 0; i < _trends.length; i++)
                  LinkRow(
                    icon: Img(_trends[i].img, size: 28),
                    title: _trends[i].name,
                    divider: i < _trends.length - 1,
                    trailing: SizedBox(width: 110, height: 34, child: CustomPaint(painter: SparkPainter(s.weekly(_trends[i].value), _trends[i].color))),
                    onTap: () => _push(context, PremiumGate(title: _trends[i].name, child: TrendDetailScreen(index: i))),
                  ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          ),
          Text(tr('Cuantos más días registres, más precisas serán tus tendencias.', 'The more days you log, the more accurate your trends.'),
              textAlign: TextAlign.center, style: _muted),
          if (!Premium.active) PremiumTeaser(text: tr('Premium: toca una tendencia para ver su detalle de 8 semanas.', 'Premium: tap a trend to see its 8-week detail.')),
        ],
      ),
    );
  }
}

class TrendDetailScreen extends StatelessWidget {
  final int index;
  const TrendDetailScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final t = _trends[index];
    final data = AppStore.instance.weekly(t.value, weeks: 8);
    final vals = data.whereType<double>().toList();
    final avg = vals.isEmpty ? null : vals.reduce((a, b) => a + b) / vals.length;
    return SubPage(
      title: t.name,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Img(t.img, size: 34),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tr('Últimas 8 semanas', 'Last 8 weeks'), style: _title)),
                    if (avg != null)
                      Text('${fmtNum(double.parse(avg.toStringAsFixed(1)))}${t.unit}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: t.color)),
                  ],
                ),
                const SizedBox(height: 14),
                if (vals.isEmpty)
                  _empty(tr('Aún no hay datos.', 'No data yet.'))
                else ...[
                  SizedBox(height: 160, width: double.infinity, child: CustomPaint(painter: SparkPainter(data, t.color, big: true))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var i = 0; i < data.length; i++)
                        Expanded(
                          child: Text(i == data.length - 1 ? tr('Esta', 'This') : '-${data.length - 1 - i}s',
                              textAlign: TextAlign.center, style: _muted),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _box(Text(t.help, style: _body)),
        ],
      ),
    );
  }
}

/// Mini gráfica de línea; ignora las semanas sin datos.
class SparkPainter extends CustomPainter {
  final List<double?> data;
  final Color color;
  final bool big;
  SparkPainter(this.data, this.color, {this.big = false});

  @override
  void paint(Canvas canvas, Size size) {
    final vals = data.whereType<double>().toList();
    if (vals.isEmpty) {
      final p = Paint()
        ..color = C.pinkLine
        ..strokeWidth = 2;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
      return;
    }
    var mn = vals.reduce(math.min);
    var mx = vals.reduce(math.max);
    if (mx - mn < 0.5) {
      mn -= 0.5;
      mx += 0.5;
    }
    final pad = big ? 10.0 : 4.0;
    final n = data.length;
    Offset at(int i, double v) => Offset(
          n == 1 ? size.width / 2 : pad + (size.width - pad * 2) * i / (n - 1),
          pad + (size.height - pad * 2) * (1 - (v - mn) / (mx - mn)),
        );
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final v = data[i];
      if (v != null) pts.add(at(i, v));
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = big ? 3 : 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (pts.length > 1) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, line);
    }
    for (final p in pts) {
      canvas.drawCircle(p, big ? 5 : 2.8, Paint()..color = color);
      if (big) canvas.drawCircle(p, 2.2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant SparkPainter old) => true;
}

// ───────────────────────────── Mi diario ─────────────────────────────

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final s = AppStore.instance;
        final days = s.noteDays;
        final today = dateOnly(DateTime.now());
        return SubPage(
          title: tr('Mi diario', 'My diary'),
          bottom: PinkButton(
            label: tr('Nueva nota', 'New note'),
            icon: Icons.add_rounded,
            onTap: () => _push(context, NoteEditorScreen(day: today)),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              if (s.showMichi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _push(context, const MichiDiaryScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: C.pinkSoft, borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        const Img('michi_letter', size: 36, fallback: Icons.pets_rounded),
                        const SizedBox(width: 10),
                        Expanded(child: Text(tr('Cuéntaselo a Michi y te contesta 💌', 'Tell Michi and he will reply 💌'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.pinkDark))),
                        Icon(Icons.chevron_right_rounded, color: C.pink),
                      ]),
                    ),
                  ),
                ),
              if (days.isEmpty)
                _box(_empty(tr('Aún no tienes notas.\nEscribe cómo te sientes, qué has notado o lo que quieras recordar.',
                    "You don't have notes yet.\nWrite how you feel or anything you want to remember.")))
              else
                _box(
                  Column(
                    children: [
                      for (var i = 0; i < days.length; i++) _entry(context, days[i], i < days.length - 1),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _entry(BuildContext context, DateTime d, bool divider) {
    final s = AppStore.instance;
    final l = s.logFor(d);
    final info = s.infoFor(d);
    final isToday = d == dateOnly(DateTime.now());
    final img = l.flow > 0 ? 'n_drop' : (l.symptoms.contains('dolor') || l.pain > 0 ? 's_dolor' : (l.mood > 0 ? moodImgs[l.mood - 1] : 'n_calendar'));
    final head = '${isToday ? tr('Hoy', 'Today') : L.dateShort(d)}${info.cycleDay != null ? ' · ${tr('Día', 'Day')} ${info.cycleDay}' : ''}';
    return InkWell(
      onTap: () => _push(context, NoteEditorScreen(day: d)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: C.pinkLine)) : null),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Img(img, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(head, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 2),
                  Text(l.note, maxLines: 3, overflow: TextOverflow.ellipsis, style: _body),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, size: 18, color: C.pink),
          ],
        ),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final DateTime day;
  const NoteEditorScreen({super.key, required this.day});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late DateTime _day;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setDay(dateOnly(widget.day));
  }

  void _setDay(DateTime d) {
    _day = d;
    _ctrl.text = AppStore.instance.logFor(d).note;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showCicloDatePicker(context: context, initialDate: _day, firstDate: DateTime(now.year - 3), lastDate: now);
    if (d != null) setState(() => _setDay(dateOnly(d)));
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    await AppStore.instance.updateLog(_day, (l) => l.note = text);
    if (!mounted) return;
    toast(context, text.isEmpty ? tr('Nota borrada', 'Note deleted') : tr('Nota guardada 💗', 'Note saved 💗'));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = AppStore.instance.logFor(_day).note.isNotEmpty;
    return SubPage(
      title: tr('Nota', 'Note'),
      bottom: Row(
        children: [
          if (hasNote) ...[
            Expanded(
              child: PinkButton(
                label: tr('Borrar', 'Delete'),
                outlined: true,
                onTap: () {
                  _ctrl.clear();
                  _save();
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: PinkButton(label: tr('Guardar', 'Save'), icon: Icons.check_rounded, onTap: _save)),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          GestureDetector(
            onTap: _pickDay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: card(radius: 18),
              child: Row(
                children: [
                  const Img('n_calendar', size: 26),
                  const SizedBox(width: 10),
                  Expanded(child: Text(L.dateLong(_day), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text))),
                  Icon(Icons.edit_calendar_rounded, color: C.pink),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 8,
            maxLines: 16,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: tr('¿Cómo te sientes hoy? ¿Qué has notado?', 'How do you feel today? What did you notice?'),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pinkLine)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pinkLine)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pink, width: 2)),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Mi pareja ─────────────────────────────

class PartnerScreen extends StatelessWidget {
  const PartnerScreen({super.key});

  String _summary() {
    final s = AppStore.instance;
    final today = dateOnly(DateTime.now());
    final info = s.infoFor(today);
    final b = StringBuffer();
    if (s.goal == 'pregnancy' && s.pregnancyWeek != null) {
      b.writeln(tr('🤰 Estoy de ${s.pregnancyWeek} semanas.', "🤰 I'm ${s.pregnancyWeek} weeks pregnant."));
    } else if (info.phase != null) {
      b.writeln(tr('🌸 Hoy: día ${info.cycleDay} del ciclo — ${phaseName(info.phase!)}.', '🌸 Today: cycle day ${info.cycleDay} — ${phaseName(info.phase!)}.'));
      final next = s.nextPeriod;
      if (next != null) b.writeln(tr('🩸 Próximo periodo: ${L.dateLong(next)}.', '🩸 Next period: ${L.dateLong(next)}.'));
      final ov = s.nextOvulation;
      if (ov != null) b.writeln(tr('🌱 Ovulación estimada: ${L.dateLong(ov)}.', '🌱 Estimated ovulation: ${L.dateLong(ov)}.'));
    } else {
      b.writeln(tr('Aún estoy empezando a registrar mi ciclo.', "I'm just starting to track my cycle."));
    }
    return b.toString().trim();
  }

  Future<void> _share(BuildContext context, String text) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(text, sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size);
    } catch (_) {
      if (context.mounted) toast(context, tr('No se pudo compartir', 'Could not share'));
    }
  }

  Future<void> _editName(BuildContext context) async {
    final s = AppStore.instance;
    final c = TextEditingController(text: s.partnerName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Nombre de tu pareja', "Your partner's name")),
        content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Guardar', 'Save'))),
        ],
      ),
    );
    if (ok == true) {
      s.partnerName = c.text.trim();
      await s.commit();
    }
  }

  Future<void> _support(BuildContext context) async {
    final msgs = [
      tr('Hoy no me encuentro muy bien, ¿me das un abrazo? 🤗', "I'm not feeling great today, can I get a hug? 🤗"),
      tr('¿Me traes algo dulce de camino a casa? 🍫', 'Could you bring me something sweet on your way home? 🍫'),
      tr('Hoy necesito descansar, ¿nos quedamos tranquilos en casa? 🛋️', 'I need to rest today, shall we stay in? 🛋️'),
      tr('Me siento con mucha energía, ¿hacemos un plan juntos? ✨', "I'm full of energy, shall we make a plan together? ✨"),
    ];
    final m = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(tr('Enviar un mensaje de apoyo', 'Send a support message'), style: _title),
            const SizedBox(height: 6),
            for (final t in msgs)
              ListTile(title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)), onTap: () => Navigator.pop(ctx, t)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (m != null && context.mounted) await _share(context, m);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final s = AppStore.instance;
        final hi = s.partnerName.isEmpty ? tr('Hola', 'Hi') : tr('Hola ${s.partnerName}', 'Hi ${s.partnerName}');
        return SubPage(
          title: tr('Mi pareja', 'My partner'),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              const Center(child: Img('couple', size: 200, fallback: Icons.favorite)),
              const SizedBox(height: 6),
              Text(tr('Comparte tu ciclo y bienestar con tu pareja.', 'Share your cycle and wellbeing with your partner.'),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.text)),
              const SizedBox(height: 12),
              _box(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in [
                      tr('Ver tu fase del ciclo', 'See your cycle phase'),
                      tr('Saber tus próximas fechas', 'Know your upcoming dates'),
                      tr('Recibir mensajes de apoyo', 'Get support messages'),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          const Icon(Icons.check_rounded, color: Color(0xFF2FB45A)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text))),
                        ]),
                      ),
                  ],
                ),
              ),
              _box(
                LinkRow(
                  icon: Icon(Icons.person_rounded, color: C.pink),
                  title: s.partnerName.isEmpty ? tr('Añadir su nombre', 'Add their name') : s.partnerName,
                  subtitle: tr('Para personalizar los mensajes', 'To personalise the messages'),
                  divider: false,
                  onTap: () => _editName(context),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              ),
              PinkButton(
                label: tr('Invitar a mi pareja', 'Invite my partner'),
                icon: Icons.group_add_rounded,
                onTap: () => _share(
                    context,
                    tr('$hi 💗 Uso CicloPlus para seguir mi ciclo. Así estoy ahora:\n\n${_summary()}',
                        "$hi 💗 I use CicloPlus to track my cycle. Here's how I am now:\n\n${_summary()}")),
              ),
              const SizedBox(height: 10),
              PinkButton(
                label: tr('Enviar mensaje de apoyo', 'Send a support message'),
                icon: Icons.chat_bubble_rounded,
                outlined: true,
                onTap: () => _support(context),
              ),
              const SizedBox(height: 10),
              Text(
                tr('Se comparte por WhatsApp, Mensajes o la app que elijas. Tus datos no salen del teléfono si no los compartes tú.',
                    'Shared via WhatsApp, Messages or any app you choose. Your data never leaves your phone unless you share it.'),
                textAlign: TextAlign.center,
                style: _muted,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────── Embarazo ─────────────────────────────

const _babySizes = {
  4: ['una semilla de amapola', 'a poppy seed', '0,1 cm'],
  5: ['una semilla de sésamo', 'a sesame seed', '0,2 cm'],
  6: ['una lenteja', 'a lentil', '0,6 cm'],
  7: ['un arándano', 'a blueberry', '1 cm'],
  8: ['una frambuesa', 'a raspberry', '1,6 cm'],
  9: ['una cereza', 'a cherry', '2,3 cm'],
  10: ['una fresa', 'a strawberry', '3 cm'],
  11: ['un higo', 'a fig', '4 cm'],
  12: ['una lima', 'a lime', '5,4 cm'],
  13: ['un limón', 'a lemon', '7,4 cm'],
  14: ['un melocotón', 'a peach', '8,7 cm'],
  15: ['una manzana', 'an apple', '10 cm'],
  16: ['un aguacate', 'an avocado', '11,6 cm'],
  17: ['una granada', 'a pomegranate', '13 cm'],
  18: ['un pimiento', 'a bell pepper', '14 cm'],
  19: ['un tomate grande', 'a large tomato', '15 cm'],
  20: ['un plátano', 'a banana', '25 cm'],
  21: ['una zanahoria', 'a carrot', '27 cm'],
  22: ['una papaya', 'a papaya', '28 cm'],
  23: ['un pomelo', 'a grapefruit', '29 cm'],
  24: ['una mazorca de maíz', 'an ear of corn', '30 cm'],
  25: ['una coliflor', 'a cauliflower', '35 cm'],
  26: ['una lechuga', 'a head of lettuce', '36 cm'],
  27: ['un brócoli', 'a broccoli', '37 cm'],
  28: ['una berenjena', 'an eggplant', '38 cm'],
  29: ['una calabaza pequeña', 'a small pumpkin', '39 cm'],
  30: ['una col', 'a cabbage', '40 cm'],
  31: ['un coco', 'a coconut', '41 cm'],
  32: ['una piña pequeña', 'a small pineapple', '42 cm'],
  33: ['una piña', 'a pineapple', '44 cm'],
  34: ['un melón', 'a melon', '45 cm'],
  35: ['un melón grande', 'a large melon', '46 cm'],
  36: ['una lechuga romana', 'a romaine lettuce', '47 cm'],
  37: ['un manojo de acelgas', 'a bunch of chard', '49 cm'],
  38: ['un puerro', 'a leek', '50 cm'],
  39: ['una sandía pequeña', 'a small watermelon', '51 cm'],
  40: ['una sandía', 'a watermelon', '51 cm'],
};

String babyText(int w) {
  if (w <= 3) {
    return tr('Tu cuerpo se prepara: en estas semanas ocurren la ovulación, la fecundación y la implantación.',
        'Your body is getting ready: ovulation, fertilisation and implantation happen these weeks.');
  }
  final k = w > 40 ? 40 : w;
  final sz = _babySizes[k]!;
  final noun = tr(sz[0], sz[1]);
  final size = tr('Tu bebé mide como $noun (unos ${sz[2]}).', 'Your baby is about the size of ${sz[1]} (around ${sz[2]}).');
  String stage;
  if (w <= 8) {
    stage = tr('Se forman el corazón, que ya late, y los primeros esbozos de brazos y piernas.',
        'The heart forms and starts beating, and tiny arm and leg buds appear.');
  } else if (w <= 13) {
    stage = tr('Ya tiene todos sus órganos formados y empieza a moverse, aunque aún no lo notes.',
        'All organs are formed and the baby starts moving, though you cannot feel it yet.');
  } else if (w <= 20) {
    stage = tr('Crece rápido, puede oír tu voz y pronto notarás sus primeras pataditas.',
        'Growing fast, the baby can hear your voice and you will soon feel the first kicks.');
  } else if (w <= 27) {
    stage = tr('Sus pulmones se desarrollan y tiene ciclos de sueño y vigilia.', 'The lungs develop and the baby has sleep and wake cycles.');
  } else if (w <= 36) {
    stage = tr('Gana peso, abre los ojos y se va colocando para el nacimiento.', 'Gaining weight, opening eyes and getting into position for birth.');
  } else {
    stage = tr('¡Está listo para nacer en cualquier momento!', 'Ready to be born any moment now!');
  }
  return '$size $stage';
}

String pregnancyTip(int w) {
  if (w <= 13) {
    return tr(
        'Primer trimestre: toma ácido fólico si te lo han indicado, descansa todo lo que puedas y come poco y a menudo si tienes náuseas. Pide cita con tu matrona.',
        'First trimester: take folic acid if prescribed, rest as much as you can and eat small, frequent meals if nauseous. Book your midwife.');
  }
  if (w <= 27) {
    return tr('Segundo trimestre: suele ser la etapa con más energía. Camina, hidrátate bien y prepara la ecografía morfológica (semana 20).',
        'Second trimester: usually the most energetic stage. Walk, stay hydrated and get ready for the anatomy scan (week 20).');
  }
  return tr('Tercer trimestre: descansa de lado, prepara la bolsa del hospital y aprende a reconocer las contracciones. Ante cualquier duda, llama a tu matrona.',
      'Third trimester: rest on your side, pack the hospital bag and learn to recognise contractions. If in doubt, call your midwife.');
}

class PregnancyScreen extends StatelessWidget {
  const PregnancyScreen({super.key});

  static Future<bool> setup(BuildContext context) async {
    final s = AppStore.instance;
    final now = dateOnly(DateTime.now());
    final initial = s.pregnancyStart ?? s.lastStart ?? addDays(now, -56);
    final d = await showCicloDatePicker(
      context: context,
      helpText: tr('PRIMER DÍA DE TU ÚLTIMA REGLA', 'FIRST DAY OF YOUR LAST PERIOD'),
      initialDate: initial.isAfter(now) ? now : (initial.isBefore(addDays(now, -294)) ? addDays(now, -294) : initial),
      firstDate: addDays(now, -294),
      lastDate: now,
    );
    if (d == null) return false;
    s.pregnancyStart = dateOnly(d);
    s.goal = 'pregnancy';
    await s.commit();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final s = AppStore.instance;
        final w = s.pregnancyWeek;
        if (w == null) {
          return SubPage(
            title: tr('Embarazo', 'Pregnancy'),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                const Center(child: Img('baby', size: 170, fallback: Icons.child_friendly_rounded)),
                const SizedBox(height: 10),
                Text(tr('Sigue tu embarazo semana a semana', 'Follow your pregnancy week by week'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.text)),
                const SizedBox(height: 8),
                Text(tr('Dinos el primer día de tu última regla y calcularemos tu semana y la fecha prevista de parto.',
                        "Tell us the first day of your last period and we'll calculate your week and due date."),
                    textAlign: TextAlign.center, style: _body),
                const SizedBox(height: 18),
                PinkButton(label: tr('Empezar', 'Start'), icon: Icons.favorite_rounded, onTap: () => setup(context)),
              ],
            ),
          );
        }
        final due = addDays(s.pregnancyStart!, 280);
        final left = daysBetween(dateOnly(DateTime.now()), due);
        return SubPage(
          title: tr('Embarazo', 'Pregnancy'),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  const Img('baby', size: 150, fallback: Icons.child_friendly_rounded),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tr('Semana', 'Week')} $w', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: C.text)),
                        Text(tr('de embarazo', 'of pregnancy'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.text)),
                        if (s.pregnancyDayOfWeek > 0)
                          Text(tr('y ${s.pregnancyDayOfWeek} ${daysWord(s.pregnancyDayOfWeek)}', 'and ${s.pregnancyDayOfWeek} ${daysWord(s.pregnancyDayOfWeek)}'),
                              style: _muted),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _box(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (w / 40).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: C.pinkSoft,
                        valueColor: AlwaysStoppedAnimation(C.pink),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${tr('Fecha prevista de parto', 'Due date')}: ${L.dateLong(due)}', style: const TextStyle(fontWeight: FontWeight.w800, color: C.text)),
                    Text(left > 0 ? tr('Faltan $left días', '$left days to go') : tr('¡Ya ha llegado la fecha!', 'Your due date is here!'), style: _muted),
                  ],
                ),
              ),
              Row(
                children: [
                  _tileBtn(context, 'baby', tr('Desarrollo\ndel bebé', 'Baby\ndevelopment'),
                      () => _info(context, tr('Semana $w · Tu bebé', 'Week $w · Your baby'), babyText(w))),
                  const SizedBox(width: 10),
                  _tileBtn(context, 'q_sex', tr('Mis\nsíntomas', 'My\nsymptoms'), () => _push(context, RegisterScreen(day: DateTime.now()))),
                  const SizedBox(width: 10),
                  _tileBtn(context, 'logo_flower', tr('Consejos\nsemanales', 'Weekly\ntips'),
                      () => _info(context, tr('Consejos · semana $w', 'Tips · week $w'), pregnancyTip(w))),
                ],
              ),
              const SizedBox(height: 12),
              _box(Text(babyText(w), style: _body)),
              _box(
                Column(
                  children: [
                    LinkRow(
                      icon: Icon(Icons.edit_calendar_rounded, color: C.pink),
                      title: tr('Cambiar fecha de la última regla', 'Change last period date'),
                      onTap: () => setup(context),
                    ),
                    LinkRow(
                      icon: Icon(Icons.logout_rounded, color: C.pink),
                      title: tr('Salir del modo embarazo', 'Leave pregnancy mode'),
                      divider: false,
                      onTap: () async {
                        s.goal = 'track';
                        s.pregnancyStart = null;
                        await s.commit();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              ),
              Text(tr('Información orientativa. Sigue siempre las indicaciones de tu matrona o ginecóloga.',
                  'For guidance only. Always follow your midwife or doctor.'),
                  textAlign: TextAlign.center, style: _muted),
            ],
          ),
        );
      },
    );
  }

  Widget _tileBtn(BuildContext context, String img, String label, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
            decoration: tile(radius: 22),
            child: Column(
              children: [
                Img(img, size: 48),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.text, height: 1.1)),
              ],
            ),
          ),
        ),
      );

  void _info(BuildContext context, String title, String text) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.text)),
                const SizedBox(height: 10),
                Text(text, style: _body),
                const SizedBox(height: 16),
                PinkButton(label: tr('Entendido', 'Got it'), onTap: () => Navigator.pop(ctx)),
              ],
            ),
          ),
        ),
      );
}


/// AnalysisScreen es Premium: sin Premium enseña qué incluye y lleva al pago.
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) => _AnalysisScreenBody(initialTab: initialTab);
}


/// TrendsScreen es Premium: sin Premium enseña qué incluye y lleva al pago.
class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _TrendsScreenBody();
}
