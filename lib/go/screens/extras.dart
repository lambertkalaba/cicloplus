import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/legal_links.dart';
import '../../services/locale_controller.dart';

import '../data/store.dart';
import '../go_root.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'register.dart';

const _h = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.text);
const _b = TextStyle(fontSize: 13, color: C.muted, fontWeight: FontWeight.w600, height: 1.35);

Widget _box(Widget child, {EdgeInsets padding = const EdgeInsets.all(14)}) =>
    Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: padding,
        decoration: card(),
        child: Material(type: MaterialType.transparency, child: child));

/// Cambiar el nombre.
Future<void> editName(BuildContext context) async {
  final s = AppStore.instance;
  final c = TextEditingController(text: s.name);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('Tu nombre', 'Your name')),
      content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.words),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Guardar', 'Save'))),
      ],
    ),
  );
  if (ok == true) {
    s.name = c.text.trim();
    await s.commit();
  }
}

/// Cambiar la foto de perfil (galería, cámara o volver a la ilustración).
Future<void> pickPhoto(BuildContext context) async {
  final s = AppStore.instance;
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(tr('Foto de perfil', 'Profile photo'), style: _h),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: C.pink),
            title: Text(tr('Elegir de la galería', 'Choose from gallery'), style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded, color: C.pink),
            title: Text(tr('Hacer una foto', 'Take a photo'), style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const ClipOval(child: Img('avatar', size: 28, fit: BoxFit.cover, fallback: Icons.face_3)),
            title: Text(tr('Usar la ilustración', 'Use the illustration'), style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, 'default'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null) return;
  final old = s.photoPath;
  if (choice == 'default') {
    s.photoName = null;
    await s.commit();
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
    return;
  }
  try {
    final x = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (x == null || s.docsPath.isEmpty) return;
    final name = 'perfil_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(x.path).copy('${s.docsPath}/$name');
    s.photoName = name;
    await s.commit();
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  } catch (e) {
    if (context.mounted) toast(context, tr('No se pudo cargar la foto', 'Could not load the photo'));
  }
}

// ───────────────────────────── Periodo y ciclo ─────────────────────────────

class PeriodCycleScreen extends StatelessWidget {
  const PeriodCycleScreen({super.key});

