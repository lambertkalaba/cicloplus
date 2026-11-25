import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../cicloplus_host.dart' show CicloData;
import '../../services/settings_service.dart';
import '../cicloplus_links.dart';
import '../data/store.dart';
import '../strings.dart';
import 'ui.dart';

/// Extras del ciclo: margen de predicción, patrones personales, registro
/// en un toque, modo perimenopausia y ajustes de privacidad.
class CyclePlus {
  CyclePlus._();

  /// Días de margen alrededor de la próxima regla (null = ciclo regular).
  static int? spread() {
    final s = AppStore.instance;
    final c = s.cycleLengths;
    final recent = c.length > 6 ? c.sublist(c.length - 6) : c;
    // "Mi ciclo es irregular" (Configuración > Configuración de predicción)
    // también da un margen de fechas, como el modo perimenopausia.
    if (s.perimenopause || CicloData.instance.irregular) {
      // Siempre algo más amplio que el margen "normal", para que activar
      // el interruptor se note aunque los ciclos ya varíen un poco.
      if (recent.length < 2) return 5;
      final r = recent.reduce(math.max) - recent.reduce(math.min);
      return (r ~/ 2 + 1).clamp(4, 10);
    }
    // Interruptor apagado: fecha exacta, como promete el texto del ajuste
    // ("Te mostramos un margen de fechas en vez de un día exacto").
    return null;
  }

  /// Texto "Periodo entre el X y el Y" si el ciclo es irregular.
  static String? rangeLabel() {
    final sp = spread();
    final next = AppStore.instance.nextPeriod;
    if (sp == null || next == null) return null;
    final a = addDays(next, -sp), b = addDays(next, sp);
    return tr('Periodo entre el {} y el {}', 'Period between {} and {}').replaceFirst('{}', L.dateShort(a)).replaceFirst('{}', L.dateShort(b));
  }

  // ───────────── Patrones personales ─────────────

  static int _bucket(DateTime d) {
    final s = AppStore.instance;
    final info = s.infoFor(d);
    if (info.period) return 0; // durante la regla
    // Los 5 días antes de una regla registrada.
    for (final st in s.periodStarts) {
      final diff = daysBetween(d, st);
      if (diff >= 1 && diff <= 5) return 1;
    }
    if (info.fertile || info.ovulation) return 2; // días fértiles
    return 3;
  }

  static String _when(int b) => [
        tr('durante la regla', 'during your period'),
        tr('los días antes de la regla', 'in the days before your period'),
        tr('en tus días fértiles', 'on your fertile days'),
        tr('el resto del ciclo', 'the rest of your cycle'),
      ][b];

  /// Frases tipo "Sueles tener dolor de cabeza los días antes de la regla".
  static List<String> patterns() {
    final s = AppStore.instance;
    final days = List.filled(4, 0);
    final hits = <String, List<int>>{};
    void hit(String k, int b) => (hits[k] ??= List.filled(4, 0))[b]++;
    for (final e in s.logs.entries) {
      if (e.value.isEmpty) continue;
      final d = DateTime.tryParse(e.key);
      if (d == null) continue;
      final b = _bucket(d);
      days[b]++;
      for (final k in e.value.symptoms) {
        hit(k, b);
      }
      if (e.value.pain >= 2) hit('_pain', b);
      if (e.value.mood == 2) hit('_tired', b);
      if ((e.value.sleep ?? 99) < 6) hit('_sleep', b);
    }
    final out = <(double, String)>[];
    for (final h in hits.entries) {
      for (var b = 0; b < 3; b++) {
        if (h.value[b] < 3 || days[b] < 4) continue;
        final rate = h.value[b] / days[b];
        final restDays = days.asMap().entries.where((x) => x.key != b).fold<int>(0, (a, x) => a + x.value);
        final restHits = h.value.asMap().entries.where((x) => x.key != b).fold<int>(0, (a, x) => a + x.value);
        final rest = restDays == 0 ? 0.0 : restHits / restDays;
        if (rate < 0.4 || rate < rest * 1.8) continue;
        final what = switch (h.key) {
          '_pain' => tr('Sueles tener más dolor {}', 'You usually have more pain {}'),
          '_tired' => tr('Sueles estar más cansada {}', 'You are usually more tired {}'),
          '_sleep' => tr('Sueles dormir menos {}', 'You usually sleep less {}'),
          _ => tr('Sueles tener «{}» {}', 'You usually have "{}" {}').replaceFirst('{}', symptomName(h.key).toLowerCase()),
        };
        out.add((rate - rest, what.replaceFirst('{}', _when(b))));
      }
    }
    out.sort((a, b) => b.$1.compareTo(a.$1));
    return out.take(3).map((e) => e.$2).toList();
  }
}

