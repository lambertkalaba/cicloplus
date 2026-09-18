import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Pantalla "Test de ovulación" (tira de LH): a diferencia de las otras 3
/// pantallas nuevas de esta ronda de pulido (Apple Watch/Widget/Foro, solo
/// informativas), esta SÍ tiene persistencia real vía
/// `SettingsService.loadOvulationTests`/`saveOvulationTests` — mismo
/// patrón load/save que el resto de la app (ver `loadMedicalAppointments`).
///
/// Formulario simple: fecha de hoy (no editable, para mantenerlo mínimo) +
/// resultado de 3 opciones tipo chip (negativo/positivo/pico de LH). Debajo,
/// un historial de solo lectura con los tests ya guardados.
class OvulationTestScreen extends StatefulWidget {
  final String themeId;

  const OvulationTestScreen({super.key, this.themeId = 'pink'});

  @override
  State<OvulationTestScreen> createState() => _OvulationTestScreenState();
}

class _OvulationTestScreenState extends State<OvulationTestScreen> {
  final SettingsService _settings = SettingsService();

  List<OvulationTestEntry> _tests = [];
  String _selectedResult = 'negative';
  bool _loading = true;
  bool _saving = false;

  AppThemeOption get _theme => themeById(widget.themeId);

  static const _monthShort = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

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
    final today = DateTime.now();
    final entry = OvulationTestEntry(
      date: DateTime(today.year, today.month, today.day),
      result: _selectedResult,
    );
    final updated = [entry, ..._tests];
    await _settings.saveOvulationTests(updated);
    if (!mounted) return;
    setState(() {
      _tests = updated;
      _saving = false;
    });
    final s = AppStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.ovulationTestSaved)));
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

  String _formatDate(DateTime d) => '${d.day} ${_monthShort[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final primary = Color(_theme.primary);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.ovulationTestScreenTitle),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  s.ovulationTestIntro,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.ovulationTestDateLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Text(
                          _formatDate(today),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(s.ovulationTestResultLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ('negative', s.ovulationTestNegative),
                          ('positive', s.ovulationTestPositive),
                          ('peak', s.ovulationTestPeak),
                        ].map((o) {
                          final selected = _selectedResult == o.$1;
                          return ChoiceChip(
                            label: Text(o.$2, style: const TextStyle(fontSize: 12.5)),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedResult = o.$1),
                            selectedColor: primary,
                            labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: selected ? primary : AppColors.border),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(s.ovulationTestSave, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(s.ovulationTestHistory, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                if (_tests.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Text(
                      s.ovulationTestEmptyHistory,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  )
                else
                  ..._tests.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 1.4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.science_outlined, size: 18, color: primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formatDate(t.date),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                              Text(
                                _resultLabel(s, t.result),
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primary),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}