  Future<void> _addPast(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: tr('¿Qué día empezó?', 'When did it start?'),
    );
    if (d == null) return;
    await AppStore.instance.addPeriod(dateOnly(d));
    if (context.mounted) toast(context, tr('Periodo añadido', 'Period added'));
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: tr('Periodo y ciclo', 'Period & cycle'),
      child: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) {
          final s = AppStore.instance;
          final today = dateOnly(DateTime.now());
          final inPeriod = s.isPeriodDay(today);
          final starts = s.periodStarts.reversed.toList();
          final lengths = s.periodLengths;
          final all = s.periodStarts;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _box(Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr('Registrar periodo', 'Log period'), style: _h),
                  const SizedBox(height: 4),
                  Text(
                      inPeriod
                          ? tr('Estás en tu periodo (día ${s.cycleDayToday}).', "You're on your period (day ${s.cycleDayToday}).")
                          : tr('Marca el primer día y rellenamos los días siguientes por ti.', "Mark the first day and we'll fill the next days."),
                      style: _b),
                  const SizedBox(height: 12),
                  if (!inPeriod)
                    PinkButton(
                      label: tr('Me ha bajado hoy', 'My period started today'),
                      icon: Icons.water_drop_rounded,
                      onTap: () async {
                        await s.addPeriod(today);
                        if (context.mounted) toast(context, tr('¡Anotado! 🩸', 'Logged! 🩸'));
                      },
                    )
                  else
                    PinkButton(
                      label: tr('Se me ha terminado hoy', 'It ended today'),
                      icon: Icons.check_rounded,
                      onTap: () async {
                        var d = addDays(today, 1);
                        while (s.isPeriodDay(d)) {
                          final l = s.logFor(d)..flow = 0;
                          await s.setLog(d, l);
                          d = addDays(d, 1);
                        }
                        if (context.mounted) toast(context, tr('Periodo cerrado', 'Period closed'));
                      },
                    ),
                  const SizedBox(height: 10),
                  PinkButton(
                    label: tr('Añadir un periodo pasado', 'Add a past period'),
                    icon: Icons.history_rounded,
                    outlined: true,
                    onTap: () => _addPast(context),
                  ),
                ],
              )),
              _box(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Mis duraciones habituales', 'My usual lengths'), style: _h),
                  const SizedBox(height: 4),
                  Text(tr('Se usan hasta que tengamos suficientes registros tuyos.', 'Used until we have enough of your logs.'), style: _b),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: Text(tr('Ciclo', 'Cycle'), style: const TextStyle(fontWeight: FontWeight.w700))),
                    Stepper2(
                        value: s.defaultCycle,
                        min: 18,
                        max: 45,
                        suffix: ' d',
                        onChanged: (v) {
                          s.defaultCycle = v;
                          s.commit();
                        }),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Text(tr('Periodo', 'Period'), style: const TextStyle(fontWeight: FontWeight.w700))),
                    Stepper2(
                        value: s.defaultPeriod,
                        min: 2,
                        max: 10,
                        suffix: ' d',
                        onChanged: (v) {
                          s.defaultPeriod = v;
                          s.commit();
                        }),
                  ]),
                ],
              )),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(tr('Historial de periodos', 'Period history'), style: _h),
              ),
              if (starts.isEmpty)
                _box(Text(tr('Todavía no hay periodos registrados.', 'No periods logged yet.'), style: _b)),
              for (final st in starts)
                Builder(builder: (context) {
                  final i = all.indexOf(st);
                  final len = lengths[i];
                  final cyc = i + 1 < all.length ? daysBetween(st, all[i + 1]) : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    decoration: card(radius: 16),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 18, backgroundColor: C.pinkSoft, child: Icon(Icons.water_drop_rounded, color: C.pink, size: 19)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(L.dateLong(st), style: const TextStyle(fontWeight: FontWeight.w800, color: C.text)),
                              Text(
                                '${tr('Periodo', 'Period')}: $len ${daysWord(len)}'
                                '${cyc != null ? ' · ${tr('Ciclo', 'Cycle')}: $cyc ${daysWord(cyc)}' : ''}',
                                style: const TextStyle(fontSize: 12, color: C.muted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: C.muted),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(tr('¿Quitar este periodo?', 'Remove this period?')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Quitar', 'Remove'))),
                                ],
                              ),
                            );
                            if (ok == true) await s.removePeriodAround(st);
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────────── Informe del ciclo ─────────────────────────────

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final cycles = s.cycleLengths;
    final recent = cycles.length > 8 ? cycles.sublist(cycles.length - 8) : cycles;
    final preds = s.predictedStarts(3);
    final counts = s.symptomCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final moods = List<int>.filled(5, 0);
    for (final l in s.logs.values) {
      if (l.mood > 0) moods[l.mood - 1]++;
    }
    final reg = s.isRegular;
    return SubPage(
      title: tr('Informe del ciclo', 'Cycle report'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _box(Row(
            children: [
              _stat('${s.avgCycle}', tr('ciclo medio', 'avg. cycle')),
              _stat('${s.avgPeriod}', tr('periodo medio', 'avg. period')),
              _stat('${s.periodStarts.length}', tr('periodos', 'periods')),
              _stat(reg == null ? '—' : (reg ? '✔' : '~'), reg == null ? tr('regularidad', 'regularity') : (reg ? tr('regular', 'regular') : tr('irregular', 'irregular'))),
            ],
          )),
          _box(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(Icons.bar_chart_rounded, tr('Duración de tus ciclos', 'Your cycle lengths')),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                Text(tr('Registra al menos 2 periodos para ver la gráfica.', 'Log at least 2 periods to see the chart.'), style: _b)
              else
                SizedBox(height: 150, child: CustomPaint(painter: _BarsPainter(recent), size: Size.infinite)),
            ],
          )),
          _box(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(Icons.auto_awesome_rounded, tr('Próximas predicciones', 'Upcoming predictions')),
              const SizedBox(height: 8),
              if (preds.isEmpty) Text(tr('Registra tu periodo para ver predicciones.', 'Log your period to see predictions.'), style: _b),
              for (final p in preds) ...[
                _predRow('🩸', tr('Periodo', 'Period'), '${L.dateShort(p)} – ${L.dateShort(addDays(p, s.avgPeriod - 1))}'),
                _predRow('🌱', tr('Días fértiles', 'Fertile days'),
                    '${L.dateShort(addDays(p, s.avgCycle - 14 - 5))} – ${L.dateShort(addDays(p, s.avgCycle - 14 + 1))}'),
                _predRow('🥚', tr('Ovulación', 'Ovulation'), L.dateShort(addDays(p, s.avgCycle - 14))),
                const Divider(color: C.pinkLine),
              ],
            ],
          )),
          _box(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(Icons.bolt_rounded, tr('Tus síntomas más frecuentes', 'Your most frequent symptoms')),
              const SizedBox(height: 10),
              if (counts.isEmpty) Text(tr('Aún no has registrado síntomas.', 'No symptoms logged yet.'), style: _b),
              for (final e in counts.take(6))
                _barRow(symptomAsset(e.key), symptomName(e.key), e.value, counts.first.value),
            ],
          )),
          _box(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(Icons.favorite_rounded, tr('Tu ánimo', 'Your mood')),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Expanded(
                      child: Column(
                        children: [
                          Img(moodImgs[i], size: 30, fallback: Icons.sentiment_satisfied_rounded, fallbackColor: C.orange),
                          Text('${moods[i]}', style: const TextStyle(fontWeight: FontWeight.w900, color: C.pinkDark, fontSize: 16)),
                          Text(moodNames[i], style: const TextStyle(fontSize: 10, color: C.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          )),
          Text(
            tr('Las predicciones son estimaciones. No uses la app como método anticonceptivo ni como diagnóstico.',
                'Predictions are estimates. Do not use the app as birth control or for diagnosis.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: C.muted),
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(
        child: Column(
          children: [
            Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.pinkDark)),
            Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _predRow(String e, String t, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(e, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: C.text))),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800, color: C.pinkDark)),
        ]),
      );

  Widget _barRow(String? asset, String name, int v, int max) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 26, child: asset != null ? Img(asset, size: 24) : const Text('✨')),
            const SizedBox(width: 6),
            SizedBox(width: 82, child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: v / math.max(max, 1),
                  minHeight: 10,
                  backgroundColor: C.pinkSoft,
                  valueColor: const AlwaysStoppedAnimation(C.pink),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$v', style: const TextStyle(fontWeight: FontWeight.w800, color: C.pinkDark)),
          ],
        ),
      );
}

