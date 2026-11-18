import 'package:flutter/material.dart';

import '../go/strings.dart' show L, tr;
import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Pantalla "Test de ovulación" (tira de LH), rediseñada a partir de la
/// maqueta de ChatGPT (noviembre 2026): cabecera con degradado, tarjeta de
/// introducción ilustrada, 3 tarjetas grandes con el dibujo de la tira
/// (negativo / positivo / pico de LH) y un historial con etiquetas de
/// color. La persistencia es la misma de siempre
/// (`SettingsService.loadOvulationTests` / `saveOvulationTests`).
class OvulationTestScreen extends StatefulWidget {
  final String themeId;

  const OvulationTestScreen({super.key, this.themeId = 'pink'});

  @override
  State<OvulationTestScreen> createState() => _OvulationTestScreenState();
}

class _OvulationTestScreenState extends State<OvulationTestScreen> {
  final SettingsService _settings = SettingsService();

  static const _green = Color(0xFF3E9B4F);
  static const _wine = Color(0xFF8E1B47);

  List<OvulationTestEntry> _tests = [];
  String _selectedResult = 'negative';
  DateTime _date = _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: _today(),
      );
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tests = await _settings.loadOvulationTests();
    if (!mounted) return;
    setState(() {
      _tests = tests;
      _loading = false;
    });
  }

  Future<void> _saveTest() async {
    setState(() => _saving = true);
    final entry = OvulationTestEntry(date: _date, result: _selectedResult);
    final updated = [entry, ..._tests]..sort((a, b) => b.date.compareTo(a.date));
    await _settings.saveOvulationTests(updated);
    if (!mounted) return;
    setState(() {
      _tests = updated;
      _saving = false;
      _date = _today();
    });
    final s = AppStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.ovulationTestSaved)));
  }

  Future<void> _deleteTest(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_formatDate(_tests[index].date)),
        content: Text('${tr('Borrar', 'Delete')}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar', 'Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Borrar', 'Delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final updated = [..._tests]..removeAt(index);
    await _settings.saveOvulationTests(updated);
    if (!mounted) return;
    setState(() => _tests = updated);
  }

  /// Cambiar la fecha o el resultado de un test ya guardado (o borrarlo).
  Future<void> _editTest(int index) async {
    final s = AppStrings.of(context);
    var date = _tests[index].date;
    var result = _tests[index].result;
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF7FA),
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(tr('Editar test', 'Edit test'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _wine)),
              const SizedBox(height: 12),
              Material(
                color: const Color(0xFFFFF0F4),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final d = await _pickDate(date);
                    if (d != null) set(() => date = d);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${s.ovulationTestDateLabel}: ${_formatDate(date)}',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                      const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final r in const ['negative', 'positive', 'peak'])
                  ChoiceChip(
                    label: Text(_resultLabel(s, r)),
                    selected: result == r,
                    onSelected: (_) => set(() => result = r),
                    selectedColor: _resultColors(r).$1,
                    labelStyle: TextStyle(fontWeight: FontWeight.w800, color: _resultColors(r).$2),
                  ),
              ]),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, 'save'),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(tr('Guardar cambios', 'Save changes'), style: const TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                label: Text(tr('Borrar', 'Delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
    if (action == 'delete') return _deleteTest(index);
    if (action != 'save') return;
    final updated = [..._tests];
    updated[index] = OvulationTestEntry(date: date, result: result);
    updated.sort((a, b) => b.date.compareTo(a.date));
    await _settings.saveOvulationTests(updated);
    if (!mounted) return;
    setState(() => _tests = updated);
  }

  String _resultLabel(AppStrings s, String result) {
    switch (result) {
      case 'positive':
        return s.ovulationTestPositive;
      case 'peak':
        return s.ovulationTestPeak;
      case 'negative':
      default:
        return s.ovulationTestNegative;
    }
  }

  String _resultHint(String result) {
    switch (result) {
      case 'positive':
        return tr('La ovulación está cerca', 'Ovulation is near');
      case 'peak':
        return tr('Ovulas en 24–36 h: días más fértiles', 'Ovulation in 24–36 h: most fertile days');
      case 'negative':
      default:
        return tr('Todavía no ovulas', 'Not ovulating yet');
    }
  }

  /// Colores de cada resultado: (fondo suave, color fuerte).
  (Color, Color) _resultColors(String result) {
    switch (result) {
      case 'positive':
        return (const Color(0xFFFFE3EC), const Color(0xFFD63A6E));
      case 'peak':
        return (const Color(0xFFEFE3FA), const Color(0xFF8A4FC8));
      case 'negative':
      default:
        return (const Color(0xFFE3EEFB), const Color(0xFF3D7CC9));
    }
  }

  String _resultAsset(String result) {
    switch (result) {
      case 'positive':
        return 'assets/go/ov_pos.png';
      case 'peak':
        return 'assets/go/ov_peak.png';
      case 'negative':
      default:
        return 'assets/go/ov_neg.png';
    }
  }

  String _formatDate(DateTime d) => '${d.day} ${L.monthShort(d.month)} ${d.year}';

  Widget _header(AppStrings s) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4, top + 6, 12, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C1C4C), Color(0xFFD9507D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -4,
            top: -4,
            child: Image.asset('assets/go/hibiscus.png', width: 72, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFE3EC),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: ClipOval(
                  child: Image.asset('assets/go/avatar.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/go/logo_flower.png', width: 16, height: 16, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                        const SizedBox(width: 4),
                        const Text('CicloPlus', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.ovulationTestScreenTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    const bg = Color(0xFFE3F1DC);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [bg, bg.withOpacity(0.15)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _wine),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _wine))),
            const Icon(Icons.eco_rounded, size: 18, color: _green),
          ],
        ),
      ),
    );
  }

  BoxDecoration _card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _wine.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      );

  Widget _resultOption(AppStrings s, String result) {
    final selected = _selectedResult == result;
    final (soft, strong) = _resultColors(result);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedResult = result),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
          decoration: BoxDecoration(
            color: selected ? soft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? strong : const Color(0xFFF1E3E8), width: selected ? 2 : 1.2),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(_resultAsset(result), width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.science_rounded, size: 40, color: strong)),
              ),
              const SizedBox(height: 6),
              Text(
                _resultLabel(s, result),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? strong : AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                _resultHint(result),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.2),
              ),
              const SizedBox(height: 6),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 20,
                color: selected ? strong : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      body: Column(
        children: [
          _header(s),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    children: [
                      // Introducción con dibujo de la tira
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: _card(),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset('assets/go/ov_intro.png', width: 92, height: 92, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.science_rounded, size: 60, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.ovulationTestIntro,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _sectionHeader(Icons.edit_rounded, tr('Nuevo test', 'New test')),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _card(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: const Color(0xFFFFF0F4),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final d = await _pickDate(_date);
                                  if (d != null) setState(() => _date = d);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${s.ovulationTestDateLabel}: ${_formatDate(_date)}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        ),
                                      ),
                                      const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(s.ovulationTestResultLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _resultOption(s, 'negative'),
                                  const SizedBox(width: 8),
                                  _resultOption(s, 'positive'),
                                  const SizedBox(width: 8),
                                  _resultOption(s, 'peak'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _saveTest,
                                icon: _saving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check_circle_rounded, size: 20),
                                label: Text(s.ovulationTestSave, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _sectionHeader(Icons.history_rounded, s.ovulationTestHistory),
                      if (_tests.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: _card(),
                          child: Text(
                            s.ovulationTestEmptyHistory,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: _card(),
                          child: Column(
                            children: [
                              for (var i = 0; i < _tests.length; i++) ...[
                                if (i > 0) Divider(height: 1, color: AppColors.border.withOpacity(0.6)),
                                InkWell(
                                  onTap: () => _editTest(i),
                                  onLongPress: () => _deleteTest(i),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event_rounded, size: 20, color: AppColors.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _formatDate(_tests[i].date),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        Builder(builder: (_) {
                                          final (soft, strong) = _resultColors(_tests[i].result);
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                            decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(20)),
                                            child: Text(
                                              _resultLabel(s, _tests[i].result),
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: strong),
                                            ),
                                          );
                                        }),
                                        IconButton(
                                          onPressed: () => _deleteTest(i),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
                                          tooltip: tr('Borrar', 'Delete'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('Toca un test para cambiar la fecha o el resultado.', 'Tap a test to change its date or result.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Image.asset('assets/go/hibiscus.png', width: 70, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
