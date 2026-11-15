import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart' show themeById;
import '../theme/app_theme.dart';

const List<int> kReminderDayOptions = [1, 2, 3, 5];

/// Tarjeta de "Alarma de menstruación" en la pantalla principal:
/// interruptor + selector de cuántos días antes avisar.
class ReminderCard extends StatelessWidget {
  final ReminderSettings settings;
  final bool hasPrediction;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onDaysChanged;

  // Id del tema de color elegido en Configuración — usado en el switch
  // de esta tarjeta para que siga el color de app actual.
  final String themeId;

  const ReminderCard({
    super.key,
    required this.settings,
    required this.hasPrediction,
    required this.onToggle,
    required this.onDaysChanged,
    this.themeId = 'pink',
  });

  String _subtitle(AppStrings s) {
    if (!settings.enabled) return s.reminderSubtitleOff;
    if (!hasPrediction) return s.reminderSubtitleNoData(settings.daysBefore);
    return s.reminderSubtitleOn(settings.daysBefore);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.reminderTitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(s),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.enabled,
                activeColor: Color(themeById(themeId).primary),
                onChanged: onToggle,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: settings.enabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Text(s.reminderBefore, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: settings.daysBefore,
                                isExpanded: true,
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                items: kReminderDayOptions
                                    .map((d) => DropdownMenuItem<int>(
                                          value: d,
                                          child: Text(s.reminderDayOption(d)),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) onDaysChanged(value);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