class _BarsPainter extends CustomPainter {
  final List<int> values;
  _BarsPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.reduce(math.max).toDouble() + 4;
    final minV = math.max(0, values.reduce(math.min) - 6).toDouble();
    final n = values.length;
    final slot = size.width / n;
    final bw = slot * 0.55;
    final chartH = size.height - 20;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      final h = chartH * ((v - minV) / (maxV - minV)).clamp(0.08, 1.0);
      final x = i * slot + (slot - bw) / 2;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, chartH - h, bw, h), const Radius.circular(8));
      canvas.drawRRect(r, Paint()..shader = pinkGradient.createShader(r.outerRect));
      final tp = TextPainter(
        text: TextSpan(text: '$v', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: C.text)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + bw / 2 - tp.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => old.values != values;
}

// ───────────────────────────── Vida sexual ─────────────────────────────

class SexLifeScreen extends StatefulWidget {
  const SexLifeScreen({super.key});

  @override
  State<SexLifeScreen> createState() => _SexLifeScreenState();
}

class _SexLifeScreenState extends State<SexLifeScreen> {
  DateTime _day = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: tr('Vida sexual', 'Sex life'),
      child: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) {
          final s = AppStore.instance;
          final log = s.logFor(_day);
          final info = s.infoFor(_day);
          final now = DateTime.now();
          var month = 0;
          var unprot = 0;
          final history = <DateTime>[];
          s.logs.forEach((k, v) {
            if (v.sex > 0) {
              final d = parseKey(k);
              history.add(d);
              if (d.year == now.year && d.month == now.month) month++;
              if (v.sex == 2 && d.year == now.year && d.month == now.month) unprot++;
            }
          });
          history.sort((a, b) => b.compareTo(a));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _DayNav(day: _day, onChanged: (d) => setState(() => _day = d)),
              const SizedBox(height: 12),
              _box(Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(Icons.favorite_rounded, tr('¿Hubo relaciones este día?', 'Any intimacy this day?')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Choice(
                              selected: log.sex == i,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              onTap: () => s.updateLog(_day, (l) => l.sex = i),
                              child: Column(children: [
                                Text(['🚫', '🛡️', '❤️'][i], style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(sexNames[i],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.text)),
                              ]),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (info.fertile || info.ovulation) ...[
                    const SizedBox(height: 10),
                    Pill(tr('Este día está en tu ventana fértil estimada', 'This day is in your estimated fertile window'),
                        icon: Icons.eco, color: C.emerald, bg: C.greenSoft),
                  ],
                ],
              )),
              _box(Row(
                children: [
                  Expanded(
                    child: Column(children: [
                      Text('$month', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.pinkDark)),
                      Text(tr('este mes', 'this month'), style: _b),
                    ]),
                  ),
                  Expanded(
                    child: Column(children: [
                      Text('$unprot', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.pinkDark)),
                      Text(tr('sin protección', 'unprotected'), style: _b),
                    ]),
                  ),
                ],
              )),
              if (history.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 4, bottom: 6), child: Text(tr('Historial', 'History'), style: _h)),
              for (final d in history.take(30))
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: card(radius: 14),
                  child: Row(children: [
                    Text(s.logs[dayKey(d)]!.sex == 2 ? '❤️' : '🛡️'),
                    const SizedBox(width: 10),
                    Expanded(child: Text(L.dateLong(d), style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text(sexNames[s.logs[dayKey(d)]!.sex], style: const TextStyle(color: C.muted, fontSize: 12)),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Navegación de día ‹ fecha ›.
class _DayNav extends StatelessWidget {
  final DateTime day;
  final ValueChanged<DateTime> onChanged;
  const _DayNav({required this.day, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final isToday = day == today;
    return Container(
      decoration: card(radius: 18),
      child: Row(
        children: [
          IconButton(onPressed: () => onChanged(addDays(day, -1)), icon: const Icon(Icons.chevron_left_rounded, color: C.pinkDark)),
          Expanded(
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: day, firstDate: DateTime(today.year - 3), lastDate: today);
                if (d != null) onChanged(dateOnly(d));
              },
              child: Text(isToday ? '${tr('Hoy', 'Today')} · ${L.dateShort(day)}' : L.dateLong(day),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          IconButton(
            onPressed: isToday ? null : () => onChanged(addDays(day, 1)),
            icon: Icon(Icons.chevron_right_rounded, color: isToday ? C.pinkLine : C.pinkDark),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Peso, sueño y agua ─────────────────────────────

enum Metric { weight, sleep, water }

class MetricScreen extends StatefulWidget {
  final Metric kind;
  const MetricScreen({super.key, required this.kind});

  @override
  State<MetricScreen> createState() => _MetricScreenState();
}

class _MetricScreenState extends State<MetricScreen> {
  DateTime _day = dateOnly(DateTime.now());

  String get _title => switch (widget.kind) {
        Metric.weight => tr('Peso', 'Weight'),
        Metric.sleep => tr('Sueño', 'Sleep'),
        Metric.water => tr('Bebe agua', 'Drink water'),
      };

  String get _unit => switch (widget.kind) { Metric.weight => 'kg', Metric.sleep => 'h', Metric.water => tr('vasos', 'glasses') };

  double? _value(DayLog l) => switch (widget.kind) {
        Metric.weight => l.weight,
        Metric.sleep => l.sleep,
        Metric.water => l.water > 0 ? l.water.toDouble() : null,
      };

  Future<void> _set(double? v) async {
    await AppStore.instance.updateLog(_day, (l) {
      switch (widget.kind) {
        case Metric.weight:
          l.weight = v;
        case Metric.sleep:
          l.sleep = v;
        case Metric.water:
          l.water = (v ?? 0).round();
      }
    });
  }

  Future<void> _enterWeight(double? current) async {
    final c = TextEditingController(text: current != null ? fmtNum(current) : '');
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Peso (kg)', 'Weight (kg)')),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancelar', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('Guardar', 'Save'))),
        ],
      ),
    );
    if (r == null) return;
    final v = double.tryParse(r.replaceAll(',', '.'));
    if (v == null || v < 25 || v > 300) {
      await _set(null);
    } else {
      await _set(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: _title,
      child: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) {
          final s = AppStore.instance;
          final log = s.logFor(_day);
          final v = _value(log);
          final series = <MapEntry<DateTime, double>>[];
          for (final e in s.logs.entries) {
            final x = _value(e.value);
            if (x != null) series.add(MapEntry(parseKey(e.key), x));
          }
          series.sort((a, b) => a.key.compareTo(b.key));
          final last = series.length > 30 ? series.sublist(series.length - 30) : series;
          final avg = last.isEmpty ? null : last.map((e) => e.value).reduce((a, b) => a + b) / last.length;
          Widget control = const SizedBox();
          switch (widget.kind) {
            case Metric.weight:
              control = Column(children: [
                Text(v != null ? '${fmtNum(v)} kg' : '— kg', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: C.pinkDark)),
                const SizedBox(height: 10),
                PinkButton(label: tr('Anotar peso', 'Log weight'), icon: Icons.edit_rounded, onTap: () => _enterWeight(v)),
              ]);
            case Metric.sleep:
              final cur = v ?? 0;
              control = Column(children: [
                Text(v != null ? '${fmtNum(v)} h' : '— h', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: C.purple)),
                Slider(
                  value: cur.clamp(0, 14).toDouble(),
                  min: 0,
                  max: 14,
                  divisions: 28,
                  activeColor: C.purple,
                  label: '${fmtNum(cur)} h',
                  onChanged: (x) => _set(x == 0 ? null : x),
                ),
                Text(tr('Desliza para indicar las horas que dormiste', 'Slide to set the hours you slept'), style: _b),
              ]);
            case Metric.water:
              final w = log.water;
              control = Column(children: [
                Text('$w / ${s.waterGoal}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: C.blue)),
                Text(tr('vasos de agua', 'glasses of water'), style: _b),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < math.max(s.waterGoal, w); i++)
                      Icon(Icons.local_drink_rounded, size: 30, color: i < w ? C.blue : const Color(0xFFD6ECF7)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton.filledTonal(onPressed: w > 0 ? () => _set((w - 1).toDouble()) : null, icon: const Icon(Icons.remove)),
                  const SizedBox(width: 16),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: C.blue),
                    onPressed: () => _set((w + 1).toDouble()),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(tr('Objetivo diario', 'Daily goal'), style: const TextStyle(fontWeight: FontWeight.w700))),
                  Stepper2(
                      value: s.waterGoal,
                      min: 4,
                      max: 16,
                      onChanged: (x) {
                        s.waterGoal = x;
                        s.commit();
                      }),
                ]),
              ]);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _DayNav(day: _day, onChanged: (d) => setState(() => _day = d)),
              const SizedBox(height: 12),
              _box(control, padding: const EdgeInsets.all(18)),
              _box(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(Icons.show_chart_rounded, tr('Últimos registros', 'Latest entries')),
                  if (avg != null) ...[
                    const SizedBox(height: 4),
                    Text('${tr('Media', 'Average')}: ${fmtNum(double.parse(avg.toStringAsFixed(1)))} $_unit', style: _b),
                  ],
                  const SizedBox(height: 12),
                  if (last.length < 2)
                    Text(tr('Registra al menos 2 días para ver la evolución.', 'Log at least 2 days to see the trend.'), style: _b)
                  else
                    SizedBox(height: 140, child: CustomPaint(painter: _LinePainter(last.map((e) => e.value).toList()), size: Size.infinite)),
                ],
              )),
              for (final e in last.reversed.take(14))
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: card(radius: 14),
                  child: Row(children: [
                    Expanded(child: Text(L.dateLong(e.key), style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text('${fmtNum(e.value)} $_unit', style: const TextStyle(fontWeight: FontWeight.w800, color: C.pinkDark)),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  _LinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    if (maxV - minV < 1) {
      minV -= 1;
      maxV += 1;
    }
    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - 8 - (size.height - 16) * (values[i] - minV) / (maxV - minV);
      pts.add(Offset(x, y));
    }
    final area = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(pts.last.dx, size.height)
      ..close();
    canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            colors: [C.pink.withOpacity(0.30), C.pink.withOpacity(0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Offset.zero & size));
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        line,
        Paint()
          ..color = C.pinkDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
    for (final p in pts) {
      canvas.drawCircle(p, 3.5, Paint()..color = C.pink);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values;
}

// ───────────────────────────── Autoexamen de mamas ─────────────────────────────

class BreastExamScreen extends StatelessWidget {
  const BreastExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      [
        '🪞',
        tr('Mírate al espejo', 'Look in the mirror'),
        tr('Con los brazos a los lados y luego en alto, busca cambios de forma, tamaño, piel o pezón.',
            'Arms at your sides, then raised: look for changes in shape, size, skin or nipple.')
      ],
      [
        '✋',
        tr('Palpa tumbada', 'Feel while lying down'),
        tr('Con la yema de 3 dedos, haz pequeños círculos por toda la mama, de fuera hacia dentro.',
            'With 3 fingertips, make small circles across the whole breast, from outside in.')
      ],
      [
        '🔁',
        tr('Sigue un patrón', 'Follow a pattern'),
        tr('Recorre de arriba abajo para no dejarte ninguna zona, incluida la axila.',
            "Go up and down so you don't miss any area, including the armpit.")
      ],
      [
        '🚿',
        tr('Repite en la ducha', 'Repeat in the shower'),
        tr('Con la piel mojada y jabonosa es más fácil notar bultos.', 'Wet, soapy skin makes it easier to feel lumps.')
      ],
      [
        '🩺',
        tr('Consulta si notas algo', 'See a doctor if you notice anything'),
        tr('Un bulto, hundimiento, secreción o dolor nuevo: pide cita con tu médico.',
            'A lump, dimpling, discharge or new pain: book an appointment with your doctor.')
      ],
    ];
    return SubPage(
      title: tr('Autoexamen', 'Self-exam'),
      child: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) {
          final s = AppStore.instance;
          DateTime? last;
          s.logs.forEach((k, v) {
            if (v.breastExam) {
              final d = parseKey(k);
              if (last == null || d.isAfter(last!)) last = d;
            }
          });
          final today = dateOnly(DateTime.now());
          final doneToday = s.logFor(today).breastExam;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _box(Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr('Autoexamen de mamas', 'Breast self-exam'), style: _h),
                  const SizedBox(height: 4),
                  Text(
                      tr('Hazlo una vez al mes, mejor unos días después de terminar el periodo.',
                          'Do it once a month, ideally a few days after your period ends.'),
                      style: _b),
                  const SizedBox(height: 8),
                  Text(
                    last == null
                        ? tr('Aún no has registrado ningún autoexamen.', 'No self-exams logged yet.')
                        : tr('Último: ${L.dateLong(last!)}', 'Last: ${L.dateLong(last!)}'),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: C.pinkDark),
                  ),
                ],
              )),
              for (var i = 0; i < steps.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: card(radius: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: C.pinkSoft, child: Text(steps[i][0], style: const TextStyle(fontSize: 19))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}. ${steps[i][1]}', style: const TextStyle(fontWeight: FontWeight.w800, color: C.text)),
                            const SizedBox(height: 3),
                            Text(steps[i][2], style: _b),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              PinkButton(
                label: doneToday ? tr('Hecho hoy ✔', 'Done today ✔') : tr('Marcar como hecho hoy', 'Mark as done today'),
                icon: Icons.check_rounded,
                outlined: doneToday,
                onTap: () => s.updateLog(today, (l) => l.breastExam = !l.breastExam),
              ),
              const SizedBox(height: 10),
              Text(
                tr('Esta guía no sustituye a las revisiones médicas.', 'This guide does not replace medical check-ups.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: C.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────────── Cronología ─────────────────────────────

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: tr('Cronología', 'Timeline'),
      child: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) {
          final s = AppStore.instance;
          final days = s.loggedDays;
          if (days.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Img('cal_heart', size: 110, fallback: Icons.event_available),
                  const SizedBox(height: 10),
                  Text(tr('Aquí verás todo lo que registres, día a día.', "Everything you log will appear here, day by day."),
                      textAlign: TextAlign.center, style: _b),
                ]),
              ),
            );
          }
          final children = <Widget>[];
          String? lastMonth;
          for (final d in days) {
            final m = '${L.month(d.month)} ${d.year}';
            if (m != lastMonth) {
              children.add(Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 6), child: Text(m, style: _h)));
              lastMonth = m;
            }
            final l = s.logs[dayKey(d)]!;
            final info = s.infoFor(d);
            final parts = <String>[
              if (l.flow > 0) '🩸 ${flowNames[l.flow]}',
              for (final k in l.symptoms) symptomName(k),
              if (l.pain > 0) '${tr('Dolor', 'Pain')} ${painAdj[l.pain]}',
              if (l.mood > 0) '${moodEmojis[l.mood - 1]} ${moodNames[l.mood - 1]}',
              if (l.water > 0) '💧 ${l.water}',
              if (l.sleep != null) '🌙 ${fmtNum(l.sleep!)} h',
              if (l.weight != null) '⚖️ ${fmtNum(l.weight!)} kg',
              if (l.sex > 0 && AppStore.instance.showSex) '❤️',
              if (l.breastExam) '🎀',
            ];
            children.add(InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterScreen(day: d))),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: card(radius: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: l.flow > 0 ? pinkGradient : null,
                        color: l.flow > 0 ? null : C.pinkSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${d.day}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: l.flow > 0 ? Colors.white : C.pinkDark, height: 1)),
                        Text(L.monthShort(d.month),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: l.flow > 0 ? Colors.white : C.pinkDark)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.cycleDay != null ? tr('Día ${info.cycleDay} del ciclo', 'Cycle day ${info.cycleDay}') : L.dateLong(d),
                            style: const TextStyle(fontWeight: FontWeight.w800, color: C.text),
                          ),
                          const SizedBox(height: 3),
                          Text(parts.join(' · '), style: _b),
                          if (l.note.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text('“${l.note}”',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: C.text)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ));
          }
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: children);
        },
      ),
    );
  }
}

