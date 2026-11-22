import 'package:flutter/material.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';
import 'extra_details.dart';
import '../widgets/ciclo_date_picker.dart';

/// Registrar mi día: flujo, síntomas, dolor, ánimo y notas.
class RegisterScreen extends StatefulWidget {
  final DateTime day;
  const RegisterScreen({super.key, required this.day});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late DateTime _day;
  late DayLog _log;
  final _note = TextEditingController();
  final _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load(dateOnly(widget.day));
  }

  void _load(DateTime d) {
    _day = d;
    _log = AppStore.instance.logFor(d);
    _note.text = _log.note;
  }

  void _changeDay(int delta) {
    final n = addDays(_day, delta);
    if (n.isAfter(dateOnly(DateTime.now()))) return;
    setState(() => _load(n));
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showCicloDatePicker(context: context, initialDate: _day, firstDate: DateTime(now.year - 3), lastDate: now);
    if (d != null) setState(() => _load(dateOnly(d)));
  }

  Future<void> _save() async {
    _log.note = _note.text.trim();
    await AppStore.instance.setLog(_day, _log);
    if (!mounted) return;
    toast(context, tr('Registro guardado 💗', 'Saved 💗'));
    Navigator.of(context).pop();
  }

  Future<void> _customize() async {
    final s = AppStore.instance;
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Mis síntomas personalizados', 'My custom symptoms'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.text)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: tr('Ej.: Dolor de espalda', 'E.g. Back pain'),
                        filled: true,
                        fillColor: C.pinkBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: C.pink),
                    onPressed: () async {
                      final t = ctrl.text.trim();
                      if (t.isEmpty || s.customSymptoms.contains(t) || symptomKeys.contains(t)) return;
                      s.customSymptoms.add(t);
                      ctrl.clear();
                      await s.commit();
                      setSheet(() {});
                      setState(() {});
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (s.customSymptoms.isEmpty)
                Text(tr('Aún no has añadido ninguno.', "You haven't added any yet."), style: const TextStyle(color: C.muted)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in s.customSymptoms)
                    InputChip(
                      label: Text(c),
                      onDeleted: () async {
                        s.customSymptoms.remove(c);
                        await s.commit();
                        setSheet(() {});
                        setState(() {});
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    // Los habituales (elegidos en la bienvenida) salen primero.
    final symptoms = [
      ...symptomKeys.where(s.favSymptoms.contains),
      ...symptomKeys.where((k) => !s.favSymptoms.contains(k)),
      ...s.customSymptoms,
    ];
    final isToday = _day == dateOnly(DateTime.now());
    return Scaffold(
      body: PinkBackground(
        child: Column(
          children: [
            GreenHeader(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Registrar mi día', 'Log my day'),
                                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: C.text)),
                            const SizedBox(height: 2),
                            Text(tr('Registra tus síntomas, hábitos y notas.', 'Log your symptoms, habits and notes.'),
                                style: const TextStyle(fontSize: 13, color: C.muted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Img('cal_check', size: 76, fallback: Icons.event_available),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: card(radius: 18),
                    child: Row(
                      children: [
                        IconButton(onPressed: () => _changeDay(-1), icon: Icon(Icons.chevron_left_rounded, color: C.pinkDark)),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDay,
                            child: Text(
                              isToday ? '${tr('Hoy', 'Today')} · ${L.dateShort(_day)}' : L.dateLong(_day),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isToday ? null : () => _changeDay(1),
                          icon: Icon(Icons.chevron_right_rounded, color: isToday ? C.pinkLine : C.pinkDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!AppStore.instance.pregnant) _section(
                    SectionTitle(Icons.water_drop_rounded, tr('Flujo menstrual', 'Menstrual flow')),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Choice(
                                selected: _log.flow == i,
                                onTap: () => setState(() => _log.flow = i),
                                child: Column(
                                  children: [
                                    _Drops(i),
                                    const SizedBox(height: 4),
                                    Text(flowNames[i],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.text)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section(
                    SectionTitle(
                      Icons.bolt_rounded,
                      tr('Síntomas', 'Symptoms'),
                      trailing: GestureDetector(
                        onTap: _customize,
                        child: Pill(tr('Personalizar', 'Customize'), icon: Icons.settings_rounded, color: C.pinkDark, bg: C.pinkSoft),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.9,
                      children: [
                        for (final k in symptoms)
                          Choice(
                            selected: _log.symptoms.contains(k),
                            onTap: () => setState(() {
                              if (!_log.symptoms.remove(k)) _log.symptoms.add(k);
                            }),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (symptomAsset(k) != null)
                                  Img(symptomAsset(k)!, size: 34)
                                else
                                  const Text('✨', style: TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(symptomName(k),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.text)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section(
                    SectionTitle(Icons.speed_rounded, tr('Intensidad del dolor', 'Pain intensity')),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Choice(
                                selected: _log.pain == i,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                onTap: () => setState(() => _log.pain = i),
                                child: Text(painNames[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.text)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section(
                    SectionTitle(Icons.favorite_rounded, tr('Otros registros', 'Other logs')),
                    Row(
                      children: [
                        if (AppStore.instance.showSex)
                          _other('q_sex', null, tr('Vida sexual', 'Sex life'), _log.sex > 0 ? sexNames[_log.sex] : null, _editSex),
                        _other('q_weight', null, tr('Peso', 'Weight'), _log.weight != null ? '${fmtNum(_log.weight!)} kg' : null, _editWeight),
                        _other('q_water', null, tr('Bebe agua', 'Water'), _log.water > 0 ? '${_log.water} ${tr('vasos', 'glasses')}' : null, _editWater),
                        _other(null, '🏃‍♀️', tr('Actividad', 'Activity'), _log.activity > 0 ? '${_log.activity} min' : null, _editActivity),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section(
                    SectionTitle(Icons.favorite_rounded, tr('Tu ánimo hoy', 'Your mood today')),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Choice(
                                selected: _log.mood == i + 1,
                                onTap: () => setState(() => _log.mood = _log.mood == i + 1 ? 0 : i + 1),
                                child: Column(
                                  children: [
                                    Img(moodImgs[i], size: 30, fallback: Icons.sentiment_satisfied_rounded, fallbackColor: C.orange),
                                    const SizedBox(height: 3),
                                    Text(moodNames[i],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: C.text)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MoreDetailsCard(log: _log, onChanged: () => setState(() {}), showSex: AppStore.instance.showSex),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: card(radius: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: C.pinkSoft, shape: BoxShape.circle),
                          child: Icon(Icons.menu_book_rounded, color: C.pink, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(tr('Nota del día', 'Note of the day'),
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: C.text)),
                        ),
                        Text(tr('Se guarda en tu diario', 'Saved in your diary'),
                            style: const TextStyle(fontSize: 11.5, color: C.muted, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 12),
                      Stack(children: [
                        TextField(
                          controller: _note,
                          focusNode: _noteFocus,
                          minLines: 3,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: tr('¿Quieres añadir algo más hoy?', 'Anything else to add today?'),
                            hintStyle: const TextStyle(color: C.muted),
                            filled: true,
                            fillColor: const Color(0xFFFFF4F8),
                            contentPadding: const EdgeInsets.fromLTRB(14, 14, 56, 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pink, width: 1.5)),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Material(
                            color: C.pink,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _noteFocus.requestFocus(),
                              child: Tooltip(
                                message: tr('Dictar con el teclado', 'Dictate with the keyboard'),
                                child: const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: PinkButton(label: tr('Guardar registro', 'Save log'), icon: Icons.check_rounded, onTap: _save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _other(String? img, String? emoji, String label, String? value, VoidCallback onTap) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Choice(
            selected: value != null,
            onTap: onTap,
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
            child: Column(
              children: [
                if (img != null) Img(img, size: 32) else Text(emoji ?? '', style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 3),
                Text(value ?? label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: value != null ? C.pinkDark : C.text)),
              ],
            ),
          ),
        ),
      );

  Future<T?> _sheet<T>(String title, Widget Function(BuildContext ctx, StateSetter set) body) => showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 14),
                  body(ctx, set),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _editSex() async {
    final v = await _sheet<int>(tr('Vida sexual', 'Sex life'), (ctx, set) => Column(
          children: [
            for (var i = 0; i < 3; i++)
              ListTile(
                leading: Icon(i == 0 ? Icons.block_rounded : Icons.favorite_rounded, color: i == 0 ? C.muted : C.pink),
                title: Text(sexNames[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: _log.sex == i ? Icon(Icons.check_rounded, color: C.pink) : null,
                onTap: () => Navigator.pop(ctx, i),
              ),
          ],
        ));
    if (v != null) setState(() => _log.sex = v);
  }

  Future<void> _editWeight() async {
    final ctrl = TextEditingController(text: _log.weight != null ? fmtNum(_log.weight!) : '');
    final v = await _sheet<String>(tr('Peso (kg)', 'Weight (kg)'), (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: tr('Ej.: 62,5', 'E.g. 62.5'),
                suffixText: 'kg',
                filled: true,
                fillColor: C.pinkBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: PinkButton(label: tr('Borrar', 'Clear'), outlined: true, onTap: () => Navigator.pop(ctx, ''))),
                const SizedBox(width: 10),
                Expanded(child: PinkButton(label: tr('Guardar', 'Save'), onTap: () => Navigator.pop(ctx, ctrl.text))),
              ],
            ),
          ],
        ));
    if (v == null) return;
    final t = v.trim().replaceAll(',', '.');
    if (t.isEmpty) {
      setState(() => _log.weight = null);
      return;
    }
    final w = double.tryParse(t);
    if (w == null || w < 20 || w > 300) {
      if (mounted) toast(context, tr('Escribe un peso válido', 'Enter a valid weight'));
      return;
    }
    setState(() => _log.weight = w);
  }

  Future<void> _editWater() async {
    var n = _log.water;
    final ok = await _sheet<bool>(tr('Vasos de agua', 'Glasses of water'), (ctx, set) => Column(
          children: [
            Stepper2(value: n, min: 0, max: 20, onChanged: (v) => set(() => n = v)),
            const SizedBox(height: 6),
            Text(tr('Objetivo: ${AppStore.instance.waterGoal} vasos', 'Goal: ${AppStore.instance.waterGoal} glasses'),
                style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            PinkButton(label: tr('Guardar', 'Save'), onTap: () => Navigator.pop(ctx, true)),
          ],
        ));
    if (ok == true) setState(() => _log.water = n);
  }

  Future<void> _editActivity() async {
    final v = await _sheet<int>(tr('Actividad física', 'Physical activity'), (ctx, set) => Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final m in const [0, 10, 15, 20, 30, 45, 60, 90, 120])
              ChoiceChip(
                label: Text(m == 0 ? tr('Nada', 'None') : '$m min'),
                selected: _log.activity == m,
                selectedColor: C.pinkSoft,
                onSelected: (_) => Navigator.pop(ctx, m),
              ),
          ],
        ));
    if (v != null) setState(() => _log.activity = v);
  }

  Widget _section(Widget title, Widget body) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: card(radius: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [title, const SizedBox(height: 10), body]),
      );
}

/// Gotas de flujo: contorno (ninguno), 1, 2 o 3 gotas.
class _Drops extends StatelessWidget {
  final int n;
  const _Drops(this.n);

  @override
  Widget build(BuildContext context) {
    if (n == 0) return const Img('drop_empty', size: 26, fallback: Icons.water_drop_outlined, fallbackColor: C.lavender);
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [for (var i = 0; i < n; i++) const Img('drop', size: 20, fallback: Icons.water_drop_rounded)],
      ),
    );
  }
}
