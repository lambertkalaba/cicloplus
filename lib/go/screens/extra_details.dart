import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';

/// "Más detalles" del registro: todo lo que CicloPlus ya permitía anotar y
/// el diseño nuevo no tenía (temperatura basal, moco cervical, manchado,
/// energía, medicación, piel y cabello, autoexamen de mamas y detalles de
/// la vida sexual). Se guarda en los mismos campos de siempre.
class ExtraDetails extends StatelessWidget {
  const ExtraDetails({super.key, required this.log, required this.onChanged, this.showSex = true});

  final DayLog log;
  final VoidCallback onChanged;
  final bool showSex;

  Map<String, dynamic> get x => log.extra;

  static List<List<String>> get _mucus => [
        ['dry', '🏜️', tr('Seco', 'Dry')],
        ['sticky', '🔸', tr('Pegajoso', 'Sticky')],
        ['creamy', '🥛', tr('Cremoso', 'Creamy')],
        ['watery', '💧', tr('Acuoso', 'Watery')],
        ['eggwhite', '🥚', tr('Clara de huevo', 'Egg white')],
      ];
  static List<List<String>> get _spotting => [
        ['brown', '🟤', tr('Marrón', 'Brown')],
        ['pink', '🩷', tr('Rosa', 'Pink')],
        ['red', '🔴', tr('Rojo', 'Red')],
      ];
  static List<List<String>> get _energy => [
        ['baja', '🪫', tr('Baja', 'Low')],
        ['media', '🔋', tr('Media', 'Medium')],
        ['alta', '⚡', tr('Alta', 'High')],
        ['con_energia', '✨', tr('Con energía', 'Energized')],
      ];
  static List<List<String>> get _meds => [
        ['analgesico', '💊', tr('Analgésico', 'Painkiller')],
        ['anticonceptivo', '💊', tr('Anticonceptivo', 'Birth control')],
        ['antiinflamatorio', '💊', tr('Antiinflamatorio', 'Anti-inflammatory')],
        ['vitaminas', '💊', tr('Vitaminas', 'Vitamins')],
        ['hierro', '💊', tr('Hierro', 'Iron')],
        ['otro', '💊', tr('Otro', 'Other')],
      ];
  static List<List<String>> get _skin => [
        ['brillo_saludable', '✨', tr('Brillo saludable', 'Healthy glow')],
        ['enrojecimiento', '🔴', tr('Enrojecimiento', 'Redness')],
        ['piel_reseca', '🏜️', tr('Piel reseca', 'Dry skin')],
        ['piel_grasa', '💧', tr('Piel con grasa', 'Oily skin')],
        ['buen_dia_cabello', '💇', tr('Buen día de pelo', 'Good hair day')],
        ['mal_dia_cabello', '😩', tr('Mal día de pelo', 'Bad hair day')],
        ['caida_cabello', '🪮', tr('Caída del pelo', 'Hair loss')],
        ['cabello_graso', '💦', tr('Pelo graso', 'Oily hair')],
      ];
  static List<List<String>> get _breast => [
        ['normal', '✅', tr('Todo en orden', 'All good')],
        ['congestion', '🔴', tr('Congestión', 'Swelling')],
        ['bulto', '⚠️', tr('Bulto', 'Lump')],
        ['hoyuelo', '🔘', tr('Hoyuelo', 'Dimple')],
        ['irritacion', '🩹', tr('Irritación de la piel', 'Skin irritation')],
        ['pezones_agrietados', '💢', tr('Pezones agrietados', 'Cracked nipples')],
        ['dolor', '😖', tr('Dolor', 'Pain')],
        ['secrecion', '💧', tr('Secreción del pezón', 'Nipple discharge')],
      ];
  static List<List<String>> get _sexExtra => [
        ['sexDesire', '🔥', tr('Deseo sexual', 'Sex drive')],
        ['sexMasturbation', '💫', tr('Masturbación', 'Masturbation')],
        ['sexOrgasm', '💥', tr('Orgasmo', 'Orgasm')],
        ['sexNoOrgasm', '😶', tr('Sin orgasmo', 'No orgasm')],
        ['diu', '🛡️', tr('DIU', 'IUD')],
      ];

  void _single(String key, String id) {
    if (x[key] == id) {
      x.remove(key);
    } else {
      x[key] = id;
    }
    if (key == 'breastSelfExam') log.breastExam = x[key] != null;
    onChanged();
  }

  void _multi(String key, String id) {
    final l = List<String>.from((x[key] as List?) ?? const []);
    if (!l.remove(id)) l.add(id);
    if (l.isEmpty) {
      x.remove(key);
    } else {
      x[key] = l;
    }
    onChanged();
  }

  void _flag(String key) {
    if (x[key] == true) {
      x.remove(key);
    } else {
      x[key] = true;
    }
    onChanged();
  }

