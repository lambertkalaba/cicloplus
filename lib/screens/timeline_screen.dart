import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/photo_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

/// Lista cronológica de días con datos registrados (más reciente primero),
/// con búsqueda por texto del diario o nombre de síntoma. Equivalente a
/// "viewTimeline" del prototipo web.
class TimelineScreen extends StatefulWidget {
  final Map<String, DayEntry> data;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;

  // Id del tema de color elegido en Configuración — se reenvía al editor
  // de día para que sus botones (Guardar, cita médica, recordatorio) usen
  // el color de app actual en vez del rosa fijo por defecto.
  final String themeId;

  const TimelineScreen({
    super.key,
    required this.data,
    required this.onDataChanged,
    this.themeId = 'pink',
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SettingsService _settingsService = SettingsService();
  String _query = '';
  bool _wellnessEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadWellnessPref();
  }

  Future<void> _loadWellnessPref() async {
    final value = await _settingsService.loadWellnessEnabled();
    if (mounted) setState(() => _wellnessEnabled = value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _parseKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  List<String> _filteredKeys() {
    var keys = widget.data.keys.toList()..sort();
    keys = keys.reversed.toList();
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return keys;

    final s = AppStrings.of(context);
    return keys.where((key) {
      final entry = widget.data[key]!;
      final symptomLabels = entry.symptoms.map((id) => s.symptomLabelFor(id)).join(' ');
      final haystack = [
        entry.note,
        entry.symptoms.join(' '),
        symptomLabels,
        entry.flow,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _openDay(String key) {
    final date = _parseKey(key);

    // Siempre se usa la pantalla "Registrar" (única pantalla de edición de
    // día en toda la app) — el antiguo editor modal `DayEditorSheet` quedó
    // retirado también aquí. RegisterScreen acepta `targetDate` para poder
    // trabajar sobre cualquier día, no solo hoy.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          data: widget.data,
          onDataChanged: widget.onDataChanged,
          themeId: widget.themeId,
          targetDate: date,
          showCloseButton: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = _filteredKeys();
    final s = AppStrings.of(context);

    // Esta pantalla se abre con Navigator.push desde MeScreen (tarjeta
    // "Cronología") y no tiene AppBar propio — antes se devolvía solo el
    // Padding/Column de abajo, sin Scaffold, lo que provocaba el error
    // "No Material widget found" + overflow al faltar el AppBar/SafeArea
    // que reserva espacio para la barra de estado. Se envuelve aquí en un
    // Scaffold con AppBar y botón de cierre (X) para volver atrás.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(s.timelineTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            tooltip: s.commonClose,
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: s.timelineSearchHint,
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: keys.isEmpty
                ? Center(
                    child: Text(
                      _query.isNotEmpty ? s.timelineNoResults : s.timelineEmpty,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: keys.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) => _TimelineItem(
                      dateKey: keys[index],
                      entry: widget.data[keys[index]]!,
                      onTap: () => _openDay(keys[index]),
                      wellnessEnabled: _wellnessEnabled,
                    ),
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String dateKey;
  final DayEntry entry;
  final VoidCallback onTap;
  final bool wellnessEnabled;

  const _TimelineItem({
    required this.dateKey,
    required this.entry,
    required this.onTap,
    this.wellnessEnabled = true,
  });

  DateTime get _date {
    final parts = dateKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final date = _date;
    final tags = <Widget>[];

    if (entry.flow != 'none') {
      // flowLabelFor ya incluye su propia cantidad de gotas (🩸/🩸🩸/🩸🩸🩸
      // según intensidad), así que no se antepone una gota fija aquí para
      // no duplicarla.
      tags.add(_Tag(text: s.flowLabelFor(entry.flow), isPeriod: true));
    }
    if (entry.cervicalMucus != null) {
      tags.add(_Tag(text: '💧 ${s.cervicalMucusLabelFor(entry.cervicalMucus!)}'));
    }
    for (final symptomId in entry.symptoms) {
      final level = entry.symptomLevels[symptomId];
      final label = s.symptomLabelFor(symptomId);
      final levelLabel = level != null ? s.symptomLevelLabelFor(level) : null;
      final emoji = kSymptomEmoji[symptomId] ?? '';
      tags.add(_Tag(text: '$emoji $label${levelLabel != null ? ' ($levelLabel)' : ''}'));
    }
    if (entry.sex) {
      tags.add(_Tag(text: '${entry.unprotected ? '⚠️' : '❤️'} ${s.timelineSexTag}'));
    }
    if (wellnessEnabled) {
      if (entry.temp != null) tags.add(_Tag(text: '🌡️ ${entry.temp}°C'));
      if (entry.water != null) tags.add(_Tag(text: '💧 ${s.timelineGlasses(entry.water!)}'));
      if (entry.sleep != null) tags.add(_Tag(text: '😴 ${entry.sleep}h'));
      if (entry.weight != null) tags.add(_Tag(text: '⚖️ ${entry.weight}kg'));
    }
    if (entry.photo != null) tags.add(_Tag(text: s.timelinePhotoTag));
    if (tags.isEmpty) tags.add(_Tag(text: s.timelineNoDetails));

    final photoBytes = PhotoService.decodeDataUrl(entry.photo);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text('${date.day}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(s.monthShort(date.month).toUpperCase(),
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 4, runSpacing: 4, children: tags),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.note,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (photoBytes != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(photoBytes, width: 56, height: 56, fit: BoxFit.cover),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool isPeriod;

  const _Tag({required this.text, this.isPeriod = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isPeriod ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: isPeriod ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}
