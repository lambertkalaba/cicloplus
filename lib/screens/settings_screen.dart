import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../go/data/store.dart' show AppStore;
import '../go/strings.dart' show L, tr;
import '../go/widgets/cycle_plus.dart' show CycleExtraSettings;
import '../go/widgets/michi_events.dart' show MichiSettings;
import '../go/widgets/avatar_picker.dart' show AvatarSettings;
import 'package:flutter/cupertino.dart' show CupertinoAlertDialog, CupertinoDialogAction;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/auth_service.dart';
import '../services/cycle_predictor.dart';
import '../services/daily_notification_service.dart';
import '../services/health_sync_service.dart';
import '../services/locale_controller.dart';
import '../services/partner_service.dart';
import '../services/pdf_report_service.dart';
import '../services/reminder_service.dart';
import '../services/calendar_palette_controller.dart';
import '../services/calendar_style_controller.dart';
import '../services/couple_illustration_controller.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart' show kPaywallEnabled;
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/coming_soon_sheet.dart';
import '../widgets/conceive_intake_sheet.dart';
import 'apple_watch_screen.dart';
import 'lock_screen.dart';
import 'register_card_order_screen.dart';
import 'paywall_screen.dart';
import 'pregnancy_tracking_screen.dart';
import 'reminder_screen.dart';
import 'widget_placeholder_screen.dart';

/// Pantalla de configuración, reorganizada (fase "Ajustes: reorganizar
/// como en capturas") siguiendo el orden de las capturas de referencia:
/// cabecera de cuenta, invitar pareja, mi objetivo, predicción, embarazo,
/// año de nacimiento, prueba prémium, recordatorio, seguir a otros,
/// exportar para el doctor, borrar datos, Face ID, idioma, tema, opciones
/// personalizadas, Apple Salud/Watch/Widget, quitar anuncios,
/// informe de errores, puntúanos y privacidad al
/// final (se quitaron "Foro" y "Ayúdanos con la traducción" a petición
/// de la dueña — ver ForumScreen, ya sin usar). Los datos personales
/// completos (nombre/apellido/fecha
/// nacimiento/talla/peso) y el backup export/import se mantienen cerca de
/// las secciones con las que se relacionan (Datos ~ Año de nacimiento,
/// Backup ~ Exportar para el doctor).
///
/// Modo embarazo, recordatorio de anticonceptivo y citas médicas siguen
/// viviendo también en HealthMenuScreen (archivo huérfano conservado sin
/// borrar), pero el toggle de embarazo ahora también está aquí para que
/// coincida con la referencia — mismo `SettingsService.loadPregnancySettings
/// /savePregnancySettings` que ya usan HealthMenuScreen y MeScreen, sin
/// estado paralelo.
const Color _kGreen = Color(0xFF3E9B4F);

class SettingsScreen extends StatefulWidget {
  final String userId;
  final ValueChanged<String> onThemeChanged;

  // Registros del ciclo (para exportar PDF al doctor) y su callback de
  // cambio (para "Borrar todos los datos", que sí debe reflejarse de
  // inmediato en el resto de la app sin esperar a que se recargue el
  // estado en MainTabScreen).
  final Map<String, DayEntry> data;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;

  // Llamado tras borrar la cuenta con éxito (ver "Borrar cuenta" más abajo)
  // para que AuthGate detecte que ya no hay sesión y vuelva a AuthScreen —
  // mismo callback que ya usan MainTabScreen/MeScreen para el cierre de
  // sesión normal, reutilizado aquí para el borrado de cuenta.
  final VoidCallback onSignOut;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.onThemeChanged,
    required this.data,
    required this.onDataChanged,
    required this.onSignOut,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// URL pública de la política de privacidad, publicada vía Firebase
/// Hosting. Debe coincidir siempre con la que se declara en Google Play
/// Console (sección "Política de privacidad" de la ficha de la tienda).
/// Es la versión en inglés (idioma por defecto del sitio) — se usa como
/// base y como último recurso si el idioma actual no tiene traducción.
const String kPrivacyPolicyUrl = 'https://cicloplus-9a957.web.app/privacidad.html';

/// URL pública de los términos de uso, publicada vía Firebase Hosting
/// junto a la política de privacidad (mismo hosting, mismo estilo).
/// Igual que arriba, es la versión en inglés y sirve de último recurso.
const String kTermsOfUseUrl = 'https://cicloplus-9a957.web.app/terminos.html';

/// Idiomas de la app para los que existe una traducción publicada de la
/// política de privacidad y los términos de uso (además del inglés, que
/// es ahora el idioma por defecto del sitio). Debe reflejar los archivos
/// realmente subidos a Firebase Hosting (privacidad-XX.html / terminos-XX.html).
const Set<String> _kLegalDocLanguages = {'es', 'fr', 'de', 'ru', 'ar', 'hi', 'bn', 'pt'};

/// Devuelve la URL de la política de privacidad en el idioma indicado.
/// Si ese idioma es inglés o no tiene traducción publicada, cae a la
/// versión en inglés (idioma por defecto del sitio).
String privacyPolicyUrlFor(String languageCode) {
  if (_kLegalDocLanguages.contains(languageCode)) {
    return 'https://cicloplus-9a957.web.app/privacidad-$languageCode.html';
  }
  return kPrivacyPolicyUrl;
}

/// Igual que [privacyPolicyUrlFor] pero para los términos de uso.
String termsOfUseUrlFor(String languageCode) {
  if (_kLegalDocLanguages.contains(languageCode)) {
    return 'https://cicloplus-9a957.web.app/terminos-$languageCode.html';
  }
  return kTermsOfUseUrl;
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final AuthService _authService = AuthService();
  final DailyNotificationService _dailyNotifications = DailyNotificationService();
  final HealthSyncService _healthSync = HealthSyncService();
  final ReminderService _reminderService = ReminderService();
  late final StorageService _storage = StorageService(widget.userId);

  String _themeId = 'pink';
  bool _pinEnabled = false;
  DailyTimeReminderSettings _dailyReminder = const DailyTimeReminderSettings(time: '20:00');
  bool _sexAlwaysVisible = false;
  bool _loading = true;
  bool _busy = false;
  bool _languageExpanded = false;
  bool _healthSyncEnabled = false;
  bool _healthSyncBusy = false;
  bool _irregularCycleMode = false;
  // Duración de ciclo/periodo autoinformadas en el cuestionario de
  // "Intentar concebir" — respaldo para CyclePredictor mientras no hay
  // suficientes datos reales (ver conceive_intake_sheet.dart). Se cargan
  // aparte, igual que _irregularCycleMode, en vez de recibirse de
  // MainTabScreen, porque esta pantalla siempre lee su propia copia fresca
  // de SettingsService.
  int? _selfReportedCycleLen;
  int? _selfReportedPeriodLen;
  bool _wellnessEnabled = true;
  bool _exportingPdf = false;
  bool _deletingAllData = false;
  bool _deletingAccount = false;

  // ---- Mi objetivo (mismo valor que MeScreen — ver SettingsService.
  // loadUserGoal/saveUserGoal, sin estado paralelo) ----
  String _userGoal = 'period';

  // ---- Embarazo (mismo interruptor que HealthMenuScreen/MeScreen) ----
  PregnancySettings _pregnancy = const PregnancySettings();
  // ---- Compartir fotos del bebé/barriga con el socio vinculado (ver
  // "Invitar a un socio" y PartnerService) ----
  bool _shareBabyPhotos = false;

  // ---- Datos personales (nombre, apellido, fecha de nacimiento, talla,
  // peso de referencia). Ya no se muestran/editan en esta pantalla (la
  // sección "Datos" se quitó de Configuración a petición del usuario) —
  // se siguen cargando aquí por si algún otro punto de esta misma clase
  // llega a necesitarlos más adelante, pero de momento no se leen en
  // ningún build(). El único editor real que queda es "Edad"/altura en
  // Registrar > Peso (register_screen.dart).
  String? _profileName;
  String? _profileLastName;
  DateTime? _profileBirthDate;
  double? _heightCm;
  double? _referenceWeight;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final themeId = await _settings.loadThemeId();
    final hasPin = await _settings.hasPin();
    final daily = await _settings.loadDailyReminderSettings();
    final sexAlwaysVisible = await _settings.loadSexAlwaysVisible();
    final healthSyncEnabled = await _settings.loadHealthSyncEnabled();
    final irregularCycleMode = await _settings.loadIrregularCycleMode();
    final selfReportedCycleLen = await _settings.loadConceiveAvgCycleLength();
    final selfReportedPeriodLen = await _settings.loadConceiveAvgPeriodLength();
    final wellnessEnabled = await _settings.loadWellnessEnabled();
    final profileName = await _settings.loadProfileName();
    final profileLastName = await _settings.loadProfileLastName();
    final profileBirthDate = await _settings.loadProfileBirthDate();
    final heightCm = await _settings.loadHeightCm();
    final referenceWeight = await _settings.loadProfileReferenceWeight();
    final userGoal = await _settings.loadUserGoal();
    final pregnancy = await _settings.loadPregnancySettings();
    final shareBabyPhotos = await _settings.loadShareBabyPhotos();
    if (!mounted) return;
    setState(() {
      _themeId = themeId;
      _pinEnabled = hasPin;
      _dailyReminder = daily;
      _sexAlwaysVisible = sexAlwaysVisible;
      _healthSyncEnabled = healthSyncEnabled;
      _irregularCycleMode = irregularCycleMode;
      _selfReportedCycleLen = selfReportedCycleLen;
      _selfReportedPeriodLen = selfReportedPeriodLen;
      _wellnessEnabled = wellnessEnabled;
      _profileName = profileName;
      _profileLastName = profileLastName;
      _profileBirthDate = profileBirthDate;
      _heightCm = heightCm;
      _referenceWeight = referenceWeight;
      _userGoal = pregnancy.enabled ? 'pregnancy' : userGoal;
      _pregnancy = pregnancy;
      _shareBabyPhotos = shareBabyPhotos;
      _loading = false;
    });
  }

