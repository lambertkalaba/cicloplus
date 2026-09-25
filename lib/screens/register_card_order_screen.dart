import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart' show kDefaultRegisterCardOrder;

/// Pantalla "Orden de las tarjetas de Registrar" (Configuración > Opciones
/// personalizadas). Deja arrastrar para reordenar las tarjetas de la
/// pestaña Registrar que NO son Flujo menstrual/Síntomas (siempre primero,
/// no aparecen aquí) ni la sección plegable "Opcional" (siempre al final,
/// tampoco aparece aquí) — ver kDefaultRegisterCardOrder en
/// register_screen.dart para la lista completa de ids reordenables.
///
/// "Vida sexual" solo se incluye en esta lista si "Mostrar 'Vida sexual'
/// siempre visible" está activo en Configuración: si no lo está, esa
/// tarjeta vive dentro de "Opcional" y no tiene sentido dejar elegir su
/// posición aquí (no está en este bloque en absoluto).
class RegisterCardOrderScreen extends StatefulWidget {
  final String themeId;

  const RegisterCardOrderScreen({super.key, this.themeId = 'pink'});

  @override
  State<RegisterCardOrderScreen> createState() => _RegisterCardOrderScreenState();
}

class _RegisterCardOrderScreenState extends State<RegisterCardOrderScreen> {
  final _settings = SettingsService();
  List<String> _order = List<String>.from(kDefaultRegisterCardOrder);
  bool _sexAlwaysVisible = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _settings.loadRegisterCardOrderRaw();
    final sexAlwaysVisible = await _settings.loadSexAlwaysVisible();
    final merged = saved.where(kDefaultRegisterCardOrder.contains).toList();
    for (final id in kDefaultRegisterCardOrder) {
      if (!merged.contains(id)) merged.add(id);
    }
    if (!mounted) return;
    setState(() {
      _order = merged;
      _sexAlwaysVisible = sexAlwaysVisible;
      _loading = false;
    });
  }

  String _labelFor(AppStrings s, String id) {
    switch (id) {
      case 'sexLife':
        return s.sexLifeLabel;
      case 'mood':
        return s.moodSectionTitle;
      case 'energy':
        return s.energySectionTitle;
      case 'skinHair':
        return s.skinHairSectionTitle;
      case 'medication':
        return s.medicationSectionTitle;
      default:
        return id;
    }
  }

  Future<void> _persist() async {
    await _settings.saveRegisterCardOrder(_order);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(widget.themeId);
    // 'sexLife' se muestra en la lista arrastrable solo si de verdad
    // aparece en el bloque fijo de Registrar (_sexAlwaysVisible activo) —
    // si no, dejar que la usuaria la reordene aquí no tendría ningún
    // efecto visible, así que se oculta de la lista para no confundir.
    final visibleOrder = _order.where((id) => id != 'sexLife' || _sexAlwaysVisible).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          s.settingsRegisterCardOrder,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    s.settingsRegisterCardOrderHint,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: visibleOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        // visibleOrder es un subconjunto filtrado de _order;
                        // el reordenamiento se aplica sobre los índices REALES
                        // dentro de _order (no los de visibleOrder), para no
                        // desordenar la posición de 'sexLife' cuando está
                        // oculta de esta lista.
                        final movedId = visibleOrder[oldIndex];
                        _order.remove(movedId);
                        final targetId = newIndex < visibleOrder.length ? visibleOrder[newIndex] : null;
                        final insertAt = targetId != null ? _order.indexOf(targetId) : _order.length;
                        _order.insert(insertAt, movedId);
                      });
                      _persist();
                    },
                    itemBuilder: (context, index) {
                      final id = visibleOrder[index];
                      return Container(
                        key: ValueKey(id),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: AppColors.textPrimary.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.drag_indicator, color: Color(theme.primary).withOpacity(0.6)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _labelFor(s, id),
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
