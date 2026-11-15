import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/notifications.dart';
import '../strings.dart';
import '../widgets/ui.dart';

/// Pestaña Recordatorios: Mi ciclo, Mi salud y Mis hábitos.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  String _time(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Future<int?> _pickTime(BuildContext context, int minutes) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Future<void> _set(void Function(ReminderSettings r) f, {bool turningOn = false}) async {
    final s = AppStore.instance;
    f(s.reminders);
    if (turningOn) await Notifier.instance.requestPermission();
    await s.commit();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final s = AppStore.instance;
        final r = s.reminders;
        final next = s.predictedStarts(1);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Recordatorios', 'Reminders'), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: C.text)),
                      const SizedBox(height: 2),
                      Text(tr('No olvides lo importante.\nConfigura tus avisos.', "Don't forget what matters.\nSet up your alerts."),
                          style: const TextStyle(fontSize: 13, color: C.text, fontWeight: FontWeight.w600, height: 1.35)),
                      if (next.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Pill('${tr('Próximo periodo', 'Next period')}: ${L.dateShort(next.first)}',
                            img: 'n_drop', color: C.pinkDark, bg: C.pinkSoft),
                      ],
                    ],
                  ),
                ),
                const Img('cal_clock', size: 96, fallback: Icons.alarm_rounded),
              ],
            ),
            const SizedBox(height: 12),
            _group(Icons.calendar_month_rounded, tr('Mi ciclo', 'My cycle'), [
              _row(
                icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF2A516), size: 26),
                title: tr('Aviso de periodo', 'Period alert'),
                subtitle: tr('${r.periodDaysBefore} ${daysWord(r.periodDaysBefore)} antes, 09:00', '${r.periodDaysBefore} ${daysWord(r.periodDaysBefore)} before, 09:00'),
                value: r.period,
                onChanged: (v) => _set((x) => x.period = v, turningOn: v),
                extra: r.period
                    ? Row(children: [
                        Expanded(child: Text(tr('Días antes', 'Days before'), style: _small)),
                        Stepper2(value: r.periodDaysBefore, min: 1, max: 7, suffix: ' d', onChanged: (v) => _set((x) => x.periodDaysBefore = v)),
                      ])
                    : null,
              ),
              _row(
                icon: const Img('target', size: 28),
                title: tr('Aviso de ovulación', 'Ovulation alert'),
                subtitle: tr('El mismo día, 09:00', 'Same day, 09:00'),
                value: r.ovulation,
                onChanged: (v) => _set((x) => x.ovulation = v, turningOn: v),
              ),
              _row(
                icon: const Img('leaf', size: 28),
                title: tr('Ventana fértil', 'Fertile window'),
                subtitle: tr('Inicio y fin, 09:00', 'Start and end, 09:00'),
                value: r.fertile,
                onChanged: (v) => _set((x) => x.fertile = v, turningOn: v),
              ),
              _row(
                icon: const Img('cal_check', size: 28),
                title: tr('Registrar mi día', 'Log my day'),
                subtitle: tr('Cada día, ${_time(r.dailyMinutes)}', 'Every day, ${_time(r.dailyMinutes)}'),
                value: r.daily,
                onChanged: (v) => _set((x) => x.daily = v, turningOn: v),
                onTapSubtitle: () async {
                  final m = await _pickTime(context, r.dailyMinutes);
                  if (m != null) await _set((x) => x.dailyMinutes = m);
                },
              ),
              _row(
                icon: const Text('💊', style: TextStyle(fontSize: 22)),
                title: tr('Píldora anticonceptiva', 'Birth control pill'),
                subtitle: tr('Cada día, ${_time(r.pillMinutes)}', 'Every day, ${_time(r.pillMinutes)}'),
                value: r.pill,
                onChanged: (v) => _set((x) => x.pill = v, turningOn: v),
                onTapSubtitle: () async {
                  final m = await _pickTime(context, r.pillMinutes);
                  if (m != null) await _set((x) => x.pillMinutes = m);
                },
              ),
            ]),
            const SizedBox(height: 12),
            _group(Icons.favorite_rounded, tr('Mi salud', 'My health'), [
              _row(
                icon: const Img('q_water', size: 28),
                title: tr('Bebe agua', 'Drink water'),
                subtitle: tr('Cada 2 horas (09:00 - 21:00)', 'Every 2 hours (09:00 - 21:00)'),
                value: r.water,
                onChanged: (v) => _set((x) => x.water = v, turningOn: v),
              ),
              _row(
                icon: const Img('q_weight', size: 28),
                title: tr('Registro de peso', 'Weight log'),
                subtitle: tr('1 vez por semana (lunes, 09:00)', 'Once a week (Monday, 09:00)'),
                value: r.weight,
                onChanged: (v) => _set((x) => x.weight = v, turningOn: v),
              ),
              _row(
                icon: const Img('q_breast', size: 28),
                title: tr('Autoexamen de mamas', 'Breast self-exam'),
                subtitle: tr('1 vez al mes (día ${r.breastExamDay})', 'Once a month (day ${r.breastExamDay})'),
                value: r.breastExam,
                onChanged: (v) => _set((x) => x.breastExam = v, turningOn: v),
                extra: r.breastExam
                    ? Row(children: [
                        Expanded(child: Text(tr('Día del mes', 'Day of month'), style: _small)),
                        Stepper2(value: r.breastExamDay, min: 1, max: 28, onChanged: (v) => _set((x) => x.breastExamDay = v)),
                      ])
                    : null,
              ),
            ]),
            const SizedBox(height: 12),
            _group(Icons.directions_run_rounded, tr('Mis hábitos', 'My habits'), [
              _row(
                icon: const Text('🏃‍♀️', style: TextStyle(fontSize: 22)),
                title: tr('Actividad física', 'Physical activity'),
                subtitle: tr('Diario, ${_time(r.activityMinutes)}', 'Daily, ${_time(r.activityMinutes)}'),
                value: r.activity,
                onChanged: (v) => _set((x) => x.activity = v, turningOn: v),
                onTapSubtitle: () async {
                  final m = await _pickTime(context, r.activityMinutes);
                  if (m != null) await _set((x) => x.activityMinutes = m);
                },
              ),
              _row(
                icon: const Img('q_sleep', size: 28),
                title: tr('Hora de dormir', 'Bedtime'),
                subtitle: tr('Todos los días, ${_time(r.bedtimeMinutes)}', 'Every day, ${_time(r.bedtimeMinutes)}'),
                value: r.bedtime,
                onChanged: (v) => _set((x) => x.bedtime = v, turningOn: v),
                onTapSubtitle: () async {
                  final m = await _pickTime(context, r.bedtimeMinutes);
                  if (m != null) await _set((x) => x.bedtimeMinutes = m);
                },
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              tr('Los recordatorios funcionan sin internet. Toca la hora en rosa para cambiarla.',
                  'Reminders work offline. Tap the pink time to change it.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: C.muted),
            ),
          ],
        );
      },
    );
  }

  Widget _group(IconData icon, String title, List<Widget> rows) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
        decoration: card(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.only(right: 6, bottom: 2), child: SectionTitle(icon, title)),
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i < rows.length - 1) const Divider(height: 1, color: C.pinkLine),
            ],
          ],
        ),
      );

  Widget _row({
    required Widget icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onTapSubtitle,
    Widget? extra,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 34, child: Center(child: icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: C.text)),
                    GestureDetector(
                      onTap: onTapSubtitle,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(subtitle,
                                style: TextStyle(
                                    fontSize: 12, color: onTapSubtitle != null ? C.pinkDark : C.muted, fontWeight: FontWeight.w600)),
                          ),
                          if (onTapSubtitle != null) const Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.edit_rounded, size: 12, color: C.pinkDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF2FB45A),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE3DDE1),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
          if (extra != null) Padding(padding: const EdgeInsets.fromLTRB(44, 4, 6, 2), child: extra),
        ],
      ),
    );
  }
}

const _small = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.text);
