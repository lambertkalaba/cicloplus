import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final temp = x['temp'] as num?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(tr('Temperatura basal', 'Basal temperature')),
        Align(
          alignment: Alignment.centerLeft,
          child: _chip('🌡️', temp == null ? tr('Añadir', 'Add') : '${temp.toStringAsFixed(2)} °C', temp != null, () => _editTemp(context)),
        ),
        _label(tr('Moco cervical', 'Cervical mucus')),
        _wrap([for (final o in _mucus) _chip(o[1], o[2], x['cervicalMucus'] == o[0], () => _single('cervicalMucus', o[0]))]),
        _label(tr('Manchado', 'Spotting')),
        _wrap([for (final o in _spotting) _chip(o[1], o[2], x['spotting'] == o[0], () => _single('spotting', o[0]))]),
        _label(tr('Energía', 'Energy')),
        _wrap([for (final o in _energy) _chip(o[1], o[2], x['energy'] == o[0], () => _single('energy', o[0]))]),
        _label(tr('Medicación', 'Medication')),
        _wrap([
          for (final o in _meds) _chip(o[1], o[2], ((x['medication'] as List?) ?? const []).contains(o[0]), () => _multi('medication', o[0])),
        ]),
        _label(tr('Piel y pelo', 'Skin & hair')),
        _wrap([
          for (final o in _skin) _chip(o[1], o[2], ((x['skinHair'] as List?) ?? const []).contains(o[0]), () => _multi('skinHair', o[0])),
        ]),
        _label(tr('Autoexamen de mamas', 'Breast self-exam')),
        _wrap([for (final o in _breast) _chip(o[1], o[2], x['breastSelfExam'] == o[0], () => _single('breastSelfExam', o[0]))]),
        if (showSex) ...[
          _label(tr('Vida sexual: más detalles', 'Sex life: more details')),
          _wrap([for (final o in _sexExtra) _chip(o[1], o[2], x[o[0]] == true, () => _flag(o[0]))]),
        ],
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.text)),
      );

  Widget _wrap(List<Widget> c) => Wrap(spacing: 6, runSpacing: 6, children: c);

  Widget _chip(String emoji, String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: on ? C.pinkSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? C.pink : C.pinkLine, width: on ? 1.6 : 1),
          ),
          child: Text('$emoji  $label',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? C.pinkDark : C.text)),
        ),
      );
}