/// Registro en un toque: regla, dolor y agua sin abrir pantallas.
class QuickLogRow extends StatelessWidget {
  const QuickLogRow({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final today = dateOnly(DateTime.now());
    final log = s.logFor(today);
    final inPeriod = log.flow > 0;
    Widget btn(String emoji, String label, bool on, VoidCallback tap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: on ? C.pinkSoft : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  tap();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: on ? C.pink : C.pinkLine)),
                  child: Column(children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: C.text)),
                  ]),
                ),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(tr('Registro rápido', 'Quick log'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.text)),
        ),
        Row(children: [
          btn('🩸', inPeriod ? tr('Con regla', 'On period') : tr('Me vino', 'Started'), inPeriod, () {
            if (inPeriod) {
              s.markPeriodEnded().then((_) => s.updateLog(today, (l) => l.flow = 0));
            } else if (s.infoFor(addDays(today, -1)).period) {
              s.updateLog(today, (l) => l.flow = 2);
            } else {
              s.addPeriod(today);
            }
          }),
          btn('😣', log.pain >= 2 ? tr('Con dolor', 'In pain') : tr('Dolor', 'Pain'), log.pain >= 2, () => s.updateLog(today, (l) => l.pain = l.pain >= 2 ? 0 : 2)),
          btn('💧', '${log.water} ${tr('vasos', 'glasses')}', log.water >= s.waterGoal, () => s.updateLog(today, (l) => l.water = l.water + 1)),
          btn('😴', log.sleep == null ? tr('Dormí mal', 'Slept badly') : '${log.sleep!.toStringAsFixed(0)} h', (log.sleep ?? 99) < 6,
              () => s.updateLog(today, (l) => l.sleep = (l.sleep != null && l.sleep! < 6) ? null : 5)),
        ]),
      ]),
    );
  }
}

/// Patrones personales detectados en sus registros.
class PatternsCard extends StatelessWidget {
  const PatternsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = CyclePlus.patterns();
    final peri = AppStore.instance.perimenopause;
    if (p.isEmpty && !peri) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🔎 ${tr('Tus patrones', 'Your patterns')}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: C.purple)),
        const SizedBox(height: 6),
        for (final t in p)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $t', style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: C.text)),
          ),
        if (peri)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
                tr('Modo perimenopausia: tus ciclos pueden variar mucho, por eso te mostramos un margen de fechas. Apunta sofocos o sudores nocturnos en síntomas.',
                    'Perimenopause mode: your cycles can vary a lot, so we show a date range. Log hot flushes or night sweats as symptoms.'),
                style: const TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, color: C.muted)),
          ),
        if (p.isNotEmpty)
          Text(tr('Basado en tus registros. No es un diagnóstico.', 'Based on your logs. Not a diagnosis.'),
              style: const TextStyle(fontSize: 10.5, color: C.muted)),
      ]),
    );
  }
}

/// Ajustes extra de ciclo y privacidad (en las dos pantallas de Configuración).
class CycleExtraSettings extends StatelessWidget {
  const CycleExtraSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Column(children: [
        if (!s.pregnant) SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Text('🌗', style: TextStyle(fontSize: 22)),
          title: Text(tr('Modo perimenopausia', 'Perimenopause mode'), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(tr('Para ciclos que cambian mucho: muestra un margen de fechas y añade sofocos y sudores nocturnos a tus síntomas.',
              'For cycles that change a lot: shows a date range and adds hot flushes and night sweats to your symptoms.')),
          value: s.perimenopause,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF2FB45A),
          onChanged: (v) {
            s.perimenopause = v;
            if (v) {
              for (final x in [tr('Sofocos', 'Hot flushes'), tr('Sudores nocturnos', 'Night sweats')]) {
                if (!s.customSymptoms.contains(x)) s.customSymptoms.add(x);
              }
            }
            s.commit();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Text('🤫', style: TextStyle(fontSize: 22)),
          title: Text(tr('Avisos discretos', 'Discreet notifications'), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(tr('Los recordatorios no mencionan la regla ni la ovulación: solo dicen "Tienes un recordatorio".',
              'Reminders never mention your period or ovulation: they just say "You have a reminder".')),
          value: s.discreetNotifs,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF2FB45A),
          onChanged: (v) {
            s.discreetNotifs = v;
            s.commit();
          },
        ),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) const DiscreetIconTile(),
        const PinLockTile(),
      ]),
    );
  }
}