  Future<void> _editTemp(BuildContext context) async {
    final ctrl = TextEditingController(text: x['temp'] == null ? '' : (x['temp'] as num).toStringAsFixed(2));
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Temperatura basal', 'Basal temperature')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: '°C', hintText: '36.50'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: Text(tr('Borrar', 'Clear'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(tr('Guardar', 'Save'))),
        ],
      ),
    );
    if (r == null) return;
    final v = double.tryParse(r.replaceAll(',', '.'));
    if (v == null || v < 34 || v > 42) {
      x.remove('temp');
    } else {
      x['temp'] = v;
    }
    onChanged();
  }

  /// Cuántos apartados de "Más detalles" tienen algo apuntado ese día.
  static int filledCount(DayLog log) {
    final x = log.extra;
    const keys = ['temp', 'cervicalMucus', 'spotting', 'energy', 'medication', 'skinHair', 'breastSelfExam'];
    var n = keys.where((k) => x[k] != null).length;
    if (['sexDesire', 'sexMasturbation', 'sexOrgasm', 'sexNoOrgasm', 'diu'].any((k) => x[k] == true)) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final temp = x['temp'] as num?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (AppStore.instance.conceiving) _group('🌡️', const Color(0xFFFFE4EC), tr('Temperatura basal', 'Basal temperature'),
            Align(
              alignment: Alignment.centerLeft,
              child: _chip('', temp == null ? tr('Añadir', 'Add') : '${temp.toStringAsFixed(2)} °C', temp != null, () => _editTemp(context)),
            )),
        if (AppStore.instance.conceiving) _group('💧', const Color(0xFFE3F1FF), tr('Moco cervical', 'Cervical mucus'),
            _wrap([for (final o in _mucus) _chip(o[1], o[2], x['cervicalMucus'] == o[0], () => _single('cervicalMucus', o[0]))])),
        _group('🩸', const Color(0xFFFFE6E6), tr('Manchado', 'Spotting'),
            _wrap([for (final o in _spotting) _chip(o[1], o[2], x['spotting'] == o[0], () => _single('spotting', o[0]))])),
        _group('⚡', const Color(0xFFFFF4D6), tr('Energía', 'Energy'),
            _wrap([for (final o in _energy) _chip(o[1], o[2], x['energy'] == o[0], () => _single('energy', o[0]))])),
        _group('💊', const Color(0xFFF0E8FF), tr('Medicación', 'Medication'),
            _wrap([
              for (final o in _meds) _chip(o[1], o[2], ((x['medication'] as List?) ?? const []).contains(o[0]), () => _multi('medication', o[0])),
            ])),
        _group('✨', const Color(0xFFFFEFE2), tr('Piel y pelo', 'Skin & hair'),
            _wrap([
              for (final o in _skin) _chip(o[1], o[2], ((x['skinHair'] as List?) ?? const []).contains(o[0]), () => _multi('skinHair', o[0])),
            ])),
        _group('🩷', const Color(0xFFFFE4EC), tr('Autoexamen de mamas', 'Breast self-exam'),
            _wrap([for (final o in _breast) _chip(o[1], o[2], x['breastSelfExam'] == o[0], () => _single('breastSelfExam', o[0]))])),
        if (showSex)
          _group('🔥', const Color(0xFFFFE6E6), tr('Vida sexual: más detalles', 'Sex life: more details'),
              _wrap([for (final o in _sexExtra) _chip(o[1], o[2], x[o[0]] == true, () => _flag(o[0]))])),
      ],
    );
  }

  Widget _group(String emoji, Color bg, String title, Widget body) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 1, bottom: 7),
                child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.text)),
              ),
              body,
            ]),
          ),
        ]),
      );

  Widget _wrap(List<Widget> c) => Wrap(spacing: 6, runSpacing: 6, children: c);

  Widget _chip(String emoji, String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: on ? C.pinkSoft : const Color(0xFFFFFBFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? C.pink : const Color(0xFFF3DCE5), width: on ? 1.5 : 1),
          ),
          child: Text(emoji.isEmpty ? label : '$emoji $label',
              style: TextStyle(fontSize: 12.5, fontWeight: on ? FontWeight.w800 : FontWeight.w600, color: on ? C.pinkDark : C.text)),
        ),
      );
}


/// Tarjeta plegable "Más detalles" del registro: cerrada por defecto (se
/// puede elegir "Mostrar siempre abierto"); enseña cuántos apartados hay
/// apuntados ese día.
class MoreDetailsCard extends StatefulWidget {
  const MoreDetailsCard({super.key, required this.log, required this.onChanged, this.showSex = true});
  final DayLog log;
  final VoidCallback onChanged;
  final bool showSex;

  @override
  State<MoreDetailsCard> createState() => _MoreDetailsCardState();
}

class _MoreDetailsCardState extends State<MoreDetailsCard> {
  static const _prefKey = 'register_details_always_open';
  bool _open = false;
  bool _always = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final a = p.getBool(_prefKey) ?? false;
      if (mounted) setState(() => _always = _open = a);
    });
  }

  Future<void> _setAlways(bool v) async {
    setState(() => _always = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefKey, v);
  }

  @override
  Widget build(BuildContext context) {
    final n = ExtraDetails.filledCount(widget.log);
    return Container(
      decoration: card(radius: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: C.pinkSoft, shape: BoxShape.circle),
                child: Icon(Icons.assignment_rounded, color: C.pink, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('Más detalles', 'More details'), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 2),
                  Text(AppStore.instance.conceiving ? tr('Temperatura, flujo, energía, medicación…', 'Temperature, discharge, energy, medication…') : tr('Energía, manchado, medicación, piel…', 'Energy, spotting, medication, skin…'),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: C.muted)),
                ]),
              ),
              if (n > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: C.pink, borderRadius: BorderRadius.circular(12)),
                  child: Text('$n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: C.pink, size: 28),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Divider(height: 1, color: C.pinkLine),
                    ExtraDetails(log: widget.log, onChanged: () {
                      widget.onChanged();
                      setState(() {});
                    }, showSex: widget.showSex),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: C.pinkLine),
                    Row(children: [
                      Expanded(
                        child: Text(tr('Mostrar siempre abierto', 'Always show open'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.muted)),
                      ),
                      Switch(
                        value: _always,
                        activeColor: Colors.white,
                        activeTrackColor: C.pink,
                        onChanged: _setAlways,
                      ),
                    ]),
                  ]),
                ),
        ),
      ]),
    );
  }
}
