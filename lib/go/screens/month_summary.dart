import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';

/// "Tu mes": tarjeta bonita con el resumen del mes actual que se puede
/// compartir como imagen (WhatsApp, Instagram…).
class MonthSummaryScreen extends StatefulWidget {
  const MonthSummaryScreen({super.key});

  @override
  State<MonthSummaryScreen> createState() => _MonthSummaryScreenState();
}

class _MonthSummaryScreenState extends State<MonthSummaryScreen> {
  final _key = GlobalKey();
  late DateTime _month;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cicloplus_mes.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: tr('Mi mes en CicloPlus', 'My month on CicloPlus'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('No se pudo compartir', 'Could not share'))));
      }
    }
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final first = _month;
    final last = DateTime(_month.year, _month.month + 1, 0);
    final today = dateOnly(DateTime.now());
    var logged = 0, periodDays = 0, waterSum = 0, waterDays = 0;
    final symptomCount = <String, int>{};
    final moodCount = <int, int>{};
    double sleepSum = 0;
    var sleepDays = 0;
    for (var d = first; !d.isAfter(last) && !d.isAfter(today); d = addDays(d, 1)) {
      final l = s.logFor(d);
      final any = l.flow > 0 || l.symptoms.isNotEmpty || l.mood > 0 || l.water > 0 || l.sleep != null || l.note.isNotEmpty;
      if (any) logged++;
      if (l.flow > 0) periodDays++;
      for (final k in l.symptoms) {
        symptomCount[k] = (symptomCount[k] ?? 0) + 1;
      }
      if (l.mood > 0) moodCount[l.mood] = (moodCount[l.mood] ?? 0) + 1;
      if (l.water > 0) {
        waterSum += l.water;
        waterDays++;
      }
      if (l.sleep != null) {
        sleepSum += l.sleep!;
        sleepDays++;
      }
    }
    String? topSymptom;
    if (symptomCount.isNotEmpty) {
      topSymptom = (symptomCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    }
    int? topMood;
    if (moodCount.isNotEmpty) {
      topMood = (moodCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    }

    Widget stat(String emoji, String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.text)),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8A7280))),
              ],
            ),
          ),
        );

    final card = RepaintBoundary(
      key: _key,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [C.t(0xFFFFE1EC), Color(0xFFF7E6FF), Color(0xFFE3F1DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Img('logo_flower', size: 26),
                const SizedBox(width: 6),
                Text('CicloPlus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.pinkDark)),
                const Spacer(),
                const Img('hibiscus', size: 44),
              ],
            ),
            const SizedBox(height: 6),
            Text(tr('Tu mes', 'Your month'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF8A7280))),
            Text('${L.month(_month.month)} ${_month.year}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.text)),
            const SizedBox(height: 14),
            Row(
              children: [
                if (AppStore.instance.pregnant && AppStore.instance.pregnancyWeek != null)
                  stat('🤰', '${AppStore.instance.pregnancyWeek}', tr('Semana de embarazo', 'Pregnancy week'))
                else
                  stat('🩸', '$periodDays', tr('Días de regla', 'Period days')),
                const SizedBox(width: 8),
                stat('📝', '$logged', tr('Días registrados', 'Days logged')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                stat('💧', waterDays == 0 ? '—' : (waterSum / waterDays).toStringAsFixed(1), tr('Agua', 'Water')),
                const SizedBox(width: 8),
                stat('🌙', sleepDays == 0 ? '—' : '${(sleepSum / sleepDays).toStringAsFixed(1)} h', tr('Sueño', 'Sleep')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        if (topMood != null) Img(moodImgs[topMood - 1], size: 40) else const Text('🙂', style: TextStyle(fontSize: 30)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('Ánimo', 'Mood'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8A7280))),
                              Text(topMood != null ? moodNames[topMood - 1] : '—',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: C.text)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        if (topSymptom != null && symptomAsset(topSymptom) != null)
                          Img(symptomAsset(topSymptom)!, size: 40)
                        else
                          const Text('✨', style: TextStyle(fontSize: 30)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('Síntomas', 'Symptoms'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8A7280))),
                              Text(topSymptom != null ? symptomName(topSymptom) : '—',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.text)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return SubPage(
      title: tr('Tu mes', 'Your month'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                icon: Icon(Icons.chevron_left_rounded, color: C.pinkDark),
              ),
              Text('${L.month(_month.month)} ${_month.year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.text)),
              IconButton(
                onPressed: _month.year == DateTime.now().year && _month.month == DateTime.now().month
                    ? null
                    : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                icon: Icon(Icons.chevron_right_rounded, color: C.pinkDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          card,
          const SizedBox(height: 18),
          PinkButton(
            label: tr('Compartir', 'Share'),
            icon: Icons.ios_share_rounded,
            onTap: _sharing ? () {} : _share,
          ),
        ],
      ),
    );
  }
}