/// Icono discreto (solo Android): cambia el icono y el nombre de la app
/// por un cuaderno llamado "Diario". Ver MainActivity.kt.
class DiscreetIconTile extends StatefulWidget {
  const DiscreetIconTile({super.key});
  @override
  State<DiscreetIconTile> createState() => _DiscreetIconTileState();
}

class _DiscreetIconTileState extends State<DiscreetIconTile> {
  static const _ch = MethodChannel('cicloplus/icon');
  bool? _on;

  @override
  void initState() {
    super.initState();
    _ch.invokeMethod<bool>('isDiscreet').then((v) {
      if (mounted) setState(() => _on = v ?? false);
    }).catchError((_) {
      if (mounted) setState(() => _on = false);
    });
  }

  Future<void> _set(bool v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(v ? tr('¿Cambiar el icono?', 'Change the icon?') : tr('¿Volver al icono normal?', 'Back to the normal icon?')),
        content: Text(v
            ? tr('La app aparecerá como un cuaderno llamado "Diario". El icono actual desaparecerá de tu pantalla de inicio: búscala en tus aplicaciones y vuelve a colocarla donde quieras. Tus datos no cambian.',
                'The app will appear as a notebook called "Journal". The current icon will disappear from your home screen: find it in your apps and place it again wherever you like. Your data does not change.')
            : tr('Volverá el icono de CicloPlus. Puede que tengas que colocarlo de nuevo en tu pantalla de inicio.',
                'The CicloPlus icon will come back. You may need to place it on your home screen again.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancelar', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Cambiar', 'Change'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _ch.invokeMethod('setDiscreet', v);
      if (mounted) setState(() => _on = v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const Text('📓', style: TextStyle(fontSize: 22)),
      title: Text(tr('Icono discreto', 'Discreet icon'), style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(tr('Cambia el icono de la app por un cuaderno llamado "Diario".', 'Changes the app icon to a notebook called "Journal".')),
      value: _on ?? false,
      activeColor: Colors.white,
      activeTrackColor: const Color(0xFF2FB45A),
      onChanged: _on == null ? null : _set,
    );
  }
}

/// Textos discretos para las notificaciones.
class DiscreetNotif {
  DiscreetNotif._();
  static bool get on => AppStore.instance.discreetNotifs;

  /// Si Michi está activado, los avisos los "manda" él: su nombre en el
  /// título, un maullido al empezar y su carita como imagen del aviso.
  static bool get michi => !on && AppStore.instance.showMichi;

  static String title(String t) => on ? 'CicloPlus' : (michi ? '🐱 Michi · $t' : t);
  static String body(String b) => on
      ? tr('Tienes un recordatorio 🌸', 'You have a reminder 🌸')
      : (michi ? tr('¡Miau! {}', 'Meow! {}').replaceFirst('{}', b) : b);

  /// Carita de Michi para el aviso (Android). null = icono normal.
  static AndroidBitmap<Object>? get largeIcon => michi ? const DrawableResourceAndroidBitmap('widget_michi_happy') : null;
}


/// Bloqueo con PIN: interruptor que muestra si está activado. Para quitarlo
/// pide el PIN actual.
class PinLockTile extends StatefulWidget {
  const PinLockTile({super.key});
  @override
  State<PinLockTile> createState() => _PinLockTileState();
}

class _PinLockTileState extends State<PinLockTile> {
  bool? _on;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final on = await SettingsService().hasPin();
    if (mounted) setState(() => _on = on);
  }

  Future<void> _toggle() async {
    await CP.togglePin(context);
    await _load();
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Text('🔒', style: TextStyle(fontSize: 22)),
        title: Text(tr('Bloqueo con PIN o huella', 'PIN or fingerprint lock'), style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(_on == true
            ? tr('Activado. Para quitarlo te pediremos tu PIN.', 'On. To remove it we will ask for your PIN.')
            : tr('Pide tu PIN (o tu huella / Face ID) al abrir la app.', 'Asks for your PIN (or fingerprint / Face ID) when opening the app.')),
        value: _on ?? false,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF2FB45A),
        onChanged: _on == null ? null : (_) => _toggle(),
      );
}
