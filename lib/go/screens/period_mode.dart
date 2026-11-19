import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../services/notifications.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'michi_more.dart' show showMichiPeriodKit;

/// Temporizador para cambiar la compresa, el tampón o la copa: guarda la
/// hora del aviso y programa una notificación.
class PadTimer extends ChangeNotifier {
  PadTimer._();
  static final PadTimer instance = PadTimer._();
  static const _notifId = 4000;

  /// tipo → horas por defecto.
  static const types = <String, int>{'pad': 4, 'tampon': 4, 'cup': 8, 'underwear': 8};

  static String label(String t) => switch (t) {
        'tampon' => tr('Tampón', 'Tampon'),
        'cup' => tr('Copa', 'Cup'),
        'underwear' => tr('Braga menstrual', 'Period underwear'),
        _ => tr('Compresa', 'Pad'),
      };

  static String emoji(String t) => switch (t) {
        'tampon' => '🌸',
        'cup' => '🍷',
        'underwear' => '🩲',
        _ => '🩹',
      };

  bool _loaded = false;
  DateTime? until;
  String type = 'pad';
  int hours = 4;

  bool get running => until != null && until!.isAfter(DateTime.now());

  void ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    SharedPreferences.getInstance().then((p) {
      final ms = p.getInt('pad_until');
      until = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      type = p.getString('pad_type') ?? 'pad';
      hours = p.getInt('pad_hours') ?? types[type] ?? 4;
      notifyListeners();
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    if (until == null) {
      await p.remove('pad_until');
    } else {
      await p.setInt('pad_until', until!.millisecondsSinceEpoch);
    }
    await p.setString('pad_type', type);
    await p.setInt('pad_hours', hours);
    notifyListeners();
  }

  Future<void> setType(String t) {
    type = t;
    hours = types[t] ?? 4;
    return _save();
  }

  Future<void> setHours(int h) {
    hours = h.clamp(1, 12).toInt();
    return _save();
  }

  Future<void> start() async {
    until = DateTime.now().add(Duration(hours: hours));
    await _save();
    await Notifier.instance.requestPermission();
    await Notifier.instance.once(
      _notifId,
      tr('Hora de cambiarte 🩸', 'Time to change 🩸'),
      tr('Han pasado {} h. Hora de cambiar: {}.', "It's been {} h. Time to change: {}.")
          .replaceFirst('{}', '$hours')
          .replaceFirst('{}', label(type).toLowerCase()),
      until!,
    );
  }

  Future<void> stop() async {
    until = null;
    await _save();
    await Notifier.instance.cancelOnce(_notifId);
  }
}

/// Tarjeta de Hoy los días de regla: consejos rápidos y temporizador.
class PeriodModeCard extends StatefulWidget {
  const PeriodModeCard({super.key, this.force = false});

  /// true = se enseña aunque hoy no sea día de regla (desde el buscador).
  final bool force;

  @override
  State<PeriodModeCard> createState() => _PeriodModeCardState();
}

class _PeriodModeCardState extends State<PeriodModeCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    PadTimer.instance.ensureLoaded();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// Día de la regla de hoy (1 = primer día).
  int _periodDay(DateTime today) {
    final s = AppStore.instance;
    var n = 0;
    var d = today;
    while (s.isPeriodDay(d) && n < 15) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  String _left(Duration d) {
    if (d.isNegative) return '0 min';
    final h = d.inHours, m = d.inMinutes % 60;
    return h > 0 ? '$h h ${m.toString().padLeft(2, '0')} min' : '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final pt = PadTimer.instance;
    return ListenableBuilder(
      listenable: pt,
      builder: (context, _) {
        final today = dateOnly(DateTime.now());
        final onPeriod = AppStore.instance.isPeriodDay(today);
        if (!widget.force && !onPeriod && !pt.running) return const SizedBox.shrink();
        final day = _periodDay(today);
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🩸', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        onPeriod
                            ? tr('Estás con la regla · día {}', 'On your period · day {}').replaceFirst('{}', '$day')
                            : tr('Temporizador', 'Timer'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.text),
                      ),
                    ),
                  ],
                ),
                if (onPeriod) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => showMichiPeriodKit(context),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tip('🫖', tr('Calor en la tripa', 'Warmth on your tummy')),
                        _tip('🍵', tr('Algo calentito', 'Something warm')),
                        _tip('🧘‍♀️', tr('Estiramientos suaves', 'Gentle stretches')),
                        _tip('🥬', tr('Come algo con hierro', 'Eat something with iron')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: C.pink, borderRadius: BorderRadius.circular(14)),
                          child: Text(tr('Ver más consejos ›', 'More tips ›'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(color: C.pinkBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.pinkLine)),
                  child: pt.running ? _running(pt) : _setup(pt),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tip(String e, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: C.pinkSoft, borderRadius: BorderRadius.circular(14)),
        child: Text('$e $t', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.pinkDark)),
      );

  Widget _setup(PadTimer pt) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('¿Te avisamos para cambiarte?', 'Want a reminder to change?'),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.text)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final t in PadTimer.types.keys)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Choice(
                      selected: pt.type == t,
                      onTap: () => pt.setType(t),
                      child: Column(
                        children: [
                          Text(PadTimer.emoji(t), style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(PadTimer.label(t),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: C.text)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(tr('Avisarme en', 'Remind me in'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.text))),
              Stepper2(value: pt.hours, min: 1, max: 12, suffix: ' h', onChanged: pt.setHours),
            ],
          ),
          if (pt.type == 'tampon' && pt.hours > 8)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(tr('Un tampón no debe llevarse más de 8 horas.', 'A tampon should not be worn for more than 8 hours.'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.pinkDark)),
            ),
          const SizedBox(height: 10),
          PinkButton(label: tr('Empezar ahora', 'Start now'), icon: Icons.timer_rounded, onTap: pt.start),
        ],
      );

  Widget _running(PadTimer pt) {
    final left = pt.until!.difference(DateTime.now());
    return Row(
      children: [
        Text(PadTimer.emoji(pt.type), style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(PadTimer.label(pt.type), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.text)),
              Text(tr('Te aviso en {}', "I'll remind you in {}").replaceFirst('{}', _left(left)),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: C.pinkDark)),
            ],
          ),
        ),
        TextButton(
          onPressed: pt.start,
          child: Text(tr('Me he cambiado', 'I changed'), style: TextStyle(color: C.pinkDark, fontWeight: FontWeight.w800)),
        ),
        IconButton(onPressed: pt.stop, icon: const Icon(Icons.close_rounded, color: C.muted), tooltip: tr('Parar', 'Stop')),
      ],
    );
  }
}