  /// Abre un diálogo para editar nombre, apellido (opcional), fecha de
  /// nacimiento, talla y peso de referencia. Es el único lugar de la app
  /// donde se pueden modificar estos datos; en "Mi salud" solo se ven.
  // _openEditDataDialog (editaba nombre/apellido/fecha de
  // nacimiento/altura/peso de referencia) se quitó junto con la sección
  // "Datos" de Configuración, a petición del usuario. La altura sigue
  // siendo editable desde Registrar > Peso; el año de nacimiento también
  // (campo "Edad" en esa misma pantalla, ver register_screen.dart
  // _saveAge). Nombre, apellido y peso de referencia solo se establecen
  // ahora durante el registro inicial (auth_screen.dart) y ya no tienen
  // ningún editor posterior en la app.

  Future<void> _toggleIrregularCycleMode(bool value) async {
    setState(() => _irregularCycleMode = value);
    await _settings.saveIrregularCycleMode(value);
  }

  /// Abre la sub-pantalla (bottomsheet) de "Configuración de predicción":
  /// mismo patrón `showModalBottomSheet` que ya usan HomeScreen/TodayScreen/
  /// StatsScreen/TimelineScreen (fondo blanco, esquinas superiores
  /// redondeadas). No crea persistencia nueva: reutiliza el mismo
  /// `_irregularCycleMode`/`_toggleIrregularCycleMode` de siempre, solo
  /// cambia dónde vive visualmente el control (antes en la lista principal,
  /// ahora dentro de una hoja con más contexto explicativo), para que la
  /// fila de la lista se vea como una configuración con más profundidad en
  /// vez de un simple switch suelto.
  Future<void> _openPredictionConfigSheet() async {
    final s = AppStrings.of(context);
    // Valores actuales de ciclo/período, mismo CyclePredictor (y mismo
    // forceIrregular) que el resto de la app usa para predecir — se
    // muestran de solo lectura porque se derivan siempre del historial de
    // registros (CyclePredictor.getAvgCycleLength/getAvgPeriodLength), no
    // hay un valor manual paralelo que pudiera desincronizarse de ellos.
    final predictor = CyclePredictor(
      widget.data,
      forceIrregular: _irregularCycleMode,
      selfReportedCycleLen: _selfReportedCycleLen,
      selfReportedPeriodLen: _selfReportedPeriodLen,
    );
    final avgCycle = predictor.getAvgCycleLength();
    final avgPeriod = predictor.getAvgPeriodLength();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    s.settingsPredictionConfig,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.settingsPredictionConfigHint,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.settingsPredictionCurrentValues,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _predictionValueCard(
                          label: s.meAvgCycle,
                          value: avgCycle,
                          unit: s.meDayUnit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _predictionValueCard(
                          label: s.meAvgPeriod,
                          value: avgPeriod,
                          unit: s.meDayUnit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.settingsPredictionCurrentValuesHint,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  _switchRow(
                    title: s.settingsIrregularCycleToggle,
                    subtitle: _irregularCycleMode ? s.on_ : s.off_,
                    value: _irregularCycleMode,
                    onChanged: (value) {
                      _toggleIrregularCycleMode(value);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.settingsIrregularCycleHint,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Hoja "Personalizar colores" — deja elegir los 7 colores de la paleta
  /// 'custom' uno a uno (Período, Previsto relleno/borde, Fértil
  /// relleno/borde, Hoy, Ovulación), con vista previa en vivo, y los
  /// guarda de golpe en CalendarPaletteController al pulsar "Guardar".
  /// Mismo patrón visual que `_openPredictionConfigSheet` (hoja blanca,
  /// esquinas redondeadas, tirador arriba) para que se sienta parte de
  /// la misma pantalla.
  Future<void> _openCustomPaletteSheet() async {
    final s = AppStrings.of(context);
    var draft = CalendarPaletteController.instance.customPalette;

    Future<void> pickFor(
      StateSetter setSheetState,
      int current,
      void Function(int) apply,
    ) async {
      final picked = await _showColorSwatchPicker(context, s, current);
      if (picked != null) {
        apply(picked);
        setSheetState(() {});
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Widget row(String label, int color, void Function(int) apply) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ),
                    _ColorSwatchButton(
                      color: color,
                      onTap: () => pickFor(setSheetState, color, apply),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      s.settingsCustomPaletteTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.settingsCustomPaletteHint,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    _PaletteSwatchDots(palette: draft),
                    const SizedBox(height: 6),
                    _cardDivider(),
                    row(s.settingsCustomPaletteLabelPeriod, draft.periodFill,
                        (c) => draft = _withColors(draft, periodFill: c)),
                    row(s.settingsCustomPaletteLabelPredictedFill, draft.predictedFill,
                        (c) => draft = _withColors(draft, predictedFill: c)),
                    row(s.settingsCustomPaletteLabelPredictedBorder, draft.predictedBorder,
                        (c) => draft = _withColors(draft, predictedBorder: c)),
                    row(s.settingsCustomPaletteLabelFertileFill, draft.fertileFill,
                        (c) => draft = _withColors(draft, fertileFill: c)),
                    row(s.settingsCustomPaletteLabelFertileBorder, draft.fertileBorder,
                        (c) => draft = _withColors(draft, fertileBorder: c)),
                    row(s.settingsCustomPaletteLabelToday, draft.todayRing,
                        (c) => draft = _withColors(draft, todayRing: c)),
                    row(s.settingsCustomPaletteLabelOvulation, draft.ovulationFill,
                        (c) => draft = _withColors(draft, ovulationFill: c)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: Text(s.settingsCustomPaletteCancel, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await CalendarPaletteController.instance.setCustomPalette(draft);
                              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(themeById(_themeId).primary),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: Text(s.settingsCustomPaletteSave, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Copia `base` sustituyendo solo los campos indicados — pequeño helper
  /// para ir construyendo el borrador de la paleta 'custom' color a color
  /// dentro de `_openCustomPaletteSheet` sin repetir los 7 campos cada vez.
  CalendarPaletteOption _withColors(
    CalendarPaletteOption base, {
    int? periodFill,
    int? predictedFill,
    int? predictedBorder,
    int? fertileFill,
    int? fertileBorder,
    int? todayRing,
    int? ovulationFill,
  }) {
    return CalendarPaletteOption(
      id: 'custom',
      name: 'Personalizado',
      periodFill: periodFill ?? base.periodFill,
      predictedFill: predictedFill ?? base.predictedFill,
      predictedBorder: predictedBorder ?? base.predictedBorder,
      fertileFill: fertileFill ?? base.fertileFill,
      fertileBorder: fertileBorder ?? base.fertileBorder,
      todayRing: todayRing ?? base.todayRing,
      ovulationFill: ovulationFill ?? base.ovulationFill,
    );
  }

  /// Diálogo con una rejilla de colores predefinidos para elegir uno —
  /// usado por `_openCustomPaletteSheet` para cada uno de los 7 colores.
  /// Se usa una paleta curada de swatches en vez de un selector RGB libre
  /// (más simple, sin dependencias nuevas, y evita elegir colores casi
  /// invisibles sobre el fondo de la app).
  Future<int?> _showColorSwatchPicker(BuildContext context, AppStrings s, int current) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.settingsCustomPaletteChooseColor,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: kCalendarSwatchColors.map((c) {
                    final selected = c == current;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(dialogContext).pop(c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.textPrimary : Colors.black.withOpacity(0.08),
                            width: selected ? 2.5 : 1,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleWellnessEnabled(bool value) async {
    setState(() => _wellnessEnabled = value);
    await _settings.saveWellnessEnabled(value);
  }

  // Devuelve `Future<bool>` (en vez de `Future<void>`) para que
  // AppleWatchScreen pueda conocer el resultado real del intento de
  // activación y actualizar su propio interruptor local; sigue siendo
  // válido como `onChanged` de un SwitchListTile (que espera
  // `void Function(bool)`) porque Dart permite descartar el valor de
  // retorno de una función asignada a un parámetro de tipo `void`.
  Future<bool> _toggleHealthSync(bool value) async {
    if (!value) {
      setState(() => _healthSyncEnabled = false);
      await _settings.saveHealthSyncEnabled(false);
      return false;
    }

    setState(() => _healthSyncBusy = true);
    final granted = await _healthSync.requestPermissions();
    if (!mounted) return granted;
    setState(() {
      _healthSyncEnabled = granted;
      _healthSyncBusy = false;
    });
    await _settings.saveHealthSyncEnabled(granted);
    if (!granted) {
      final s = AppStrings.of(context);
      _showSnack(s.settingsHealthSyncPermissionDenied);
    }
    return granted;
  }

  Future<void> _toggleSexAlwaysVisible(bool value) async {
    setState(() => _sexAlwaysVisible = value);
    await _settings.saveSexAlwaysVisible(value);
  }

  Future<void> _selectLanguage(String code) async {
    await LocaleController.instance.setLanguage(code);
    if (mounted) setState(() {});
  }

  Future<void> _selectTheme(String id) async {
    setState(() => _themeId = id);
    // ThemeController notifica a MaterialApp (en main.dart) para que
    // reconstruya el ThemeData global — así el AppBar de esta misma
    // pantalla y la barra de estado del sistema Android (que hereda el
    // mismo color) cambian al instante, sin esperar a reabrir la app.
    // ThemeController.setThemeId ya guarda el valor, así que no hace
    // falta llamar también a _settings.saveThemeId aquí.
    await ThemeController.instance.setThemeId(id);
    widget.onThemeChanged(id);
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => LockScreen(
            mode: LockScreenMode.create,
            onSuccess: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          ),
          fullscreenDialog: true,
        ),
      );
      if (created == true) {
        setState(() => _pinEnabled = true);
        if (mounted) _showSnack(AppStrings.of(context).settingsFaceIdEnabledConfirm);
      }
    } else {
      await _settings.clearPin();
      setState(() => _pinEnabled = false);
      if (mounted) _showSnack(AppStrings.of(context).settingsFaceIdDisabledConfirm);
    }
  }

  Future<void> _toggleDailyReminder(bool value) async {
    final updated = _dailyReminder.copyWith(enabled: value);
    setState(() => _dailyReminder = updated);
    await _settings.saveDailyReminderSettings(updated);
    if (value) await _dailyNotifications.requestPermissions();
    await _dailyNotifications.rescheduleDailyReminder(updated);
  }

  Future<void> _pickDailyReminderTime() async {
    final parts = _dailyReminder.time.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updated = _dailyReminder.copyWith(time: time);
    setState(() => _dailyReminder = updated);
    await _settings.saveDailyReminderSettings(updated);
    await _dailyNotifications.rescheduleDailyReminder(updated);
  }

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final data = await _storage.loadAll();
      // Si Bienestar está desactivado, esos datos (temperatura, agua,
      // sueño, peso) no deben salir en ningún sitio, incluido el archivo
      // de copia de seguridad — coherente con que tampoco se ven en el
      // día, Estadísticas ni Línea de tiempo mientras esté oculto. No se
      // borran de la app, solo se excluyen de lo que se exporta aquí.
      Map<String, dynamic> entryToJson(DayEntry entry) {
        final json = entry.toJson();
        if (!_wellnessEnabled) {
          json.remove('temp');
          json.remove('water');
          json.remove('sleep');
          json.remove('weight');
        }
        return json;
      }

      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'days': data.map((key, value) => MapEntry(key, entryToJson(value))),
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);

      final dir = await getTemporaryDirectory();
      final today = DateTime.now();
      final fileName =
          'cicloplus-backup-${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Copia de seguridad de CicloPlus',
      );
      _showSnack('Datos exportados ✓');
    } catch (_) {
      _showSnack('No se pudo exportar la copia de seguridad.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final path = result.files.single.path;
      if (path == null) throw Exception('Ruta de archivo no disponible');

      final content = await File(path).readAsString();
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final daysRaw = parsed['days'] as Map<String, dynamic>?;
      if (daysRaw == null) throw Exception('formato inválido');

      final imported = daysRaw.map(
        (key, value) => MapEntry(key, DayEntry.fromJson(value as Map<String, dynamic>)),
      );
      await _storage.saveAll(imported);
      widget.onDataChanged(imported);
      _showSnack('Datos importados ✓');
    } catch (_) {
      _showSnack('El archivo no parece un backup válido de CicloPlus.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPaywall() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(privacyPolicyUrlFor(LocaleController.instance.languageCode));
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      final s = AppStrings.of(context);
      _showSnack(s.settingsPrivacyPolicyError);
    }
  }

  /// "Mi objetivo": mismo campo que MeScreen (SettingsService.
  /// saveUserGoal), y "Seguir mi embarazo" activa el modo embarazo real
  /// igual que allí, para no crear un estado paralelo que los contradiga.
  Future<void> _selectGoal(String goal) async {
    setState(() => _userGoal = goal);
    await _settings.saveUserGoal(goal);
    if (goal == 'pregnancy' && !_pregnancy.enabled) {
      await _togglePregnancy(true);
    } else if (goal != 'pregnancy' && _pregnancy.enabled) {
      await _togglePregnancy(false);
    }
    // Primera vez que se elige "Intentar concebir": un par de preguntas
    // rápidas (fecha objetivo, tiempo intentándolo, etc.) para orientar
    // mejor desde el principio — ver widgets/conceive_intake_sheet.dart.
    if (goal == 'conceive') {
      await maybeShowConceiveIntake(context, _settings);
      // Recarga la duración de ciclo/periodo autoinformadas por si se
      // respondieron/cambiaron en el cuestionario recién cerrado, para que
      // "Configuración de predicción" (y el resto de esta pantalla) las
      // reflejen sin tener que salir y volver a entrar.
      final selfReportedCycleLen = await _settings.loadConceiveAvgCycleLength();
      final selfReportedPeriodLen = await _settings.loadConceiveAvgPeriodLength();
      if (!mounted) return;
      setState(() {
        _selfReportedCycleLen = selfReportedCycleLen;
        _selfReportedPeriodLen = selfReportedPeriodLen;
      });
    }
  }

  Future<void> _togglePregnancy(bool value) async {
    final updated = _pregnancy.copyWith(enabled: value);
    setState(() {
      _pregnancy = updated;
      if (value) {
        _userGoal = 'pregnancy';
      } else if (_userGoal == 'pregnancy') {
        _userGoal = 'period';
      }
    });
    await _settings.savePregnancySettings(updated);
    // Antes solo se guardaba `userGoal` al DESACTIVAR el modo embarazo
    // (`if (!value)`), nunca al activarlo: al activarlo, `_userGoal` pasaba
    // a 'pregnancy' solo en memoria (setState de arriba), pero
    // SharedPreferences se quedaba con el valor anterior ('period' o
    // 'conceive'). Eso dejaba activos, para una usuaria embarazada,
    // recordatorios y funciones de periodo/fertilidad que deberían
    // ocultarse en modo embarazo. Bug reportado en la auditoría previa a
    // publicación — ahora se guarda siempre, actives o desactives.
    await _settings.saveUserGoal(_userGoal);
    PartnerService().syncPregnancyData(widget.userId);
    // Primera vez que se activa el modo embarazo sin fecha guardada:
    // pedimos la fecha de última regla de inmediato (mismo selector que
    // usa la fila "Fecha de última regla" más abajo) en vez de dejar el
    // modo marcado como activo pero sin ninguna gráfica de bebé hasta que
    // la usuaria encuentre y toque ese selector por su cuenta — la
    // tarjeta de "Hoy" y "Seguir mi embarazo" exigen lmp != null. Si ya
    // había una fecha guardada de antes, no se vuelve a preguntar.
    if (value && _pregnancy.lmp == null) {
      await _pickLmpDate();
    }
  }

  /// Fecha de última regla (LMP): de ella se deriva toda la pantalla de
  /// seguimiento semanal del embarazo (PregnancyTrackingScreen). Antes solo
  /// existía este selector en HealthMenuScreen, una pantalla que quedó sin
  /// ninguna forma de abrirse tras la reorganización — así que activar
  /// "Modo embarazo" no llevaba a ningún sitio donde introducir la fecha.
  /// Se mueve aquí, a Configuración, que es donde realmente vive el resto
  /// del bloque "Embarazo" ahora.
  Future<void> _pickLmpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pregnancy.lmp ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null) return;
    final updated = _pregnancy.copyWith(lmp: picked);
    setState(() => _pregnancy = updated);
    await _settings.savePregnancySettings(updated);
    PartnerService().syncPregnancyData(widget.userId);
  }

  /// Interruptor "¿Esperas mellizos o más de un bebé?": ajusta la fecha
  /// probable de parto y el resto de los cálculos de semanas a un embarazo
  /// múltiple (37 semanas en vez de 40) en toda la app — ver
  /// PregnancyTrackingScreen/PartnerPregnancyScreen/today_screen.
  Future<void> _toggleTwins(bool value) async {
    final updated = _pregnancy.copyWith(isTwins: value);
    setState(() => _pregnancy = updated);
    await _settings.savePregnancySettings(updated);
    PartnerService().syncPregnancyData(widget.userId);
  }

  /// Interruptor "Compartir fotos del bebé con mi pareja": ver
  /// PartnerPregnancyScreen.hideBabyPhoto. Solo afecta a las imágenes —
  /// el resto del seguimiento (semana, fechas, consejos) ya se comparte
  /// en cuanto hay un socio vinculado, independientemente de este ajuste.
  Future<void> _toggleShareBabyPhotos(bool value) async {
    setState(() => _shareBabyPhotos = value);
    await _settings.saveShareBabyPhotos(value);
    PartnerService().syncPregnancyData(widget.userId);
  }

  Future<void> _exportForDoctor() async {
    setState(() => _exportingPdf = true);
    try {
      final predictor = CyclePredictor(
      widget.data,
      forceIrregular: _irregularCycleMode,
      selfReportedCycleLen: _selfReportedCycleLen,
      selfReportedPeriodLen: _selfReportedPeriodLen,
    );
      final s = AppStrings.of(context);
      await PdfReportService().exportAndShare(predictor, s);
    } catch (_) {
      if (mounted) {
        final s = AppStrings.of(context);
        _showSnack(s.exportPdfError);
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _confirmDeleteAllData() async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      // Diálogo de confirmación con look nativo de iOS (CupertinoAlertDialog):
      // tarjeta blanca muy redondeada, título en negrita, cuerpo gris
      // centrado y acción destructiva en rojo — mismo patrón para "Borrar
      // todos los datos" y "Borrar cuenta" (ver _confirmDeleteAccount).
      builder: (context) => CupertinoAlertDialog(
        title: Text(s.settingsDeleteAllDataConfirmTitle),
        content: Text(s.settingsDeleteAllDataConfirmBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    // Paso de seguridad adicional: antes de ejecutar el borrado (acción
    // irreversible), se le pide demostrar que es ella misma quien lo pide.
    // Con email/contraseña, reintroduce su contraseña; con Google/Facebook
    // (no hay contraseña de CicloPlus que pedir), repite el login social.
    // Si cancela o falla, no se borra nada.
    final reauthenticated = await _reauthenticateBeforeDelete(
      s,
      passwordBody: s.settingsDeleteConfirmPasswordBody,
      socialBody: s.settingsDeleteConfirmSocialBody,
    );
    if (!reauthenticated) return;
    if (!mounted) return;

    setState(() => _deletingAllData = true);
    try {
      // Borra el historial del ciclo (Firestore + caché) y todos los
      // ajustes locales (tema, perfil, recordatorios, idioma...). La
      // cuenta en sí (Firebase Auth) NO se toca — sigue existiendo y con
      // sesión iniciada, como si la persona acabara de registrarse.
      await _storage.deleteAll();
      await _settings.clearAll();
      widget.onDataChanged(const {});
      if (mounted) _showSnack(s.settingsDeleteAllDataSuccess);
    } finally {
      if (mounted) setState(() => _deletingAllData = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(s.settingsDeleteAccountConfirmTitle),
        content: Text(s.settingsDeleteAccountConfirmBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.settingsDeleteAccount),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final reauthenticated = await _reauthenticateBeforeDelete(
      s,
      passwordBody: s.settingsDeleteAccountConfirmPasswordBody,
      socialBody: s.settingsDeleteAccountConfirmSocialBody,
    );
    if (!reauthenticated) return;
    if (!mounted) return;

    setState(() => _deletingAccount = true);
    try {
      // Borrado inmediato y permanente, sin plazo de gracia: primero los
      // datos del ciclo + ajustes locales, y deleteAccount() se encarga de
      // borrar el resto de Firestore (pregnancy/cycle/partners/etc.) y la
      // cuenta de Firebase Authentication. Si quiere volver, tendrá que
      // registrarse de cero.
      await _storage.deleteAll();
      await _settings.clearAll();
      widget.onDataChanged(const {});
      await _authService.deleteAccount();
      if (!mounted) return;
      _showSnack(s.settingsDeleteAccountSuccess);
      widget.onSignOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  /// Pide confirmar la identidad antes de una de las dos acciones
  /// destructivas (borrar datos o borrar cuenta) — compartido por ambas
  /// para no duplicar los dos flujos (email con contraseña / Google-
  /// Facebook repitiendo login). Devuelve true solo si la reautenticación
  /// tuvo éxito; false si se canceló, la contraseña era incorrecta, o el
  /// login social falló — en cualquiera de esos casos no se debe proceder
  /// con el borrado.
  Future<bool> _reauthenticateBeforeDelete(
    AppStrings s, {
    required String passwordBody,
    required String socialBody,
  }) async {
    final provider = _authService.currentSignInProvider();

    if (provider == SignInProvider.email) {
      final passwordController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(s.settingsDeleteConfirmPasswordTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(passwordBody),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s.settingsDeleteConfirmPasswordHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => Navigator.of(context).pop(true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.cancel)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(s.settingsDeleteConfirmAction),
            ),
          ],
        ),
      );

      if (confirmed != true) return false;
      if (!mounted) return false;

      try {
        await _authService.reauthenticate(password: passwordController.text);
        return true;
      } on AuthException catch (_) {
        if (mounted) _showSnack(s.settingsDeleteConfirmWrongPassword);
        return false;
      }
    }

    // Google o Facebook: confirmación previa explicando que va a repetir
    // el login, y luego se lanza el flujo real del proveedor.
    final wantsToConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.settingsDeleteConfirmPasswordTitle),
        content: Text(socialBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(s.settingsDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (wantsToConfirm != true) return false;
    if (!mounted) return false;

    try {
      await _authService.reauthenticate();
      return true;
    } on AuthException catch (_) {
      if (mounted) _showSnack(s.settingsDeleteConfirmWrongPassword);
      return false;
    }
  }

  /// Reprograma la notificación de periodo/ovulación con el mismo cálculo
  /// que usa MainTabScreen (_syncPeriodReminder): CyclePredictor sobre
  /// widget.data, respetando _irregularCycleMode.
  void _syncPeriodReminder(ReminderSettings settings) {
    final predictor = CyclePredictor(
      widget.data,
      forceIrregular: _irregularCycleMode,
      selfReportedCycleLen: _selfReportedCycleLen,
      selfReportedPeriodLen: _selfReportedPeriodLen,
    );
    final nextPeriod = predictor.predictNextPeriod();
    final ovulation = predictor.predictOvulation(nextPeriod);
    _reminderService.reschedule(settings, nextPeriod, ovulationDate: ovulation);
  }

  /// Acceso adicional desde Configuración a la pantalla "Recordatorio" (ya
  /// existe como 4ª pestaña de MainTabScreen) — carga los mismos
  /// ReminderSettings reales desde ReminderService (no un valor por
  /// defecto decorativo) y guarda/reprograma de verdad si se cambia algo
  /// desde aquí, igual que MainTabScreen._onReminderToggle y afines, para
  /// que este acceso secundario no quede roto en silencio.
  Future<void> _openReminderFromSettings() async {
    final settings = await _reminderService.loadSettings();
    if (!mounted) return;
    final predictor = CyclePredictor(
      widget.data,
      forceIrregular: _irregularCycleMode,
      selfReportedCycleLen: _selfReportedCycleLen,
      selfReportedPeriodLen: _selfReportedPeriodLen,
    );
    final hasPrediction = predictor.predictNextPeriod() != null;

    Future<void> persist(ReminderSettings updated) async {
      await _reminderService.saveSettings(updated);
      _syncPeriodReminder(updated);
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReminderScreen(
          settings: settings,
          hasPrediction: hasPrediction,
          onPeriodToggle: (value) async {
            final updated = settings.copyWith(enabled: value);
            if (value) await _reminderService.requestPermissions();
            await persist(updated);
          },
          onDaysChanged: (days) async {
            final updated = settings.copyWith(daysBefore: days);
            await persist(updated);
          },
          onOvulationToggle: (value) async {
            final updated = settings.copyWith(ovulationEnabled: value);
            if (value) await _reminderService.requestPermissions();
            await persist(updated);
          },
          onFertileToggle: (value) async {
            final updated = settings.copyWith(fertileEnabled: value);
            if (value) await _reminderService.requestPermissions();
            await persist(updated);
          },
          themeId: _themeId,
          data: widget.data,
          irregularCycleMode: _irregularCycleMode,
          selfReportedCycleLen: _selfReportedCycleLen,
          selfReportedPeriodLen: _selfReportedPeriodLen,
          userGoal: _userGoal,
        ),
      ),
    );
  }

  Future<void> _openAppleWatch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppleWatchScreen(
          themeId: _themeId,
          healthSyncEnabled: _healthSyncEnabled,
          healthSyncBusy: _healthSyncBusy,
          onToggleHealthSync: _toggleHealthSync,
        ),
      ),
    );
    // El interruptor de Apple Salud vive también en esta pantalla (más
    // abajo); tras volver de AppleWatchScreen refrescamos para que
    // ambos reflejen el mismo estado si cambió allí.
    if (mounted) setState(() {});
  }

  /// Mismo cálculo que _syncPeriodReminder/MainTabScreen para mostrar en
  /// esta pantalla una vista previa real (no decorativa) de lo que el
  /// widget de pantalla de inicio está mostrando ahora mismo.
  Future<void> _openWidgetPlaceholder() async {
    final s = AppStrings.of(context);
    final predictor = CyclePredictor(
      widget.data,
      forceIrregular: _irregularCycleMode,
      selfReportedCycleLen: _selfReportedCycleLen,
      selfReportedPeriodLen: _selfReportedPeriodLen,
    );
    final cycleDay = predictor.currentDayInCycle();
    final nextPeriod = predictor.predictNextPeriod();
    String periodLine = '';
    if (nextPeriod != null) {
      final today = DateTime.now();
      final daysUntil = DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      if (daysUntil >= 0) periodLine = s.homeWidgetDaysUntilPeriod(daysUntil);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WidgetPlaceholderScreen(
          themeId: _themeId,
          cycleDayLine: cycleDay != null ? s.homeWidgetCycleDay(cycleDay) : s.homeWidgetNoDataLine,
          periodLine: periodLine,
        ),
      ),
    );
  }

  /// Abre el cliente de correo del usuario con un mensaje ya redactado
  /// (asunto + plantilla) dirigido al correo de soporte real de
  /// CicloPlus, para que el informe de errores sea funcional de
  /// verdad y no solo un aviso de "próximamente".
  Future<void> _openBugReport() async {
    final s = AppStrings.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: 'soportelambert@gmail.com',
      query: 'subject=${Uri.encodeComponent(s.settingsBugReportEmailSubject)}'
          '&body=${Uri.encodeComponent(s.settingsBugReportEmailBody)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showSnack(s.settingsBugReportError);
    }
  }

  /// Abre la ficha real de CicloPlus en Google Play para que la
  /// persona pueda puntuar la app, en vez de un aviso de "próximamente".
  Future<void> _openRateUs() async {
    final s = AppStrings.of(context);
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.cicloplus.cicloplus_app',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showSnack(s.settingsRateUsError);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final s = AppStrings.of(context);

    // Rediseño a partir del mockup de ChatGPT (noviembre 2026): cabecera
    // con degradado y perfil, y secciones agrupadas por categoría
    // (General, Privacidad, Dispositivos, Datos, Zona de peligro).
    // Toda la lógica y los handlers son los mismos de antes.
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      body: AbsorbPointer(
        absorbing: _busy || _exportingPdf || _deletingAllData || _deletingAccount,
        child: Column(
          children: [
            _settingsHeader(s),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  _groupHeader(Icons.settings_rounded, tr('General', 'General')),
                  _groupCard([
                    Row(
                      children: [
                        _iconBadge(Icons.language_rounded, const Color(0xFF4F86E8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.settingsLanguageTitle, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(s.settingsLanguageHint, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                final current = kAppLanguages.firstWhere(
                  (l) => l.code == LocaleController.instance.languageCode,
                  orElse: () => kAppLanguages.first,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _languageExpanded = !_languageExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(current.flag, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                current.nativeName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Icon(
                              _languageExpanded ? Icons.expand_less : Icons.expand_more,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      child: !_languageExpanded
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: kAppLanguages.map((lang) {
                                  final selected = lang.code == LocaleController.instance.languageCode;
                                  return GestureDetector(
                                    onTap: () {
                                      _selectLanguage(lang.code);
                                      setState(() => _languageExpanded = false);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected ? AppColors.primaryLight : AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(lang.flag, style: const TextStyle(fontSize: 16)),
                                          const SizedBox(width: 6),
                                          Text(
                                            lang.nativeName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                              color: selected ? AppColors.primary : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                );
              }),
                    _cardDivider(),
                    _groupedNavRow(
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFFE5486F),
                      label: s.settingsPredictionConfig,
                      subtitle: s.settingsPredictionConfigHint,
                      onTap: _openPredictionConfigSheet,
                    ),
                    _cardDivider(),
                    _iconCollapsible(Icons.people_alt_rounded, const Color(0xFFF0884F), _CollapsibleSection(
              title: s.settingsCoupleAppearanceTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.settingsCoupleAppearanceHint,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  ListenableBuilder(
                    listenable: CoupleIllustrationController.instance,
                    builder: (context, _) {
                      final currentId = CoupleIllustrationController.instance.illustrationId;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kCoupleIllustrations.map((opt) {
                          final selected = opt.id == currentId;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipOval(
                                  child: Image.asset(opt.asset, width: 22, height: 22, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 6),
                                Text(s.coupleIllustrationName(opt.id), style: const TextStyle(fontSize: 12.5)),
                              ],
                            ),
                            selected: selected,
                            onSelected: (_) => CoupleIllustrationController.instance.setIllustrationId(opt.id),
                            selectedColor: Color(themeById(_themeId).primary),
                            labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: selected ? Color(themeById(_themeId).primary) : AppColors.border),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
              )),
                    _cardDivider(),
                    _iconCollapsible(Icons.pregnant_woman_rounded, const Color(0xFF9B6BD6), _CollapsibleSection(
              title: s.settingsPregnancyTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _switchRow(
                    title: s.settingsPregnancyToggle,
                    subtitle: _pregnancy.enabled ? s.on_ : s.off_,
                    value: _pregnancy.enabled,
                    onChanged: _togglePregnancy,
                  ),
                  if (_pregnancy.enabled) ...[
                    const SizedBox(height: 10),
                    _dateRow(
                      label: s.settingsLmpLabel,
                      value: _pregnancy.lmp,
                      chooseLabel: s.settingsChooseDate,
                      onTap: _pickLmpDate,
                    ),
                  ],
                  if (_pregnancy.enabled) ...[
                    const SizedBox(height: 10),
                    _switchRow(
                      title: tr('¿Esperas mellizos, gemelos o más de un bebé?', 'Expecting twins or more than one baby?'),
                      subtitle: _pregnancy.isTwins
                          ? tr('Fecha de parto y semanas ajustadas a embarazo múltiple', 'Due date and weeks adjusted for a multiple pregnancy')
                          : tr('Activa esto si tu embarazo es de mellizos, gemelos o más', 'Turn this on if you are expecting twins or more'),
                      value: _pregnancy.isTwins,
                      onChanged: _toggleTwins,
                    ),
                  ],
                  if (_pregnancy.enabled && _pregnancy.lmp != null) ...[
                    const SizedBox(height: 10),
                    _groupedNavRow(
                      icon: Icons.pregnant_woman,
                      iconColor: Color(themeById(_themeId).primary),
                      label: s.pregnancyTrackingTitle,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PregnancyTrackingScreen(
                            lmp: _pregnancy.lmp!,
                            themeId: _themeId,
                            isTwins: _pregnancy.isTwins,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _switchRow(
                      title: tr('Compartir fotos del bebé con mi pareja', 'Share baby photos with my partner'),
                      subtitle: _shareBabyPhotos
                          ? tr('Tu socio vinculado también verá las fotos', 'Your linked partner will also see the photos')
                          : tr('Tu socio vinculado ve las fechas, pero no las fotos', 'Your linked partner sees the dates, but not the photos'),
                      value: _shareBabyPhotos,
                      onChanged: _toggleShareBabyPhotos,
                    ),
                  ],
                ],
              ),
              )),
                  ]),

                  _groupHeader(Icons.face_3_rounded, tr('Tu avatar', 'Your avatar')),
                  _groupCard([const AvatarSettings()]),

                  _groupHeader(Icons.spa_rounded, tr('Ciclo y privacidad', 'Cycle & privacy')),
                  _groupCard([const CycleExtraSettings()]),

                  _groupHeader(Icons.pets_rounded, 'Michi'),
                  _groupCard([const MichiSettings()]),

                  _groupHeader(Icons.favorite_rounded, tr('Privacidad', 'Privacy')),
                  ListenableBuilder(
                    listenable: AppStore.instance,
                    builder: (context, _) => _groupCard([
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _iconBadge(Icons.favorite_border_rounded, const Color(0xFFE5486F)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr('Registro de relaciones', 'Sex tracking'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 6),
                                _switchRow(
                                  title: tr('Vida sexual', 'Sex life'),
                                  subtitle: tr('Muestra la vida sexual en el calendario, el registro y "Mi salud". Si lo desactivas, tus datos no se borran.', 'Shows sex life in the calendar, logging and "My health". Turning it off does not delete your data.'),
                                  value: AppStore.instance.showSex,
                                  onChanged: (v) {
                                    AppStore.instance.showSex = v;
                                    AppStore.instance.commit();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),

                  _groupHeader(Icons.smartphone_rounded, tr('Dispositivos', 'Devices')),
                  _groupCard([
                    if (Platform.isIOS) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _iconBadge(Icons.favorite_rounded, const Color(0xFFE5486F)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.settingsAppleHealth, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(s.settingsHealthSyncHint, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(height: 6),
                                _switchRow(
                title: s.settingsHealthSyncToggle,
                subtitle: _healthSyncEnabled ? s.on_ : s.off_,
                value: _healthSyncEnabled,
                onChanged: _healthSyncBusy ? (_) {} : _toggleHealthSync,
              ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _cardDivider(),
                    ],
                    if (Platform.isIOS) ...[
                      _groupedNavRow(
                        icon: Icons.watch_rounded,
                        iconColor: const Color(0xFF9B6BD6),
                        label: s.settingsAppleWatch,
                        onTap: _openAppleWatch,
                      ),
                      _cardDivider(),
                    ],
                    _groupedNavRow(
                      icon: Icons.widgets_rounded,
                      iconColor: const Color(0xFFE5486F),
                      label: s.settingsWidget,
                      onTap: _openWidgetPlaceholder,
                    ),
                  ]),

                  _groupHeader(Icons.storage_rounded, tr('Datos', 'Data')),
                  _groupCard([
                    _groupedNavRow(
                      icon: Icons.error_outline_rounded,
                      iconColor: const Color(0xFFE5486F),
                      label: s.settingsBugReport,
                      onTap: _openBugReport,
                    ),
                    _cardDivider(),
                    _groupedNavRow(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF2A93B),
                      label: s.settingsRateUs,
                      onTap: _openRateUs,
                    ),
                    _cardDivider(),
                    _groupedNavRow(
                      icon: Icons.assignment_rounded,
                      iconColor: const Color(0xFF3E9B8F),
                      label: s.settingsExportForDoctor,
                      onTap: _exportingPdf ? () {} : _exportForDoctor,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _iconBadge(Icons.cloud_upload_rounded, const Color(0xFFE5486F)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.settingsBackupTitle, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(s.settingsBackupHint, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _exportBackup,
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kGreen,
                        side: const BorderSide(color: _kGreen, width: 1.3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      label: Text(s.settingsExport.replaceAll(RegExp(r'^[⬇⬆]\uFE0F?\s*'), ''), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _importBackup,
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kGreen,
                        side: const BorderSide(color: _kGreen, width: 1.3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      label: Text(s.settingsImport.replaceAll(RegExp(r'^[⬇⬆]\uFE0F?\s*'), ''), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
                        ],
                      ),
                    ),
                  ]),

                  _groupHeader(Icons.warning_amber_rounded, tr('Zona de peligro', 'Danger zone'), danger: true),
                  Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.settingsDeleteAllDataConfirmBody,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deletingAllData ? null : _confirmDeleteAllData,
                      icon: _deletingAllData
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                            )
                          : const Icon(Icons.delete_forever_outlined, size: 16, color: Colors.red),
                      label: Text(s.settingsDeleteAllData, style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deletingAccount ? null : _confirmDeleteAccount,
                      icon: _deletingAccount
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                            )
                          : const Icon(Icons.person_remove_outlined, size: 16, color: Colors.red),
                      label: Text(s.settingsDeleteAccount, style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                  const SizedBox(height: 16),
                  _groupCard([
                    _groupedNavRow(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF3E9B4F),
                      label: s.settingsPrivacyPolicyLink,
                      onTap: _openPrivacyPolicy,
                    ),
                  ]),
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
      ),
    );
  }

  /// Cabecera con degradado burdeos-rosa, avatar y flor.
  Widget _settingsHeader(AppStrings s) {
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
                      s.settingsTitle,
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

  /// Título de categoría: franja verde suave con icono y hoja.
  Widget _groupHeader(IconData icon, String title, {bool danger = false}) {
    final fg = danger ? const Color(0xFFD32F2F) : const Color(0xFF8E1B47);
    final bg = danger ? const Color(0xFFFDE0E3) : const Color(0xFFE3F1DC);
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
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg))),
            Icon(Icons.eco_rounded, size: 18, color: danger ? fg.withOpacity(0.45) : _kGreen),
          ],
        ),
      ),
    );
  }

  /// Tarjeta blanca que agrupa las filas de una categoría.
  Widget _groupCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8E1B47).withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  /// Sección plegable con icono de color a la izquierda.
  Widget _iconCollapsible(IconData icon, Color color, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBadge(icon, color),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 8), child: child)),
        ],
      ),
    );
  }

  /// Tarjeta de valor calculado (ciclo/período promedio), mismo estilo que
  /// `_reportCard` de MeScreen — reutilizado aquí dentro del bottomsheet de
  /// "Configuración de predicción" para no inventar una estética nueva.
  Widget _predictionValueCard({required String label, required int value, required String unit}) {
    final primary = Color(themeById(_themeId).primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      // Antes llevaba borde plano; ahora sombra suave, mismo lenguaje de
      // tarjeta elevada del rediseño aplicado en Inicio/Calendario.
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('$value $unit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: primary)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  /// Círculo de color suave con un icono dentro — mismo lenguaje visual
  /// que el mockup generado con ChatGPT y aprobado por la usuaria (icono
  /// en un badge circular junto a cada título/fila, en vez de un icono
  /// suelto), reutilizado en toda esta pantalla vía `_sectionCard` y
  /// `_groupedNavRow`.
  /// Iconos ilustrados generados con ChatGPT (assets/go/set_*.png) para
  /// la pantalla de Configuración; el resto sigue con el icono plano.
  static final Map<IconData, String> _illustrated = {
    Icons.language_rounded: 'globe',
    Icons.calendar_month_rounded: 'calendar',
    Icons.people_alt_rounded: 'couple',
    Icons.pregnant_woman_rounded: 'pregnant',
    Icons.favorite_border_rounded: 'heart',
    Icons.favorite_rounded: 'heart',
    Icons.watch_rounded: 'watch',
    Icons.widgets_rounded: 'widget',
    Icons.error_outline_rounded: 'error',
    Icons.star_rounded: 'star',
    Icons.assignment_rounded: 'doctor',
    Icons.cloud_upload_rounded: 'cloud',
    Icons.shield_outlined: 'shield',
  };

  Widget _iconBadge(IconData icon, Color color) {
    final img = _illustrated[icon];
    if (img != null) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Image.asset('assets/go/set_$img.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
    );
  }

  /// Tarjeta blanca de esquinas muy redondeadas y sombra suave que agrupa
  /// una sección completa de Configuración — rediseño de toda la pantalla
  /// (antes: título de texto + filas sueltas cada una con su propia
  /// sombra) aprobado por la usuaria a partir de un mockup generado con
  /// ChatGPT para la sección Suscripción/Backup/Borrar y extendido aquí a
  /// TODAS las secciones. Ninguna función/handler cambia: cada `child` es
  /// el mismo contenido/lógica que ya existía, solo cambia el envoltorio
  /// visual (más aire entre bloques, jerarquía por tarjetas).
  Widget _sectionCard({
    String? title,
    String? subtitle,
    IconData? titleIcon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  _iconBadge(titleIcon, Color(themeById(_themeId).primary)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

  /// Fila de navegación pensada para vivir DENTRO de un `_sectionCard`
  /// (una sola, o varias agrupadas y separadas por `_cardDivider`) — mismo
  /// contenido que `_navRow`, pero con icono en badge circular y sin su
  /// propia tarjeta/sombra individual (la pone el `_sectionCard` que la
  /// envuelve).
  Widget _groupedNavRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _iconBadge(icon, iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  /// Línea fina separadora entre filas agrupadas dentro de un mismo
  /// `_sectionCard` (p. ej. Apple Watch / Widget / Quitar anuncios /
  /// Informe de errores / Puntúanos, todas en una sola tarjeta).
  Widget _cardDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Divider(height: 1, color: AppColors.border.withOpacity(0.6)),
      );

  /// Nombre traducido de cada paleta de calendario (kCalendarPalettes usa
  /// nombres fijos en español en el catálogo, pensados solo como
  /// referencia de código — este mapeo los conecta con los strings i18n
  /// reales que sí respetan el idioma elegido en Configuración).
  String _calendarPaletteName(AppStrings s, String paletteId) {
    switch (paletteId) {
      case 'vivid':
        return s.calendarPaletteNameVivid;
      case 'highContrast':
        return s.calendarPaletteNameHighContrast;
      case 'suave':
        return s.calendarPaletteNameSuave;
      case 'calido':
        return s.calendarPaletteNameCalido;
      case 'joya':
        return s.calendarPaletteNameJoya;
      case 'custom':
        return s.calendarPaletteNameCustom;
      case 'pastel':
      default:
        return s.calendarPaletteNamePastel;
    }
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        Switch(value: value, activeColor: Colors.white, activeTrackColor: _kGreen, onChanged: onChanged),
      ],
    );
  }

  /// Fila de fecha (LMP para el modo embarazo), mismo patrón visual que
  /// `_timeRow` justo debajo — muestra `chooseLabel` como placeholder
  /// mientras no haya fecha elegida.
  Widget _dateRow({
    required String label,
    required DateTime? value,
    required String chooseLabel,
    required VoidCallback onTap,
  }) {
    final text = value == null ? chooseLabel : '${value.day}/${value.month}/${value.year}';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        // Antes llevaba borde plano; ahora sombra suave, mismo lenguaje de
        // tarjeta elevada del rediseño aplicado en Inicio/Calendario.
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _timeRow({required String label, required String time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        // Antes llevaba borde plano; ahora sombra suave, mismo lenguaje de
        // tarjeta elevada del rediseño aplicado en Inicio/Calendario.
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// Fila de navegación (icono + texto + chevron), mismo patrón que
  /// `_buildReminderSection` de HealthMenuScreen — usada para todos los
  /// accesos/placeholders nuevos de esta reorganización (Invitar pareja,
  /// Recordatorio, Apple Watch, Widget, anuncios, informe de errores,
  /// puntúanos). "Seguir ciclos de otros", "Foro" y "Ayúdanos con la
  /// traducción" se quitaron (eran solo placeholders de "próximamente",
  /// sin función real).
  Widget _navRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        // Antes llevaba borde plano; ahora sombra suave, mismo lenguaje de
        // tarjeta elevada del rediseño aplicado en Inicio/Calendario.
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(themeById(_themeId).primary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// 3 puntos de color (Periodo / borde de Previsto / borde de Fértil) que
/// sirven de vista previa dentro de cada chip de paleta en Configuración >
/// "Colores del calendario" — así se puede comparar visualmente antes de
/// elegir, sin salir de esta pantalla.
class _PaletteSwatchDots extends StatelessWidget {
  final CalendarPaletteOption palette;
  const _PaletteSwatchDots({required this.palette});

  @override
  Widget build(BuildContext context) {
    Widget dot(int colorValue) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(color: Color(colorValue), shape: BoxShape.circle),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(palette.periodFill),
        dot(palette.predictedBorder),
        dot(palette.fertileBorder),
      ],
    );
  }
}

/// Círculo de color tocable con un pequeño lápiz superpuesto — botón de
/// cada fila dentro de la hoja "Personalizar colores"
/// (`_openCustomPaletteSheet`), que al tocarlo abre la rejilla de swatches
/// para cambiar ese color concreto.
class _ColorSwatchButton extends StatelessWidget {
  final int color;
  final VoidCallback onTap;
  const _ColorSwatchButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.edit, size: 13, color: Colors.white54),
      ),
    );
  }
}

/// Paleta curada de colores para la rejilla de `_showColorSwatchPicker` —
/// pensada para que cualquier combinación elegida siga siendo legible
/// sobre el fondo claro de la app (nada casi-blanco ni fluorescente).
const List<int> kCalendarSwatchColors = [
  0xFFE91E8C, 0xFFD6336C, 0xFFC2185B, 0xFFAD1457,
  0xFFFF6F91, 0xFFFF8FA3, 0xFFFFB3C6,
  0xFFE64A19, 0xFFEF6C00, 0xFFFFA000, 0xFFFFCA28,
  0xFF9E9D24, 0xFF7CB342, 0xFF2F9E44, 0xFF2E7D32,
  0xFF00897B, 0xFF00ACC1, 0xFF0097A7, 0xFF0277BD,
  0xFF1565C0, 0xFF3949AB, 0xFF5C6BC0, 0xFF7E57C2,
  0xFF6A1B9A, 0xFF9B59B6, 0xFF8E24AA, 0xFFAB47BC,
  0xFF6D4C41, 0xFF8D6E63, 0xFF546E7A, 0xFF37474F,
];

/// Sección plegable con flecha: envuelve un bloque de Configuración (título +
/// contenido) para poder ocultarlo/mostrarlo tocando la cabecera — pedido de
/// la usuaria para "Mi objetivo", "Colores del calendario", "Apariencia de
/// tu pareja" y "Embarazo", que antes siempre mostraban todo su contenido
/// (chips, ilustraciones, etc.) ocupando espacio en la pantalla aunque la
/// persona no los estuviera usando en ese momento.
class _CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: widget.child,
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