// ───────────────────────────── Ajustes ─────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: tr('Ajustes', 'Settings'),
      child: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) {
          final s = AppStore.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _box(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_rounded, color: C.pink),
                  title: Text(tr('Nombre', 'Name'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(s.name.isEmpty ? tr('Sin nombre', 'No name') : s.name),
                  trailing: const Icon(Icons.edit_rounded, color: C.muted),
                  onTap: () => editName(context),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              ),
              _box(
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.favorite_rounded, color: C.pink),
                  title: Text(tr('Registro de relaciones', 'Sex tracking'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(tr('Muestra la vida sexual en el calendario, el registro y "Mi salud". Si lo desactivas, tus datos no se borran.',
                      'Shows sex life in the calendar, logging and "My health". Turning it off does not delete your data.')),
                  value: s.showSex,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF2FB45A),
                  onChanged: (v) {
                    s.showSex = v;
                    s.commit();
                  },
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              ),
              _box(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.lock_rounded, color: C.emerald),
                    const SizedBox(width: 8),
                    Text(tr('Tu privacidad', 'Your privacy'), style: _h),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    tr('Tus registros se guardan de forma privada en tu cuenta de CicloPlus, para que no los pierdas si cambias de móvil. Nadie más puede verlos.',
                        'Your logs are stored privately in your CicloPlus account, so you won\'t lose them if you change phones. Nobody else can see them.'),
                    style: _b,
                  ),
                ],
              )),
              _box(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded, color: C.pink),
                    const SizedBox(width: 8),
                    Text(tr('Aviso', 'Notice'), style: _h),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    tr('Las predicciones son estimaciones basadas en tus registros. No es un producto sanitario ni un método anticonceptivo.',
                        'Predictions are estimates based on your logs. This is not a medical device or a birth control method.'),
                    style: _b,
                  ),
                ],
              )),
              _box(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_circle_rounded, color: C.pink),
                  title: Text(tr('Cuenta', 'Account'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(GoSession.user?.email ?? ''),
                  trailing: TextButton(
                    onPressed: () async {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      await GoSession.onSignOut?.call();
                    },
                    child: Text(tr('Cerrar sesión', 'Sign out'), style: const TextStyle(color: C.pinkDark, fontWeight: FontWeight.w800)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              ),
              _box(Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.privacy_tip_rounded, color: C.pink),
                    title: Text(tr('Política de privacidad', 'Privacy policy'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.open_in_new_rounded, color: C.muted, size: 18),
                    onTap: () => launchUrl(Uri.parse(privacyPolicyUrlFor(LocaleController.instance.languageCode)), mode: LaunchMode.externalApplication),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_rounded, color: C.pink),
                    title: Text(tr('Términos de uso', 'Terms of use'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.open_in_new_rounded, color: C.muted, size: 18),
                    onTap: () => launchUrl(Uri.parse(termsOfUseUrlFor(LocaleController.instance.languageCode)), mode: LaunchMode.externalApplication),
                  ),
                ],
              ), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
              const SizedBox(height: 6),
              PinkButton(
                label: tr('Borrar todos mis datos', 'Delete all my data'),
                icon: Icons.delete_forever_rounded,
                outlined: true,
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(tr('¿Borrar todo?', 'Delete everything?')),
                      content: Text(tr('Se borrarán todos tus registros y ajustes. No se puede deshacer.',
                          'All your logs and settings will be deleted. This cannot be undone.')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: C.pinkDark),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(tr('Borrar', 'Delete')),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await s.resetAll();
                    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Center(child: Text('CicloPlus', style: TextStyle(color: C.muted, fontWeight: FontWeight.w700))),
            ],
          );
        },
      ),
    );
  }
}
