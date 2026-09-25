import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/cycle_predictor.dart' show dateKey;
import '../services/settings_service.dart' show AppThemeOption, SettingsService, themeById;
import '../theme/app_theme.dart';
import '../widgets/reminder_time_sheet.dart' show ReminderDatePickerSheet, ReminderTimePickerSheet;

/// Pestaña "Registrar" (índice 2 de la barra inferior): pantalla completa
/// (no modal) para registrar todos los datos de un día, con las secciones
/// ampliadas de la fase 4 del rediseño (medicamento, autoexamen de mamas,
/// ánimo, energía, piel y cabello, vida sexual detallada).
///
/// Es el único editor de día de la app — `DayEditorSheet` (hoja modal más
/// antigua) quedó retirado de todos los flujos. Por defecto (`targetDate`
/// nulo) trabaja sobre HOY y vive como pestaña fija con scroll normal; al
/// pasarle `targetDate` puede abrirse también sobre un día pasado (p. ej.
/// desde Calendario o Cronología vía `Navigator.push`, con
/// `showCloseButton: true`).
/// Orden por defecto (y catálogo completo de ids válidos) de las tarjetas
/// reordenables de Registrar — todas menos Flujo menstrual y Síntomas
/// (siempre primero) y la sección plegable "Opcional" (siempre al final).
/// Usado tanto aquí (RegisterScreen._cardOrder) como en
/// RegisterCardOrderScreen (settings_screen.dart) para la hoja de
/// reordenar. 'sexLife' solo se muestra en este bloque si "Mostrar 'Vida
/// sexual' siempre visible" está activo (ver _visibleOrderedCardIds); si no
/// aparece en el orden pero sí en esta lista, no pasa nada — simplemente no
/// se dibuja en este bloque fijo.
const List<String> kDefaultRegisterCardOrder = ['sexLife', 'mood', 'energy', 'skinHair', 'medication'];

class RegisterScreen extends StatefulWidget {
  final Map<String, DayEntry> data;
  final ValueChanged<Map<String, DayEntry>> onDataChanged;
  final String themeId;

  /// "Mi objetivo" (Configuración/Yo): 'period' | 'conceive' | 'pregnancy'.
  /// Se usa para ocultar aquí los mismos campos que ya se ocultan en el
  /// resto de la app según el objetivo — "Flujo menstrual" no aporta
  /// durante el embarazo (no hay periodos que registrar), y el círculo de
  /// "Temperatura" dentro de "Estilo de vida" solo tiene sentido con
  /// "Intentar concebir" (ver también me_screen.dart, mismo criterio).
  /// `'period'` por defecto para no romper los llamadores que aún no lo
  /// pasan explícitamente.
  final String userGoal;

  /// Fecha sobre la que trabaja esta pantalla. `null` (por defecto) usa el
  /// día de HOY — comportamiento original de esta pantalla como pestaña
  /// fija. Se puede pasar una fecha pasada para reemplazar por completo al
  /// antiguo `DayEditorSheet` (retirado de Calendario/Cronología para días
  /// no-hoy), de modo que exista un solo editor de día en toda la app.
  final DateTime? targetDate;

  /// Sección a la que hacer scroll automático al abrir esta pantalla,
  /// usada desde `FieldDetailScreen` (botón "Editar") para llevar a la
  /// usuaria directo al campo exacto en vez de al tope del scroll.
  /// Valores esperados: 'sexLife' | 'breastSelfExam' | 'temperature' |
  /// 'water' | 'sleep' | 'weight' (los 6 campos del grid de "Yo"). Los
  /// últimos 4 viven dentro de la tarjeta "Estilo de vida", pero cada uno
  /// tiene su propio círculo/key, así que el scroll aterriza exactamente
  /// en el campo pedido (p. ej. 'sleep' → círculo de Sueño), no solo en el
  /// tope de la tarjeta compartida. Si no coincide con ninguna sección
  /// conocida, no se hace nada.
  final String? focusSection;

  /// Muestra un botón X arriba a la derecha que hace `Navigator.pop`.
  /// `false` por defecto porque esta pantalla vive normalmente como pestaña
  /// fija en la barra inferior (`main_tab_screen.dart`), donde no hay nada
  /// a lo que "volver". Se pone en `true` solo cuando se abre con
  /// `Navigator.push` desde otra pantalla (p. ej. desde "Cronología" al
  /// tocar el día de hoy, o desde `FieldDetailScreen` → "Editar").
  final bool showCloseButton;

  /// Cambia la pestaña activa del `BottomNavigationBar` de
  /// `MainTabScreen` (mismo callback que ya usa `MeScreen`). Solo se pasa
  /// cuando esta pantalla vive como pestaña fija (`showCloseButton:
  /// false`); se usa para volver a "Hoy" (índice 0) tanto al pulsar
  /// Guardar como Cancelar, ya que en ese caso no hay nada que
  /// `Navigator.pop`.
  final ValueChanged<int>? onNavigateToTab;

  const RegisterScreen({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.themeId,
    this.targetDate,
    this.focusSection,
    this.showCloseButton = false,
    this.onNavigateToTab,
    this.userGoal = 'period',
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  AppThemeOption get _theme => themeById(widget.themeId);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _sexLifeKey = GlobalKey();
  final GlobalKey _breastSelfExamKey = GlobalKey();
  final GlobalKey _lifestyleKey = GlobalKey();
  // Keys individuales por círculo dentro de "Estilo de vida" — antes las 4
  // (Temperatura/Agua/Sueño/Peso) compartían _lifestyleKey y el scroll solo
  // llegaba al tope de la tarjeta completa. Con estas, `focusSection` puede
  // llevar el scroll exactamente al círculo pedido (p. ej. 'sleep' → el
  // círculo de Sueño queda centrado/visible, no solo la tarjeta).
  final GlobalKey _lifestyleTempKey = GlobalKey();
  final GlobalKey _lifestyleWaterKey = GlobalKey();
  final GlobalKey _lifestyleSleepKey = GlobalKey();
  final GlobalKey _lifestyleWeightKey = GlobalKey();

  late DateTime _today;
  late String _todayKey;

  // ---- Estado de todas las secciones, inicializado desde el DayEntry de
  // hoy (o valores por defecto si aún no existe) ----
  late String _flow;
  late Map<String, String> _symptomLevels;
  late List<String> _medication;
  late String? _breastSelfExam;
  late List<String> _mood;
  late String? _energy;
  late List<String> _skinHair;
  late TextEditingController _noteController;

  // Vida sexual detallada.
  late bool _sex;
  late bool _unprotected;
  late bool _sexMasturbation;
  late bool _sexNoOrgasm;
  late bool _sexOrgasm;
  late bool _sexDesire;
  late int _sexTimes;
  late bool _diu; // Método anticonceptivo: DIU colocado/en uso este día.
  // "No tuve": estado explícito (no derivado) que fija "Veces" en 1 y
  // bloquea +/- mientras esté activo. Ver getters/toggles más abajo.
  late bool _sexNone;

  // ---- 10. Estilo de vida (Temperatura/Bebe agua/Sueño/Peso) — porte FIEL
  // al diseño exacto verificado en el preview real de Lovable ("Cycle
  // Compass"), no una interpretación libre. Análogo a los demás campos de
  // estado: se carga desde el `DayEntry` de hoy en `_loadFromEntry` y se
  // persiste en `_buildEntry()` con `copyWith`, reutilizando tal cual los
  // campos ya existentes `temp`/`water`/`sleep`/`weight` de `DayEntry` (no
  // se duplican ni renombran). Temperatura: modal centrado con overlay
  // oscuro. Sueño: 2 pantallas completas (resumen con anillo + edición
  // AYER/HOY). Peso: pantalla completa con gráfica + formulario "Tus
  // datos" + 3 calculadoras. Bebe agua: panel compacto expandible in-place
  // (no modal ni pantalla completa), como en el diseño original. ----
  double? _temp; // °C
  int? _water; // vasos (unidad de almacenamiento siempre "vasos"; el
  // toggle Vasos/Gotas de la UI solo convierte para mostrar)
  double? _sleep; // horas (con fracción, ej. 7.5 = 7h30m), derivado de
  // restar `_sleepWakeTime` (hoy) menos `_sleepBedtime` (ayer) cruzando
  // medianoche.
  String? _sleepBedtime; // "Me dormí" (ayer), formato 'HH:mm'
  String? _sleepWakeTime; // "Me desperté" (hoy), formato 'HH:mm'
  double? _weight; // kg (unidad de almacenamiento siempre kg; el toggle
  // lb/kg de la UI solo convierte para mostrar)

  // Estado de UI (no persistido en DayEntry): unidad elegida para Agua y si
  // su panel expandible está abierto (oculto por defecto, como en Lovable).
  bool _waterUnitIsDrops = false; // false = Vasos (por defecto), true = Gotas
  bool _waterPanelOpen = false;
  // Controla si la cabecera plegable "Opcional" (Vida sexual /
  // Autoexamen de mamas / Estilo de vida) está expandida. Colapsada
  // por defecto: son secciones de uso ocasional, no algo que se llene
  // cada día como el resto de la pantalla.
  bool _optionalExpanded = false;
  // "Mostrar 'Vida sexual' siempre visible" (Configuración > Opciones
  // personalizadas): cuando está activo, la tarjeta de Vida sexual se
  // saca de la sección plegable "Opcional" y se muestra fija junto a
  // Flujo/Síntomas (ver `settingsSexAlwaysVisibleOn`). `false` por
  // defecto mientras se carga el valor real guardado, igual que el
  // resto de preferencias booleanas de esta pantalla.
  bool _sexAlwaysVisible = false;

  // Orden de las tarjetas "Vida sexual (si fija)/Ánimo/Energía/Piel y
  // cabello/Medicamento" — configurable desde Configuración > Opciones
  // personalizadas > "Orden de las tarjetas de Registrar". Empieza con el
  // orden original de siempre mientras se carga el valor real guardado
  // (ver _loadCardOrder), igual que _sexAlwaysVisible arriba.
  List<String> _cardOrder = List<String>.from(kDefaultRegisterCardOrder);

  static const int _waterGoalGlasses = 8; // meta diaria en vasos
  static const double _dropsPerGlass = 20; // conversión vasos -> gotas

  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _today = widget.targetDate ?? DateTime.now();
    _todayKey = dateKey(_today);
    _loadFromEntry(widget.data[_todayKey] ?? const DayEntry());
    _loadSexAlwaysVisible();
    _loadCardOrder();
    if (widget.focusSection == 'water') {
      // El círculo de Agua no muestra su detalle inline salvo que se abra
      // su panel expandible (_waterPanelOpen) — si venimos directo desde
      // "Editar" en FieldDetailScreen con foco en 'water', lo abrimos ya
      // para que la usuaria caiga justo sobre los controles, no solo sobre
      // el círculo cerrado.
      _waterPanelOpen = true;
    }
    // 'sexLife', 'breastSelfExam' y los 4 círculos de "Estilo de vida"
    // (temperature/water/sleep/weight) viven dentro de la sección plegable
    // "Opcional", colapsada por defecto (_optionalExpanded = false). Si no
    // la expandimos aquí, esas tarjetas ni siquiera se construyen, así que
    // `_scrollToKeyWithRetries` nunca encuentra el `currentContext` de su
    // key y el scroll a la sección pedida no hace nada (se queda arriba
    // del todo) — bug reportado: "Registrar ahora" en Vida sexual/Peso no
    // llevaba a esa sección.
    const kOptionalSectionFields = {'sexLife', 'breastSelfExam', 'temperature', 'water', 'sleep', 'weight'};
    if (kOptionalSectionFields.contains(widget.focusSection)) {
      _optionalExpanded = true;
    }
    if (widget.focusSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFocusSection();
        _maybeAutoOpenFocusSectionEntry();
      });
    }
  }

  /// Además de llevar el scroll hasta la sección, para Temperatura, Sueño y
  /// Peso abre directamente su "ventanilla"/pantalla de captura — la misma
  /// que se abre al tocar el círculo a mano (`_openTemperatureFlow` /
  /// `_openSleepFlow` / `_openWeightFlow`) — para no obligar a un toque más
  /// después de llegar aquí vía "Editar" desde FieldDetailScreen. Bebe agua
  /// ya tiene su propio atajo equivalente (`_waterPanelOpen`, arriba en
  /// initState). 'sexLife' y 'breastSelfExam' no lo necesitan: su contenido
  /// editable queda completamente a la vista con solo el scroll, sin un
  /// modal o pantalla intermedia de por medio.
  Future<void> _loadSexAlwaysVisible() async {
    final value = await _settingsService.loadSexAlwaysVisible();
    if (mounted) setState(() => _sexAlwaysVisible = value);
  }

  /// Carga el orden guardado de las tarjetas reordenables (ver _cardOrder,
  /// configurable desde Configuración > Opciones personalizadas > "Orden de
  /// las tarjetas de Registrar" → RegisterCardOrderScreen).
  Future<void> _loadCardOrder() async {
    final saved = await _settingsService.loadRegisterCardOrderRaw();
    // Combina el orden guardado (filtrando ids que ya no existan) con
    // cualquier id nuevo de kDefaultRegisterCardOrder que no estuviera
    // todavía guardado (por ejemplo si en el futuro se añade una tarjeta
    // nueva a este bloque) — así nunca desaparece una tarjeta por tener un
    // orden guardado antiguo e incompleto.
    final merged = saved.where(kDefaultRegisterCardOrder.contains).toList();
    for (final id in kDefaultRegisterCardOrder) {
      if (!merged.contains(id)) merged.add(id);
    }
    if (mounted) setState(() => _cardOrder = merged);
  }

  void _maybeAutoOpenFocusSectionEntry() {
    switch (widget.focusSection) {
      case 'temperature':
        _openTemperatureFlow();
        break;
      case 'sleep':
        _openSleepFlow();
        break;
      case 'weight':
        _openWeightFlow();
        break;
    }
  }

  /// Lleva el scroll hasta la sección pedida por `widget.focusSection`
  /// (viene de `FieldDetailScreen` al tocar "Editar"). 'temperature',
  /// 'water', 'sleep' y 'weight' viven todos dentro de la tarjeta "Estilo
  /// de vida", pero cada uno tiene su propia key (_lifestyleTempKey, etc.)
  /// para que el scroll aterrice exactamente en su círculo, no solo en el
  /// tope de la tarjeta compartida.
  void _scrollToFocusSection() {
    GlobalKey? key;
    switch (widget.focusSection) {
      case 'sexLife':
        key = _sexLifeKey;
        break;
      case 'breastSelfExam':
        key = _breastSelfExamKey;
        break;
      case 'temperature':
        key = _lifestyleTempKey;
        break;
      case 'water':
        key = _lifestyleWaterKey;
        break;
      case 'sleep':
        key = _lifestyleSleepKey;
        break;
      case 'weight':
        key = _lifestyleWeightKey;
        break;
      default:
        key = null;
    }
    // Un solo post-frame-callback a veces dispara antes de que el
    // Scrollable termine de medir todo el contenido que hay antes de la
    // sección buscada (p. ej. 'breastSelfExam' queda debajo de Síntomas,
    // que puede tener muchas filas). Se espera un pequeño delay real,
    // además del post-frame-callback, para dar tiempo a que el layout
    // completo del ListView esté listo antes de calcular el scroll.
    _scrollToKeyWithRetries(key, attemptsLeft: 20);
  }

  /// Reintenta encontrar el `currentContext` de [key] durante varios frames
  /// (hasta 20 intentos de 100ms = 2s), porque en dispositivos/emuladores
  /// lentos el `ListView` puede tardar más de un frame en montar secciones
  /// que están lejos del inicio (p. ej. 'breastSelfExam' es la sección 6
  /// de 10). Sin retry, `currentContext` puede seguir siendo null incluso
  /// 120ms después del build inicial.
  void _scrollToKeyWithRetries(GlobalKey? key, {required int attemptsLeft}) {
    if (key == null) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final context = key.currentContext;
      if (context == null) {
        if (attemptsLeft > 0) {
          _scrollToKeyWithRetries(key, attemptsLeft: attemptsLeft - 1);
        }
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        alignment: 0.1,
      );
    });
  }

  @override
  void didUpdateWidget(covariant RegisterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si `data` cambia desde fuera (p. ej. se editó el mismo día desde el
    // Calendario mientras esta pestaña seguía montada), refrescamos el
    // estado local para no pisar luego ese cambio externo con el "Guardar".
    final oldEntry = oldWidget.data[_todayKey];
    final newEntry = widget.data[_todayKey];
    if (oldEntry != newEntry) {
      _loadFromEntry(newEntry ?? const DayEntry());
    }
  }

  void _loadFromEntry(DayEntry entry) {
    _flow = entry.flow;
    _symptomLevels = Map<String, String>.from(entry.symptomLevels);
    _medication = List<String>.from(entry.medication);
    _breastSelfExam = entry.breastSelfExam;
    _mood = List<String>.from(entry.mood);
    _energy = entry.energy;
    _skinHair = List<String>.from(entry.skinHair);
    _noteController = TextEditingController(text: entry.note);
    _sex = entry.sex;
    _unprotected = entry.unprotected;
    _sexMasturbation = entry.sexMasturbation;
    _sexNoOrgasm = entry.sexNoOrgasm;
    _sexOrgasm = entry.sexOrgasm;
    _sexDesire = entry.sexDesire;
    _sexTimes = entry.sexTimes ?? 0;
    _diu = entry.diu;
    // "No tuve" se lee directamente del campo persistido `sexNone` (elección
    // explícita de la usuaria). Ya no se infiere desde `sexTimes`, porque
    // ahora "No tuve" también guarda el contador en 0 — el mismo valor que
    // "sin datos" — así que solo el campo explícito puede distinguir ambos
    // casos.
    _sexNone = entry.sexNone;
    _temp = entry.temp;
    _water = entry.water;
    _sleep = entry.sleep;
    _sleepBedtime = entry.sleepBedtime;
    _sleepWakeTime = entry.sleepWakeTime;
    _weight = entry.weight;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // No se puede registrar flujo/período en una fecha futura (no hay forma
  // de haber sangrado en un día que aún no llegó) — a diferencia de los
  // recordatorios, que sí pueden apuntar a fechas futuras sin problema. Se
  // compara `_today` (el día que se está editando, pese al nombre) contra
  // la fecha real de hoy, sin horas, para que "hoy" mismo siga permitido.
  bool get _isFutureEditedDate {
    final now = DateTime.now();
    final realToday = DateTime(now.year, now.month, now.day);
    final edited = DateTime(_today.year, _today.month, _today.day);
    return edited.isAfter(realToday);
  }

  // ---- Helpers de flujo ----
  int _flowDropletCount(String id) {
    switch (id) {
      case 'light':
        return 1;
      case 'medium':
        return 2;
      case 'heavy':
        return 3;
      default:
        return 0;
    }
  }

  void _cycleSymptom(String id) {
    setState(() {
      final next = cycleSymptomLevel(_symptomLevels[id]);
      if (next == null) {
        _symptomLevels.remove(id);
      } else {
        _symptomLevels[id] = next;
      }
    });
  }

  _SymptomLevelColor _symptomLevelColor(String? level) {
    switch (level) {
      case 'leve':
        return const _SymptomLevelColor(
          background: Color(0xFFFFF4E6),
          border: Color(0xFFFFB870),
          text: AppColors.textPrimary,
        );
      case 'moderado':
        return const _SymptomLevelColor(
          background: Color(0xFFFFE8CC),
          border: Color(0xFFFFA94D),
          text: Color(0xFF5C3200),
        );
      case 'fuerte':
        return const _SymptomLevelColor(
          background: AppColors.primary,
          border: AppColors.primary,
          text: Colors.white,
        );
      default:
        return const _SymptomLevelColor(
          background: AppColors.background,
          border: AppColors.border,
          text: AppColors.textPrimary,
        );
    }
  }

  /// Insignia a color por síntoma (reemplazo de los íconos Material planos
  /// grises/morados) — generadas con IA en estilo "insignia pastel plana":
  /// fondo de color sólido distinto por síntoma, silueta blanca simple,
  /// sombra suave, sin brillo de plástico. La app las recorta en círculo
  /// con [ClipOval] + `BoxFit.cover`, así que no necesitan fondo transparente.
  String _symptomAsset(String id) {
    switch (id) {
      case 'dolor':
        return 'assets/decorative/symptom_dolor.png';
      case 'animo':
        return 'assets/decorative/symptom_animo.png';
      case 'energia':
        return 'assets/decorative/symptom_energia.png';
      case 'antojos':
        return 'assets/decorative/symptom_antojos.png';
      case 'hinchazon':
        return 'assets/decorative/symptom_hinchazon.png';
      case 'sueno':
        return 'assets/decorative/symptom_sueno.png';
      case 'acne':
        return 'assets/decorative/symptom_acne.png';
      case 'dolorcab':
        return 'assets/decorative/symptom_cabeza.png';
      default:
        return 'assets/decorative/symptom_dolor.png';
    }
  }

  // ---- Vida sexual: "No tuve" es un estado explícito propio (no derivado)
  // que fija el contador "Veces" en 0 y bloquea +/- mientras esté activo.
  // Cualquier otro chip (excepto DIU, que es independiente por ser un
  // método anticonceptivo y no una actividad sexual) desactiva "No tuve"
  // automáticamente y libera el contador. Todos los demás chips admiten
  // selección múltiple simultánea. (Campo `_sexNone` declarado junto al
  // resto de estado de vida sexual, arriba). ----
  void _toggleSexNone() {
    setState(() {
      _sexNone = !_sexNone;
      if (_sexNone) {
        _sex = false;
        _unprotected = false;
        _sexMasturbation = false;
        _sexNoOrgasm = false;
        _sexOrgasm = false;
        _sexDesire = false;
      }
      _sexTimes = 0;
    });
  }

  /// Desactiva "No tuve" cuando se activa cualquier otro chip de vida
  /// sexual (excepto DIU). No hace nada si "No tuve" ya estaba inactivo.
  void _clearSexNone() {
    if (_sexNone) {
      _sexNone = false;
      _sexTimes = 0;
    }
  }

  /// Al activar (no al desactivar) cualquier chip de actividad sexual
  /// (excepto DIU, que es un método anticonceptivo independiente), si
  /// "Veces" está en 0 pasa a 1 automáticamente — igual que "No tuve", pero
  /// sin bloquear +/- después: la usuaria puede seguir ajustando el
  /// contador manualmente una vez que ya hay actividad marcada.
  void _bumpSexTimesIfZero() {
    if (_sexTimes == 0) _sexTimes = 1;
  }

  /// Complemento de [_bumpSexTimesIfZero]: si al desactivar un chip ya no
  /// queda NINGÚN chip de actividad marcado (DIU no cuenta, es un método
  /// anticonceptivo independiente), "Veces" vuelve a 0. Antes se quedaba
  /// "huérfano" en el último valor (p. ej. en 1) aunque ya no hubiera
  /// ninguna actividad marcada — pedido explícito de la usuaria: si se
  /// quita el botón, el contador debe volver a 0.
  void _resetSexTimesIfNoneActive() {
    if (!_sex && !_unprotected && !_sexMasturbation && !_sexNoOrgasm && !_sexOrgasm && !_sexDesire) {
      _sexTimes = 0;
    }
  }

  void _toggleSex() {
    setState(() {
      _sex = !_sex;
      if (_sex) {
        _clearSexNone();
        _bumpSexTimesIfZero();
      } else {
        _unprotected = false;
        _resetSexTimesIfNoneActive();
      }
    });
  }

  void _toggleUnprotected() {
    setState(() {
      _unprotected = !_unprotected;
      if (_unprotected) {
        _sex = true;
        _clearSexNone();
        _bumpSexTimesIfZero();
      } else {
        // Simétrico a _toggleSex (que al apagarse también apaga
        // _unprotected): si el chip que la usuaria tocó fue justo este
        // ("Sin protección"), apagarlo debe apagar también _sex — si no,
        // _sex se quedaba "huérfano" en true, lo que hacía que el chip
        // "Protegido" (activo quando _sex && !_unprotected) apareciera
        // marcado solo, sin que nadie lo tocara, y bloqueaba el reseteo
        // de "Veces" a 0 al no quedar ningún chip realmente activo.
        _sex = false;
        _resetSexTimesIfNoneActive();
      }
    });
  }

  void _toggleMasturbation() => setState(() {
        _sexMasturbation = !_sexMasturbation;
        if (_sexMasturbation) {
          _clearSexNone();
          _bumpSexTimesIfZero();
        } else {
          _resetSexTimesIfNoneActive();
        }
      });
  // "Con orgasmo" y "Sin orgasmo" son excluyentes por defecto (un único
  // encuentro no puede ser las dos cosas a la vez), pero con 2 o más
  // "Veces" registradas sí pueden coexistir — p. ej. dos encuentros, uno
  // con orgasmo y otro sin. Por eso, al activar uno, el otro solo se
  // desactiva si _sexTimes sigue por debajo de 2 (pedido explícito de la
  // usuaria).
  void _toggleNoOrgasm() => setState(() {
        _sexNoOrgasm = !_sexNoOrgasm;
        if (_sexNoOrgasm) {
          _clearSexNone();
          _bumpSexTimesIfZero();
          if (_sexTimes < 2) _sexOrgasm = false;
        } else {
          _resetSexTimesIfNoneActive();
        }
      });
  void _toggleOrgasm() => setState(() {
        _sexOrgasm = !_sexOrgasm;
        if (_sexOrgasm) {
          _clearSexNone();
          _bumpSexTimesIfZero();
          if (_sexTimes < 2) _sexNoOrgasm = false;
        } else {
          _resetSexTimesIfNoneActive();
        }
      });
  void _toggleDesire() => setState(() {
        _sexDesire = !_sexDesire;
        if (_sexDesire) {
          _clearSexNone();
          _bumpSexTimesIfZero();
        } else {
          _resetSexTimesIfNoneActive();
        }
      });
  // DIU es un método anticonceptivo, no una actividad sexual: se mantiene
  // totalmente independiente de "No tuve" y del contador "Veces".
  void _toggleDiu() => setState(() => _diu = !_diu);

  void _stepSexTimes(int delta) {
    // Con "No tuve" activo el contador queda fijo en 1 (no editable);
    // los botones +/- no deben hacer nada mientras ese estado esté activo.
    if (_sexNone) return;
    setState(() {
      _sexTimes = (_sexTimes + delta).clamp(0, 20);
      // "Con orgasmo" y "Sin orgasmo" solo pueden estar los dos activos a
      // la vez si hay 2 o más encuentros — si el contador baja de 2 con
      // ambos marcados, se desactiva "Sin orgasmo" para no dejar un estado
      // que ya no tiene sentido.
      if (_sexTimes < 2 && _sexNoOrgasm && _sexOrgasm) {
        _sexNoOrgasm = false;
      }
    });
  }

  void _toggleMood(String id) {
    setState(() {
      if (_mood.contains(id)) {
        _mood.remove(id);
      } else {
        _mood.add(id);
      }
    });
  }

  void _toggleSkinHair(String id) {
    setState(() {
      if (_skinHair.contains(id)) {
        _skinHair.remove(id);
      } else {
        _skinHair.add(id);
      }
    });
  }

  // Rediseño aprobado en Claude Visualize (mockup "medicamento_estilo_
  // editorial", 2026-08-16): antes era un AlertDialog genérico con
  // ChoiceChips. Ahora es un bottom sheet a pantalla casi completa, estilo
  // editorial de revista de salud — nada que ver con el lenguaje iOS
  // Settings usado en el resto de la app: fondo crema #FAF8F5, eyebrow
  // "BOTIQUÍN" en naranja quemado, título grande "¿Qué tomaste hoy?",
  // opciones como filas con radio + emoji grande, input de solo línea
  // inferior, y un botón final negro tipo píldora en vez del rosa/primary
  // habitual. La lógica de selección/validación/guardado no cambia.
  static const Map<String, String> _medicationEmoji = {
    'analgesico': '💊',
    'anticonceptivo': '🛡️',
    'antiinflamatorio': '🔥',
    'vitaminas': '🍊',
    'hierro': '🩸',
  };

  Future<void> _addMedication() async {
    final s = AppStrings.of(context);
    final customController = TextEditingController();
    String? selectedCatalogId;
    const eyebrowColor = Color(0xFFD85A30);
    const bg = Color(0xFFFAF8F5);
    const textMuted = Color(0xFF888780);
    const textPrimary = Color(0xFF2C2C2A);
    const lineColor = Color(0xFFECE7DF);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final canSave = selectedCatalogId != null || customController.text.trim().isNotEmpty;
            return Padding(
              padding: EdgeInsets.fromLTRB(26, 20, 26, 24 + MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.medicationSheetEyebrow.toUpperCase(),
                          style: const TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w500, color: eyebrowColor),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        borderRadius: BorderRadius.circular(17),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 16, color: textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.medicationSheetQuestion,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: textPrimary, height: 1.2),
                  ),
                  const SizedBox(height: 18),
                  ...kMedicationCatalog.where((m) => m['id'] != 'otro').map((m) {
                    final id = m['id']!;
                    final selected = selectedCatalogId == id;
                    final isLast = id == kMedicationCatalog[kMedicationCatalog.length - 2]['id'];
                    return InkWell(
                      onTap: () => setSheetState(() {
                        selectedCatalogId = selected ? null : id;
                        if (!selected) customController.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
                        decoration: BoxDecoration(
                          border: isLast ? null : const Border(bottom: BorderSide(color: lineColor)),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: id,
                              groupValue: selectedCatalogId,
                              onChanged: (_) => setSheetState(() {
                                selectedCatalogId = selected ? null : id;
                                if (!selected) customController.clear();
                              }),
                              activeColor: eyebrowColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(s.medicationLabelFor(id), style: const TextStyle(fontSize: 16, color: textPrimary)),
                            ),
                            Text(_medicationEmoji[id] ?? '💊', style: const TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                  Text(s.medicationSheetCustomLabel, style: const TextStyle(fontSize: 13, color: textMuted)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: customController,
                    style: const TextStyle(fontSize: 16, color: textPrimary),
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD6D0C4), width: 1.5)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD6D0C4), width: 1.5)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: eyebrowColor, width: 1.5)),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (value) => setSheetState(() {
                      if (value.trim().isNotEmpty) selectedCatalogId = null;
                    }),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: TextButton.styleFrom(foregroundColor: textMuted, padding: const EdgeInsets.symmetric(horizontal: 4)),
                        child: Text(s.cancel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canSave
                              ? () => Navigator.of(sheetContext)
                                  .pop(selectedCatalogId ?? customController.text.trim())
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: textPrimary,
                            disabledBackgroundColor: const Color(0xFFD6D0C4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 0,
                          ),
                          child: Text(s.medicationSheetSave,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty) return;
    setState(() {
      if (!_medication.contains(result)) _medication.add(result);
    });
  }

  void _removeMedication(String id) {
    setState(() => _medication.remove(id));
  }

  /// Etiqueta legible de un medicamento: si el id está en el catálogo usa
  /// la traducción normal; si es texto libre (no está en el catálogo,
  /// viene de la entrada manual del diálogo), se muestra tal cual se
  /// escribió.
  String _medicationDisplayLabel(AppStrings s, String id) {
    final inCatalog = kMedicationCatalog.any((m) => m['id'] == id);
    return inCatalog ? s.medicationLabelFor(id) : id;
  }

  DayEntry _buildEntry() {
    final existing = widget.data[_todayKey] ?? const DayEntry();
    return existing.copyWith(
      flow: _flow,
      symptoms: _symptomLevels.keys.toList(),
      symptomLevels: Map<String, String>.from(_symptomLevels),
      note: _noteController.text.trim(),
      sex: _sex,
      unprotected: _unprotected,
      medication: List<String>.from(_medication),
      breastSelfExam: _breastSelfExam,
      clearBreastSelfExam: _breastSelfExam == null,
      mood: List<String>.from(_mood),
      energy: _energy,
      clearEnergy: _energy == null,
      skinHair: List<String>.from(_skinHair),
      sexTimes: _sexTimes,
      sexDesire: _sexDesire,
      sexMasturbation: _sexMasturbation,
      sexNoOrgasm: _sexNoOrgasm,
      sexOrgasm: _sexOrgasm,
      diu: _diu,
      sexNone: _sexNone,
      temp: _temp,
      clearTemp: _temp == null,
      water: _water,
      clearWater: _water == null,
      sleep: _sleep,
      clearSleep: _sleep == null,
      sleepBedtime: _sleepBedtime,
      clearSleepBedtime: _sleepBedtime == null,
      sleepWakeTime: _sleepWakeTime,
      clearSleepWakeTime: _sleepWakeTime == null,
      weight: _weight,
      clearWeight: _weight == null,
    );
  }

  /// Persiste inmediatamente los campos de "Estilo de vida" (Temperatura/
  /// Agua/Sueño/Peso) sin esperar a que la usuaria toque el botón "Guardar"
  /// general de la pantalla — igual que el resto de esta pantalla actualiza
  /// solo su `setState` local, pero estos 4 campos vienen de modales/paneles
  /// separados que ya tienen su propia acción de confirmación ("Guardar" /
  /// "Listo" / tap en +), así que conviene escribirlos a `widget.data` en el
  /// momento en que se confirman, en vez de dejarlos solo en memoria hasta
  /// que se pulse "Guardar" al fondo de toda la pantalla.
  void _persistLifestyle() {
    final entry = _buildEntry();
    final updated = Map<String, DayEntry>.from(widget.data);
    updated[_todayKey] = entry;
    _enforceWeightHistoryLimit(updated);
    widget.onDataChanged(updated);
  }

  /// Límite de historial de Peso: como máximo 90 registros guardados. Al
  /// superar ese número (por ejemplo al añadir uno nuevo), se elimina el
  /// día completo más antiguo que tenga peso — no solo el campo de peso —
  /// para que el mapa de datos no vaya acumulando entradas indefinidamente.
  /// Se opera sobre `updated` in-place antes de persistir.
  void _enforceWeightHistoryLimit(Map<String, DayEntry> updated) {
    const maxWeightRecords = 90;
    final keysWithWeight = updated.entries
        .where((e) => e.value.weight != null)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (keysWithWeight.length <= maxWeightRecords) return;
    final overflow = keysWithWeight.length - maxWeightRecords;
    for (var i = 0; i < overflow; i++) {
      updated.remove(keysWithWeight[i]);
    }
  }

  void _save() {
    final entry = _buildEntry();
    final updated = Map<String, DayEntry>.from(widget.data);
    updated[_todayKey] = entry;
    _enforceWeightHistoryLimit(updated);
    widget.onDataChanged(updated);

    // Si esta pantalla se abrió con Navigator.push (showCloseButton: true,
    // p. ej. desde Calendario/Cronología/"Editar" en Yo), Guardar también
    // vuelve atrás a donde estaba la usuaria antes de entrar aquí — igual
    // que hace la X.
    if (widget.showCloseButton) {
      Navigator.of(context).pop();
      return;
    }

    // Pestaña fija ("Hoy"/Calendario/Registrar/Recordatorio/Yo): no hay
    // nada a lo que Navigator.pop, así que Guardar lleva a la usuaria de
    // vuelta a "Hoy" (pestaña principal, índice 0) en vez de dejarla
    // parada en Registrar con solo el snackbar.
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(0);
      return;
    }

    final s = AppStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.registerSavedConfirm)),
    );
  }

  /// Botón "Cancelar": descarta los cambios locales sin guardar. Igual que
  /// Guardar, hace `Navigator.pop` si esta pantalla se abrió empujada
  /// (showCloseButton: true), o navega a "Hoy" si vive como pestaña fija.
  void _cancel() {
    if (widget.showCloseButton) {
      Navigator.of(context).pop();
      return;
    }
    widget.onNavigateToTab?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final dateLabel = s.dayLabel(_today.day, _today.month);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // `top: false` (versión anterior) dejaba la fecha y, sobre todo, el
        // botón X de cerrar (cuando showCloseButton es true) pegados justo
        // debajo de la muesca/cámara del teléfono, con muy poco margen —
        // mismo bug ya corregido en stats_screen.dart/review_screen.dart:
        // el X quedaba ahí pero no respondía al toque porque su área
        // quedaba tapada por el recorte físico de la pantalla.
        bottom: false,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          // `cacheExtent` grande (a propósito, muy por encima del alto de
          // cualquier dispositivo): esta pantalla es una lista corta y
          // acotada de ~10 tarjetas (no un listado largo/infinito), así que
          // el costo de construir todo por adelantado es insignificante.
          // Sin esto, `SliverChildListDelegate` solo monta los `Element`
          // (y por tanto solo resuelve `GlobalKey.currentContext`) de las
          // secciones dentro del viewport + el cache extent por defecto
          // (250px) — motivo por el que `_breastSelfExamKey.currentContext`
          // quedaba en null indefinidamente en `_scrollToKeyWithRetries`
          // (sección 6 de 10, bastante más abajo que esos 250px), mientras
          // que `_sexLifeKey` (sección 2, ya dentro de esos 250px) sí
          // resolvía a la primera. Ningún número de reintentos podía
          // arreglarlo: el `Element` de la sección simplemente no existía
          // todavía. Con `cacheExtent` cubriendo toda la lista, todas las
          // secciones quedan montadas desde el primer frame y
          // `Scrollable.ensureVisible` puede encontrarlas de inmediato.
          cacheExtent: 4000,
          children: [
            if (widget.showCloseButton)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(
                    tooltip: s.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            else
              Text(dateLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),

            // ---- 1. Flujo menstrual ----
            // No aporta durante el embarazo (no hay periodos que
            // registrar) — se oculta solo en ese objetivo, igual que el
            // resto de la app (ver me_screen.dart/today_screen.dart).
            if (widget.userGoal != 'pregnancy') ...[
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(s.flowMenstrualSectionTitle),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: _isFutureEditedDate ? 0.4 : 1.0,
                      child: Row(
                        children: kFlowOptions.map((opt) {
                          final id = opt['id']!;
                          final selected = _flow == id;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: id == kFlowOptions.last['id'] ? 0 : 10),
                              child: _dropletChip(
                                label: s.flowTextOnlyLabelFor(id),
                                dropletCount: _flowDropletCount(id),
                                dropletColor: Color(_theme.primary),
                                selected: selected,
                                accent: Color(_theme.primary),
                                // Una fecha futura no puede tener flujo
                                // registrado (todavía no ha ocurrido) — los
                                // recordatorios sí se pueden programar a
                                // futuro, esta restricción es solo del
                                // flujo/período.
                                onTap: _isFutureEditedDate ? null : () => setState(() => _flow = id),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_isFutureEditedDate) ...[
                      const SizedBox(height: 8),
                      Text(
                        s.periodFutureDateHint,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            // ---- 2. Síntomas ----
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(s.symptomsLabel),
                  const SizedBox(height: 4),
                  Text(s.symptomsHint, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: kSymptomCatalog.map((cat) {
                      final id = cat['id']!;
                      final level = _symptomLevels[id];
                      final color = _symptomLevelColor(level);
                      final selected = level != null;
                      return GestureDetector(
                        onTap: () => _cycleSymptom(id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? color.background : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: selected ? color.border : AppColors.border, width: selected ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(color: color.border, width: 2)
                                      : null,
                                ),
                                child: ClipOval(
                                  child: Image.asset(_symptomAsset(id), fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      s.symptomLabelFor(id),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: selected ? color.text : AppColors.textPrimary,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                    if (level != null)
                                      Text(
                                        s.symptomLevelLabelFor(level),
                                        style: TextStyle(fontSize: 10, color: color.border.withOpacity(0.9)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---- 2.5-6. Vida sexual (si "siempre visible")/Ánimo/Energía/
            // Piel y cabello/Medicamento — orden configurable desde
            // Configuración > Opciones personalizadas > "Orden de las
            // tarjetas de Registrar" (ver _cardOrder, _visibleOrderedCardIds
            // y _buildOrderedCard más abajo). Flujo menstrual/Síntomas
            // (arriba) y la sección plegable "Opcional" (abajo) quedan
            // siempre fijos, fuera de este orden — la usuaria solo pidió
            // reordenar "las demás tarjetas", no esas dos.
            for (final _cardId in _visibleOrderedCardIds) ...[
              _buildOrderedCard(_cardId, s),
              const SizedBox(height: 16),
            ],

            // ---- 7-9. Opcional (Vida sexual / Autoexamen de mamas /
            // Estilo de vida): agrupadas bajo una cabecera plegable porque
            // son secciones de uso ocasional, no diario, a diferencia de
            // Flujo/Síntomas/Ánimo/Energía/Piel y cabello/Medicación/Diario
            // que sí se registran a menudo. Colapsada por defecto; un tap
            // en la cabecera la expande/contrae (mismo patrón de
            // Icons.expand_more/expand_less que el selector de idioma en
            // Configuración). ----
            _sectionCard(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _optionalExpanded = !_optionalExpanded),
                child: Row(
                  children: [
                    Expanded(child: _sectionTitle(s.registerOptionalSectionLabel)),
                    Icon(
                      _optionalExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_optionalExpanded) ...[
              const SizedBox(height: 16),
              // -- Vida sexual -- (salvo que "Mostrar Vida sexual siempre
              // visible" esté activo: en ese caso ya se dibujó arriba, junto
              // a Flujo/Síntomas, y no se repite aquí dentro de "Opcional").
              if (!_sexAlwaysVisible) ...[
                _sexLifeSectionCard(s),
                const SizedBox(height: 16),
              ],
            // -- Autoexamen de mamas --
            _sectionCard(
              key: _breastSelfExamKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(s.breastSelfExamSectionTitle),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kBreastSelfExamCatalog.map((cat) {
                      final id = cat['id']!;
                      final selected = _breastSelfExam == id;
                      return _catalogChip(
                        label: '${cat['emoji']} ${s.breastSelfExamLabelFor(id)}',
                        selected: selected,
                        onTap: () => setState(() => _breastSelfExam = selected ? null : id),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // -- Estilo de vida (Temperatura / Bebe agua / Sueño /
            // Peso) — porte fiel al diseño exacto de Lovable: título arriba
            // a la izquierda, 4 círculos medianos en fila con anillo grueso
            // coloreado cuando ya hay dato guardado hoy (delgado con icono
            // de línea si no). Colores semánticos fijos por círculo (no el
            // color de tema), tal como en el diseño original: rosa para
            // Temperatura, azul para Agua, ámbar para Sueño, rosa/magenta
            // para Peso. ----
            _sectionCard(
              key: _lifestyleKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(s.lifestyleSectionTitle),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // La temperatura basal es una herramienta de método de
                      // fertilidad (detectar la ovulación) — solo tiene
                      // sentido con "Intentar concebir", igual que el resto
                      // de la app (ver me_screen.dart).
                      if (widget.userGoal == 'conceive')
                        Expanded(
                          child: _lifestyleCircle(
                            key: _lifestyleTempKey,
                            icon: Icons.thermostat,
                            iconColor: const Color(0xFFE64980),
                            label: s.lifestyleTemperature,
                            valueLabel: _temp != null ? '${_temp!.toStringAsFixed(1)}°C' : s.lifestyleNoData,
                            hasData: _temp != null,
                            onTap: _openTemperatureFlow,
                          ),
                        ),
                      Expanded(
                        child: _lifestyleCircle(
                          key: _lifestyleWaterKey,
                          icon: Icons.water_drop,
                          iconColor: const Color(0xFF339AF0),
                          label: s.lifestyleDrinkWater,
                          valueLabel: _waterValueLabel(s),
                          hasData: (_water ?? 0) > 0,
                          onTap: () => setState(() => _waterPanelOpen = !_waterPanelOpen),
                        ),
                      ),
                      Expanded(
                        child: _lifestyleCircle(
                          key: _lifestyleSleepKey,
                          icon: Icons.bedtime,
                          iconColor: const Color(0xFFF59F00),
                          label: s.lifestyleSleep,
                          valueLabel: _sleepValueLabel(s),
                          hasData: _sleep != null,
                          showTopDot: _sleep == null,
                          onTap: _openSleepFlow,
                        ),
                      ),
                      Expanded(
                        child: _lifestyleCircle(
                          key: _lifestyleWeightKey,
                          icon: Icons.monitor_weight_outlined,
                          iconColor: const Color(0xFFE64980),
                          label: s.lifestyleWeight,
                          valueLabel: _weight != null
                              ? '${_weight!.toStringAsFixed(1)} ${s.lifestyleWeightUnitKg}'
                              : s.lifestyleNoData,
                          hasData: _weight != null,
                          onTap: _openWeightFlow,
                        ),
                      ),
                    ],
                  ),
                  if (_waterPanelOpen) ...[
                    const SizedBox(height: 16),
                    _buildWaterPanel(s),
                  ],
                ],
              ),
            ),
            ],

            const SizedBox(height: 16),

            // ---- 10. Escribir diario ----
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(s.diaryLabel),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: s.diaryHint,
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.all(12),
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
                        borderSide: BorderSide(color: Color(_theme.primary)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // El botón Guardar ahora vive fijo en `bottomNavigationBar` (ver
            // abajo), así que aquí ya no hace falta el SizedBox final extra
            // de antes del botón — solo un respiro antes del borde inferior
            // de la lista.
            const SizedBox(height: 8),
          ],
        ),
      ),
      // ---- Cancelar + Guardar: fijos abajo, con separación visual clara
      // del contenido mediante sombra hacia arriba + SafeArea propio para
      // no quedar debajo de la barra de gestos del sistema. Cancelar
      // (contorno, a la izquierda) descarta sin guardar; Guardar (relleno,
      // a la derecha) persiste los cambios — mismo par que ya usan otras
      // pantallas de confirmación de la app. ----
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _cancel,
                  child: Text(
                    s.cancel,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(_theme.primary),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _save,
                  child: Text(
                    s.save,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ids de las tarjetas reordenables ("Vida sexual" si está fija arriba,
  /// Ánimo, Energía, Piel y cabello, Medicamento) que SÍ corresponde
  /// mostrar ahora mismo, en el orden guardado por la usuaria (`_cardOrder`,
  /// cargado desde SettingsService en initState — ver kDefaultRegisterCardOrder).
  /// "Vida sexual" se filtra aquí igual que antes: solo aparece en este
  /// bloque fijo si `_sexAlwaysVisible` está activo; si no, sigue viviendo
  /// dentro de "Opcional" y este getter la omite para no duplicarla.
  List<String> get _visibleOrderedCardIds =>
      _cardOrder.where((id) => id != 'sexLife' || _sexAlwaysVisible).toList();

  /// Construye la tarjeta correspondiente a cada id de _visibleOrderedCardIds.
  Widget _buildOrderedCard(String id, AppStrings s) {
    switch (id) {
      case 'sexLife':
        return _sexLifeSectionCard(s);
      case 'mood':
        return _moodSectionCard(s);
      case 'energy':
        return _energySectionCard(s);
      case 'skinHair':
        return _skinHairSectionCard(s);
      case 'medication':
        return _medicationSectionCard(s);
      default:
        return const SizedBox.shrink();
    }
  }

  /// ---- Ánimo ---- (extraída a método para poder reordenarla — ver
  /// _buildOrderedCard).
  Widget _moodSectionCard(AppStrings s) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(s.moodSectionTitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kMoodCatalog.map((cat) {
              final id = cat['id']!;
              final selected = _mood.contains(id);
              return _catalogChip(
                label: '${cat['emoji']} ${s.moodLabelFor(id)}',
                selected: selected,
                onTap: () => _toggleMood(id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// ---- Energía ---- (extraída a método — ver _buildOrderedCard).
  Widget _energySectionCard(AppStrings s) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(s.energySectionTitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kEnergyOptions.map((cat) {
              final id = cat['id']!;
              final selected = _energy == id;
              return _catalogChip(
                label: '${cat['emoji']} ${s.energyLabelFor(id)}',
                selected: selected,
                onTap: () => setState(() => _energy = selected ? null : id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// ---- Piel y cabello ---- (extraída a método — ver _buildOrderedCard).
  Widget _skinHairSectionCard(AppStrings s) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(s.skinHairSectionTitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kSkinHairCatalog.map((cat) {
              final id = cat['id']!;
              final selected = _skinHair.contains(id);
              return _catalogChip(
                label: '${cat['emoji']} ${s.skinHairLabelFor(id)}',
                selected: selected,
                onTap: () => _toggleSkinHair(id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// ---- Añadir medicamento ---- (extraída a método — ver
  /// _buildOrderedCard). Rediseño editorial (Claude Visualize, 2026-08-16),
  /// a juego con el sheet de _addMedication: eyebrow naranja quemado en vez
  /// del título mayúscula gris genérico, botón pill con relleno crema en
  /// vez del OutlinedButton con color del tema, y chips con emoji cuando ya
  /// hay medicamentos guardados.
  Widget _medicationSectionCard(AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  s.medicationSectionTitle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD85A30),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              InkWell(
                onTap: _addMedication,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2A),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 15, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(s.medicationAddButton,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_medication.isEmpty)
            Text(s.medicationEmpty, style: const TextStyle(fontSize: 13, color: Color(0xFF888780)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _medication.map((id) {
                return Container(
                  padding: const EdgeInsets.only(left: 12, right: 6, top: 7, bottom: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_medicationEmoji[id] ?? '💊', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(_medicationDisplayLabel(s, id),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2A))),
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: () => _removeMedication(id),
                        borderRadius: BorderRadius.circular(100),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 14, color: Color(0xFF888780)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// Tarjeta de "Vida sexual" — extraída a su propio método para poder
  /// colocarla en dos sitios distintos del `build()` según "Mostrar 'Vida
  /// sexual' siempre visible" (Configuración > Opciones personalizadas):
  /// fija junto a Flujo/Síntomas cuando `_sexAlwaysVisible` es true, o
  /// dentro de la sección plegable "Opcional" (comportamiento original)
  /// cuando es false. El contenido y la lógica no cambian, solo dónde se
  /// dibuja.
  Widget _sexLifeSectionCard(AppStrings s) {
    return _sectionCard(
      key: _sexLifeKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle(s.sexLifeLabel)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEAF0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  s.sexLifeRegistroBadge,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF72243E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 4,
            childAspectRatio: 0.78,
            children: [
              _sexCircle(
                label: s.sexNoneLabel,
                icon: Icons.close,
                active: _sexNone,
                color: const Color(0xFF888780),
                onTap: _toggleSexNone,
              ),
              _sexCircle(
                label: s.sexUnprotectedFullLabel,
                icon: Icons.favorite,
                active: _unprotected,
                color: const Color(0xFFD4537E),
                onTap: _toggleUnprotected,
              ),
              _sexCircle(
                label: s.sexProtectedLabel,
                icon: Icons.verified_user,
                active: _sex && !_unprotected,
                color: const Color(0xFF378ADD),
                onTap: _toggleSex,
              ),
              _sexCircle(
                label: s.sexMasturbationLabel,
                icon: Icons.auto_awesome,
                active: _sexMasturbation,
                color: const Color(0xFFBA7517),
                onTap: _toggleMasturbation,
              ),
              _sexCircle(
                label: s.sexNoOrgasmLabel,
                icon: Icons.remove,
                active: _sexNoOrgasm,
                color: const Color(0xFF888780),
                onTap: _toggleNoOrgasm,
              ),
              _sexCircle(
                label: s.sexOrgasmLabel,
                icon: Icons.bolt,
                active: _sexOrgasm,
                color: const Color(0xFFD4537E),
                onTap: _toggleOrgasm,
              ),
              _sexCircle(
                label: s.sexDesireLabel,
                icon: Icons.local_fire_department,
                active: _sexDesire,
                color: const Color(0xFFD85A30),
                onTap: _toggleDesire,
              ),
              _sexCircle(
                label: s.calendarLegendCatDiu,
                icon: Icons.add,
                active: _diu,
                color: const Color(0xFF7F77DD),
                onTap: _toggleDiu,
                fillWhenActive: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.sexTimesTotalLabel.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4, color: Color(0xFFB4B2A9)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.sexTimesShortLabel,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                _darkRoundIconButton(icon: Icons.remove, onTap: () => _stepSexTimes(-1), enabled: !_sexNone),
                const SizedBox(width: 10),
                SizedBox(
                  width: 22,
                  child: Text(
                    '$_sexTimes',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                _darkRoundIconButton(
                    icon: Icons.add, onTap: () => _stepSexTimes(1), enabled: !_sexNone, accentWhenEnabled: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta blanca con esquinas redondeadas y sombra sutil que envuelve
  /// cada sección del registro (mismo patrón que `status_card.dart`:
  /// `AppColors.cardBackground` + radio 16 + `BoxShadow` suave con el color
  /// de acento del tema a opacidad baja) para separar visualmente las
  /// secciones sobre el fondo pastel de la pantalla, sin tocar ningún
  /// campo/handler dentro de `child`.
  Widget _sectionCard({required Widget child, Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(_theme.primary).withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Título de sección: mismo tratamiento tipográfico (tamaño, peso y
  /// color) en todas las tarjetas para que la jerarquía visual sea
  /// consistente en toda la pantalla — versalitas (mayúsculas) + tracking
  /// amplio, como en el diseño de referencia aprobado en v0.
  Widget _sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      );

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap, bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: Color(_theme.primary)),
        ),
      ),
    );
  }

  /// Círculo con icono propio por categoría, usado en el nuevo diseño de
  /// "Vida sexual" (aprobado en Lovable 2026-08-16) — reemplaza los chips de
  /// texto plano de `_sexChip`. Inactivo: fondo tenue del color + icono
  /// coloreado. Activo (`fillWhenActive: true`, usado solo por DIU):
  /// círculo sólido con icono blanco, para que se note claramente que es un
  /// método anticonceptivo en uso, no una actividad puntual del día como
  /// las demás. El resto de categorías solo aclaran el fondo al activarse,
  /// ya que su "activo" es más efímero (se refiere solo al día de hoy).
  Widget _sexCircle({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
    bool fillWhenActive = false,
  }) {
    final solid = fillWhenActive && active;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: solid ? color : color.withOpacity(active ? 0.16 : 0.10),
              border: active && !solid ? Border.all(color: color, width: 1.5) : null,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: solid ? Colors.white : color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: solid ? FontWeight.w600 : FontWeight.w400,
              color: solid ? color : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Botón -/+ redondo para la tarjeta oscura "Total encuentros" del nuevo
  /// diseño de Vida sexual — mismo patrón que `_roundIconButton` pero con
  /// colores invertidos (fondo oscuro) porque vive sobre un fondo casi
  /// negro en vez del fondo blanco de tarjeta habitual. El botón "+" puede
  /// resaltarse en el color de acento del tema (`accentWhenEnabled`) para
  /// que se note como la acción principal, igual que en Lovable.
  Widget _darkRoundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
    bool accentWhenEnabled = false,
  }) {
    final useAccent = enabled && accentWhenEnabled;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: useAccent ? Color(_theme.primary) : const Color(0xFF444441),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  /// Chip genérico de catálogo (ánimo/autoexamen/energía/piel y cabello):
  /// mismo estilo de fondo/borde que usa la app en otros chips
  /// seleccionables, con el color de acento del tema activo. Al
  /// seleccionarse se rellena en el color de acento (antes solo un tinte
  /// muy claro) con un "anillo" (borde de 2px en un tono más oscuro) para
  /// que el estado activo sea inequívoco a simple vista, como en el
  /// diseño de referencia de v0.
  Widget _catalogChip({required String label, required bool selected, required VoidCallback onTap}) {
    final accent = Color(_theme.primary);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? accent.withOpacity(0.55) : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Chip con icono(s) de gota + etiqueta debajo (Flujo menstrual) — mismo
  /// criterio visual que `_dropletChip` de `day_editor.dart`, con padding
  /// un poco más generoso y anillo (borde 2px) al seleccionarse, en línea
  /// con el resto de chips de esta pantalla.
  Widget _dropletChip({
    required String label,
    required int dropletCount,
    required Color dropletColor,
    required bool selected,
    required Color accent,
    // Nulo deshabilita el toque (ver _isFutureEditedDate) sin tener que
    // duplicar este widget para el caso "solo lectura".
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? accent : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              child: dropletCount == 0
                  ? Icon(Icons.circle_outlined, size: 14, color: selected ? accent : AppColors.textMuted)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        dropletCount,
                        (i) => Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                          child: Icon(Icons.water_drop, size: 14, color: dropletColor),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== "Estilo de vida" (Temperatura/Agua/Sueño/Peso) ====================
  // Porte FIEL al diseño exacto verificado en el preview real de Lovable
  // ("Cycle Compass", pantalla Registrar) — no una interpretación libre.
  // Decisiones de portabilidad documentadas en cada método relevante donde
  // el diseño no era 100% trasladable 1:1 a Flutter (franja horaria
  // arrastrable de Sueño -> `Slider` estilizado, ver `_buildSleepDetail`).

  /// Círculo de ~56px con icono de línea + 2 líneas de texto pequeño gris
  /// debajo (nombre + valor). Estado "sin dato": círculo delgado (borde
  /// 1px) con icono de línea. Estado "con dato guardado hoy": anillo
  /// grueso coloreado (borde 3px) del mismo color semántico del icono.
  /// Sueño además muestra un puntito de color arriba del círculo cuando
  /// "hay que registrar" (sin dato todavía), como en el diseño original.
  Widget _lifestyleCircle({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String valueLabel,
    required VoidCallback onTap,
    bool hasData = false,
    bool showTopDot = false,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardBackground,
                    border: Border.all(
                      color: hasData ? iconColor : AppColors.border,
                      width: hasData ? 3 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                if (showTopDot)
                  Positioned(
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Color(_theme.primary)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            valueLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ---------------- Temperatura ----------------

  /// Al tocar el círculo "Temperatura" se abre directamente el modal de
  /// registro (no hay pantalla de detalle con gráfica para Temperatura en
  /// el diseño de Lovable — a diferencia de Peso, que sí navega a una
  /// pantalla completa con evolución + registros anteriores).
  Future<void> _openTemperatureFlow() async {
    await _showTempEntryModal();
  }

  /// Modal centrado con overlay oscuro, fiel al diseño de Lovable: X
  /// circular para cerrar, número gigante rosa con icono de teclado al
  /// lado (alterna entre stepper +/- táctil y campo de texto para
  /// escribir el valor a mano), unidad "°C" debajo, texto de referencia de
  /// rango habitual, filas Fecha/Hora tocables (abren los selectores
  /// nativos) y botón "Guardar" ancho en pill. Devuelve `true` si se
  /// guardó. Se usa `showDialog` en vez de `showModalBottomSheet` porque el
  /// diseño es una tarjeta centrada (no una hoja que sube desde abajo).
  Future<bool?> _showTempEntryModal() {
    final s = AppStrings.of(context);
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => _CenteredNumericEntryDialog(
        title: s.lifestyleTemperature,
        unitSuffix: '°C',
        initialValue: _temp ?? 36.5,
        minValue: 30.0,
        maxValue: 42.0,
        decimals: 1,
        step: 0.1,
        accent: const Color(0xFFE64980),
        referenceText: s.lifestyleTempUsualRange('35.5', '37.5'),
        rangeWarningMin: 35.5,
        rangeWarningMax: 37.5,
        rangeWarningText: s.lifestyleTempOutOfRange,
        saveLabel: s.lifestyleSaveButton,
        dateLabel: s.lifestyleDateLabel,
        timeLabel: s.lifestyleTimeLabel,
        keyboardHint: s.lifestyleSwitchToKeyboard,
        onSave: (value) {
          setState(() => _temp = value);
          _persistLifestyle();
        },
      ),
    );
  }

  // ---------------- Bebe agua ----------------

  String _waterValueLabel(AppStrings s) {
    final glasses = _water ?? 0;
    if (_water == null) return s.lifestyleNoData;
    if (_waterUnitIsDrops) {
      final drops = (glasses * _dropsPerGlass).round();
      final goalDrops = (_waterGoalGlasses * _dropsPerGlass).round();
      return s.lifestyleWaterGoalOf(drops, goalDrops, s.lifestyleWaterUnitDrops);
    }
    return s.lifestyleWaterGoalOf(glasses, _waterGoalGlasses, s.lifestyleWaterUnitGlasses);
  }

  void _incrementWater() {
    setState(() {
      _water = (_water ?? 0) + 1;
    });
    _persistLifestyle();
  }

  void _decrementWater() {
    setState(() {
      _water = ((_water ?? 0) - 1).clamp(0, 999);
    });
    _persistLifestyle();
  }

  /// Panel compacto (no modal ni pantalla completa) que se despliega
  /// in-place debajo de los 4 círculos al tocar "Bebe agua", fiel al
  /// diseño original de Lovable: fondo rosa claro + tarjeta interna blanca,
  /// fila "Vasos de hoy" + botón "+ Añadir" azul, fila de iconos de vaso
  /// (uno por unidad registrada, iconos de vaso real), barra de progreso
  /// verde y texto "X de 8 vasos". Sin toggle de unidad (solo vasos).
  Widget _buildWaterPanel(AppStrings s) {
    const waterBlue = Color(0xFF339AF0);
    const progressGreen = Color(0xFF2F9E44);
    final glasses = _water ?? 0;
    final progress = _waterGoalGlasses == 0 ? 0.0 : (glasses / _waterGoalGlasses).clamp(0.0, 1.0);
    final reachedGoal = glasses >= _waterGoalGlasses;

    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Expanded(
                child: Text(s.lifestyleWaterGlassesToday,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              if (glasses > 0) ...[
                InkWell(
                  onTap: _decrementWater,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: waterBlue),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.remove, size: 16, color: waterBlue),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: _incrementWater,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: waterBlue, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 15, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(s.lifestyleAddButton,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (glasses > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                glasses,
                (i) => GestureDetector(
                  onTap: _decrementWater,
                  child: const Icon(Icons.local_drink, size: 22, color: waterBlue),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(progressGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.lifestyleWaterGoalOf(glasses, _waterGoalGlasses, s.lifestyleWaterUnitGlasses),
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          if (reachedGoal) ...[
            const SizedBox(height: 6),
            Text(s.lifestyleWaterDone,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: progressGreen)),
          ],
        ],
      ),
    );
  }

  Widget _waterPillSegment(String label, bool selected, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF888780),
          ),
        ),
      ),
    );
  }

  Widget _waterRoundButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF0EEE9) : background,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: onTap == null ? const Color(0xFFC9C6BE) : iconColor),
      ),
    );
  }

  /// Toggle pastilla de 2 opciones con icono: "Vasos" (vaso) / "Gotas"
  /// (gota), la opción activa con fondo azul sólido — mismo patrón visual
  /// que el resto de toggles pastilla de la app, pero con icono además de
  /// texto, tal como en el diseño de Lovable.
  Widget _waterUnitToggle() {
    const waterBlue = Color(0xFF339AF0);
    Widget segment(IconData icon, String label, bool selected, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected ? waterBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          segment(Icons.local_bar, s.lifestyleWaterUnitGlasses, !_waterUnitIsDrops,
              () => setState(() => _waterUnitIsDrops = false)),
          segment(Icons.water_drop, s.lifestyleWaterUnitDrops, _waterUnitIsDrops,
              () => setState(() => _waterUnitIsDrops = true)),
        ],
      ),
    );
  }

  /// Toggle de 2 segmentos reutilizado por Peso (kg/lb) en su modal de
  /// registro rápido: mismo patrón visual que `_waterUnitToggle` pero sin
  /// iconos.
  Widget _unitToggle({
    required String leftLabel,
    required String rightLabel,
    required bool leftSelected,
    required VoidCallback onSelectLeft,
    required VoidCallback onSelectRight,
    required Color accent,
  }) {
    Widget segment(String label, bool selected, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          segment(leftLabel, leftSelected, onSelectLeft),
          segment(rightLabel, !leftSelected, onSelectRight),
        ],
      ),
    );
  }

  // ---------------- Sueño ----------------
  //
  // Porte fiel al diseño de Lovable: 2 pantallas completas de fondo azul
  // muy oscuro/negro (modo noche), no un panel ni un modal. Pantalla 1
  // (`_SleepSummaryScreen`): anillo grande con luna + "Xh Ym" + objetivo,
  // tarjeta "Registro de sueño" que navega a la pantalla 2
  // (`_SleepEditScreen`): duración calculada + secciones AYER (Me dormí) /
  // HOY (Me desperté), cada una con una franja horizontal de horas.
  //
  // Decisión de portabilidad: el diseño original usa una franja horaria
  // ARRASTRABLE (gesto de "drag" libre sobre una regla de horas dibujada a
  // mano). Portar ese gesto custom 1:1 es bastante más superficie de bugs
  // que un resultado funcionalmente idéntico logrado con un `Slider` de
  // Material estilizado para parecer la franja (mismo fondo oscuro,
  // mismas marcas de hora como `divisions`, mismo color ámbar del thumb/
  // track activo) — se conserva el aspecto visual y la interacción básica
  // (arrastrar para cambiar la hora), simplificando el gesto de "drag
  // libre sobre dibujo custom" a un `Slider` real, tal como autorizan las
  // instrucciones de la tarea cuando el arrastre fino es muy costoso de
  // portar en el tiempo disponible.

  String _sleepValueLabel(AppStrings s) {
    if (_sleep == null) return s.lifestyleNoData;
    final totalMinutes = (_sleep! * 60).round();
    return s.lifestyleSleepDuration(totalMinutes ~/ 60, totalMinutes % 60);
  }

  /// Convierte 'HH:mm' a minutos desde medianoche; null si el string es
  /// null o no tiene el formato esperado.
  int? _minutesFromHHmm(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Recalcula `_sleep` (horas) restando "Me dormí" (ayer) de "Me
  /// desperté" (hoy), cruzando medianoche correctamente: si la hora de
  /// despertar cae "antes" que la de dormir en el reloj de 24h, se suma un
  /// día completo (1440 minutos) antes de restar.
  void _recomputeSleepDuration() {
    final bed = _minutesFromHHmm(_sleepBedtime);
    final wake = _minutesFromHHmm(_sleepWakeTime);
    if (bed == null || wake == null) return;
    var diff = wake - bed;
    if (diff <= 0) diff += 24 * 60;
    _sleep = diff / 60.0;
  }

  Future<void> _openSleepFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SleepSummaryScreen(
          theme: _theme,
          sleepHours: _sleep,
          bedtime: _sleepBedtime,
          wakeTime: _sleepWakeTime,
          onOpenEdit: _openSleepEditScreen,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openSleepEditScreen(BuildContext ctx) async {
    await Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => _SleepEditScreen(
          theme: _theme,
          initialBedtime: _sleepBedtime ?? '23:00',
          initialWakeTime: _sleepWakeTime ?? '07:00',
          onDone: (bedtime, wakeTime) {
            setState(() {
              _sleepBedtime = bedtime;
              _sleepWakeTime = wakeTime;
              _recomputeSleepDuration();
            });
            _persistLifestyle();
          },
        ),
      ),
    );
  }

  // ---------------- Peso ----------------
  //
  // Porte fiel al diseño de Lovable: pantalla completa fondo rosa muy
  // claro (no oscuro, a diferencia de Sueño). Tarjeta "Evolución" con
  // mini-gráfica, botón ancho "+ Añadir" en CORAL (único acento distinto
  // del rosa de marca en todo Lovable — decisión de diseño consistente
  // que se mantiene tal cual, no se reemplaza por `_theme.primary`),
  // tarjeta "Registros anteriores", tarjeta "Tus datos" (formulario 2x2
  // persistido) y 3 tarjetas de calculadoras (IMC/ICA/grasa corporal).

  static const Color _weightCoral = Color(0xFFFF6F59);

  Future<void> _openWeightFlow() async {
    // Si hoy todavía no hay un peso registrado, se pide primero con el
    // modal rápido (número gigante + Fecha/Hora estilo iOS) — igual que
    // Temperatura. Solo una vez que ya existe un dato para hoy, tocar el
    // círculo "Peso" lleva directo a la pantalla completa con historial y
    // calculadoras, sin volver a interrumpir con el modal de captura.
    if (_weight == null) {
      final saved = await _showWeightEntryModal();
      if (saved != true) return;
      if (mounted) setState(() {});
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WeightFullScreen(
          theme: _theme,
          dataProvider: () => widget.data,
          todayKey: _todayKey,
          settingsService: _settingsService,
          onAddWeight: _showWeightEntryModal,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Modal centrado (mismo widget que Temperatura, `_CenteredNumericEntryDialog`)
  /// para registrar un nuevo peso: número gigante + icono de teclado,
  /// unidad kg, filas Fecha/Hora, botón Guardar. Devuelve `true` si se
  /// guardó. Acento coral, coherente con el botón "+ Añadir" de esta
  /// sección.
  Future<bool?> _showWeightEntryModal() {
    final s = AppStrings.of(context);
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => _CenteredNumericEntryDialog(
        title: s.lifestyleWeight,
        unitSuffix: s.lifestyleWeightUnitKg,
        initialValue: _weight ?? 65.0,
        minValue: 20,
        maxValue: 300,
        decimals: 1,
        step: 0.1,
        accent: _weightCoral,
        saveLabel: s.lifestyleSaveButton,
        dateLabel: s.lifestyleDateLabel,
        timeLabel: s.lifestyleTimeLabel,
        keyboardHint: s.lifestyleSwitchToKeyboard,
        onSave: (value) {
          setState(() => _weight = value);
          _persistLifestyle();
        },
      ),
    );
  }
}

class _SymptomLevelColor {
  final Color background;
  final Color border;
  final Color text;
  const _SymptomLevelColor({required this.background, required this.border, required this.text});
}

/// Modal centrado con overlay oscuro, fiel al diseño exacto de Lovable
/// (reemplaza el `_IosStyleEntrySheet` de la ronda anterior, que era una
/// hoja modal desde abajo): tarjeta blanca con esquinas redondeadas, header
/// (título + X circular gris claro para cerrar), número gigante coloreado
/// centrado con icono de teclado al lado (alterna entre stepper táctil y
/// campo de texto), unidad debajo, texto de referencia opcional
/// (Temperatura), filas Fecha/Hora tocables (abren selectores nativos) y
/// botón "Guardar" ancho en pill. Reutilizado por Temperatura y por el "+
/// Añadir" de Peso, con el color de acento inyectado desde fuera (rosa
/// para Temperatura, coral para Peso).
class _CenteredNumericEntryDialog extends StatefulWidget {
  final String title;
  final String unitSuffix;
  final double initialValue;
  final double minValue;
  final double maxValue;
  final int decimals;
  final double step;
  final Color accent;
  final String? referenceText;
  final double? rangeWarningMin;
  final double? rangeWarningMax;
  final String? rangeWarningText;
  final String saveLabel;
  final String dateLabel;
  final String timeLabel;
  final String keyboardHint;
  final ValueChanged<double> onSave;

  const _CenteredNumericEntryDialog({
    required this.title,
    required this.unitSuffix,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.decimals,
    required this.step,
    required this.accent,
    this.referenceText,
    this.rangeWarningMin,
    this.rangeWarningMax,
    this.rangeWarningText,
    required this.saveLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.keyboardHint,
    required this.onSave,
  });

  @override
  State<_CenteredNumericEntryDialog> createState() => _CenteredNumericEntryDialogState();
}

class _CenteredNumericEntryDialogState extends State<_CenteredNumericEntryDialog> {
  late double _value;
  late TextEditingController _controller;
  late DateTime _date;
  late TimeOfDay _time;
  bool _keyboardMode = false; // false = stepper táctil, true = campo de texto

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(text: _formatValue(_value));
    _date = DateTime.now();
    _time = TimeOfDay.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double v) => v.toStringAsFixed(widget.decimals);

  void _applyStep(double delta) {
    setState(() {
      _value = (_value + delta).clamp(widget.minValue, widget.maxValue);
      _controller.text = _formatValue(_value);
    });
  }

  Future<void> _pickDate() async {
    final picked = await ReminderDatePickerSheet.show(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      primary: widget.accent,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await ReminderTimePickerSheet.show(
      context: context,
      initialTime: _time,
      primary: widget.accent,
    );
    if (picked != null) setState(() => _time = picked);
  }

  bool get _outOfRange {
    if (widget.rangeWarningMin == null || widget.rangeWarningMax == null) return false;
    return _value < widget.rangeWarningMin! || _value > widget.rangeWarningMax!;
  }

  void _save() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    final finalValue = (parsed ?? _value).clamp(widget.minValue, widget.maxValue);
    widget.onSave(finalValue);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Header: título a la izquierda, X circular gris claro a
            // la derecha para cerrar. ----
            Row(
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F1F4)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ---- Número gigante centrado + icono de teclado al lado
            // (alterna entre stepper táctil y campo de texto libre). ----
            if (_keyboardMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: widget.accent),
                      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                      onChanged: (v) {
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        if (parsed != null) _value = parsed;
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() => _keyboardMode = false),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Icon(Icons.keyboard_alt_outlined, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _stepButton(icon: Icons.remove, onTap: () => _applyStep(-widget.step)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _keyboardMode = true),
                      child: Column(
                        children: [
                          Text(
                            _formatValue(_value),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: widget.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _stepButton(icon: Icons.add, onTap: () => _applyStep(widget.step)),
                ],
              ),
            const SizedBox(height: 4),
            Center(
              child: Text(widget.unitSuffix,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
            if (widget.referenceText != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.referenceText!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
            if (_outOfRange && widget.rangeWarningText != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.rangeWarningText!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFFE8590C)),
              ),
            ],
            const SizedBox(height: 18),
            _entryRow(
              icon: Icons.calendar_today_outlined,
              label: widget.dateLabel,
              value: dateFmt.format(_date),
              onTap: _pickDate,
            ),
            const SizedBox(height: 1),
            _entryRow(
              icon: Icons.access_time,
              label: widget.timeLabel,
              value: _time.format(context),
              onTap: _pickTime,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: Text(widget.saveLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accent.withOpacity(0.12)),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: widget.accent),
      ),
    );
  }

  Widget _entryRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(width: 6),
            Icon(icon, size: 17, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Gráfica de evolución simple (línea + puntos) para una serie de
/// fecha->valor, dibujada con `CustomPainter` — mismo enfoque que
/// `lib/widgets/temp_chart.dart` (sin depender de un paquete de gráficas
/// externo), pero genérica para cualquier métrica (temperatura o peso) en
/// vez de estar acoplada al `Map<String, DayEntry>` completo con barras de
/// periodo.
class _EvolutionChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> series;
  final Color lineColor;

  _EvolutionChartPainter({required this.series, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 28.0;
    final width = size.width;
    final height = size.height;

    final values = series.map((e) => e.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    final adjMin = minV - range * 0.15;
    final adjMax = maxV + range * 0.15;
    final adjRange = (adjMax - adjMin) == 0 ? 1.0 : (adjMax - adjMin);

    final basePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(Offset(padding, height - padding), Offset(width - padding, height - padding), basePaint);

    final stepX = series.length > 1 ? (width - padding * 2) / (series.length - 1) : 0.0;
    final points = <Offset>[];
    for (var i = 0; i < series.length; i++) {
      final x = padding + i * stepX;
      final y = height - padding - ((series[i].value - adjMin) / adjRange) * (height - padding * 2 - 16) - 16;
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final circlePaint = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.5, circlePaint);
      final tp = TextPainter(
        text: TextSpan(
          text: values[i].toStringAsFixed(1),
          style: TextStyle(fontSize: 9, color: lineColor, fontWeight: FontWeight.w600),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, points[i].dy - tp.height - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _EvolutionChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.lineColor != lineColor;
  }
}

// ==================== Sueño: pantallas completas ====================

/// Pantalla 1 de Sueño: fondo full-bleed azul muy oscuro/negro (modo
/// noche), fiel al diseño de Lovable. Header "Sueño" + X blanca. Anillo
/// circular grande (~170px) con borde delgado gris oscuro: dentro, icono
/// de luna creciente ámbar (con puntito ámbar encima), texto grande blanco
/// "Xh Ym" y debajo "Objetivo: 8 Horas" en gris. Debajo del anillo, tarjeta
/// oscura tocable "Registro de sueño" (icono de cama circular ámbar +
/// flecha ">") que navega a `_SleepEditScreen`.
class _SleepSummaryScreen extends StatelessWidget {
  final AppThemeOption theme;
  final double? sleepHours;
  final String? bedtime;
  final String? wakeTime;
  final Future<void> Function(BuildContext) onOpenEdit;

  const _SleepSummaryScreen({
    required this.theme,
    required this.sleepHours,
    required this.bedtime,
    required this.wakeTime,
    required this.onOpenEdit,
  });

  static const _nightBg = Color(0xFF0B0E1A);
  static const _amber = Color(0xFFF5B93D);
  static const _cardBg = Color(0xFF1B2033);

  String _durationLabel(AppStrings s) {
    if (sleepHours == null) return '0h 0m';
    final totalMinutes = (sleepHours! * 60).round();
    return s.lifestyleSleepDuration(totalMinutes ~/ 60, totalMinutes % 60);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: _nightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.lifestyleSleep,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF262B3D)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 17, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Center(
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2A3048), width: 3),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.nightlight_round, color: _amber, size: 30),
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: _amber),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(_durationLabel(s),
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${s.lifestyleSleepGoalLabel}: ${s.lifestyleSleepGoalHours(8)}',
                              style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              InkWell(
                onTap: () => onOpenEdit(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: _amber),
                        alignment: Alignment.center,
                        child: const Icon(Icons.bed, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s.lifestyleSleepLogEntry,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla 2 de Sueño: edición de "Me dormí" (AYER) / "Me desperté" (HOY),
/// cada una con una franja horizontal de horas (portada como `Slider`
/// estilizado — ver nota de portabilidad en `_HourSlider`). Duración
/// calculada arriba, botón "Listo" al final.
class _SleepEditScreen extends StatefulWidget {
  final AppThemeOption theme;
  final String initialBedtime; // 'HH:mm'
  final String initialWakeTime; // 'HH:mm'
  final void Function(String bedtime, String wakeTime) onDone;

  const _SleepEditScreen({
    required this.theme,
    required this.initialBedtime,
    required this.initialWakeTime,
    required this.onDone,
  });

  @override
  State<_SleepEditScreen> createState() => _SleepEditScreenState();
}

class _SleepEditScreenState extends State<_SleepEditScreen> {
  static const _nightBg = Color(0xFF0B0E1A);
  static const _amber = Color(0xFFF5B93D);

  late int _bedtimeMinutes; // minutos desde medianoche, 0-1439
  late int _wakeMinutes;

  @override
  void initState() {
    super.initState();
    _bedtimeMinutes = _parse(widget.initialBedtime);
    _wakeMinutes = _parse(widget.initialWakeTime);
  }

  int _parse(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 23;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return h * 60 + m;
  }

  String _format(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _durationLabel(AppStrings s) {
    var diff = _wakeMinutes - _bedtimeMinutes;
    if (diff <= 0) diff += 24 * 60;
    return s.lifestyleSleepDuration(diff ~/ 60, diff % 60);
  }

  void _done() {
    widget.onDone(_format(_bedtimeMinutes), _format(_wakeMinutes));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: _nightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.lifestyleSleep,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF262B3D)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 17, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(_durationLabel(s),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(s.lifestyleSleepDurationLabel,
                        style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: [
                    _sleepSection(
                      label: s.lifestyleSleepYesterday,
                      rowLabel: s.lifestyleSleepFellAsleep,
                      minutes: _bedtimeMinutes,
                      onChanged: (v) => setState(() => _bedtimeMinutes = v),
                    ),
                    const SizedBox(height: 28),
                    _sleepSection(
                      label: s.lifestyleSleepToday,
                      rowLabel: s.lifestyleSleepWokeUp,
                      minutes: _wakeMinutes,
                      onChanged: (v) => setState(() => _wakeMinutes = v),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _done,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(widget.theme.primary),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: Text(s.lifestyleSleepDone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sleepSection({
    required String label,
    required String rowLabel,
    required int minutes,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: Text(rowLabel, style: const TextStyle(fontSize: 14.5, color: Colors.white))),
            Text(_format(minutes), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _amber)),
          ],
        ),
        const SizedBox(height: 10),
        _HourSlider(minutes: minutes, onChanged: onChanged),
      ],
    );
  }
}

/// Franja horizontal tipo "regla de tiempo" fiel al diseño de Lovable:
/// fondo oscuro, marcas verticales cada hora (más altas y claras en las
/// horas "en punto", cortas y tenues en los intermedios), franja central
/// ligeramente resaltada (la ventana de 3h visible alrededor del valor
/// actual) y una línea vertical ámbar fina — sin thumb circular — que
/// marca la hora/minuto exactos. Se arrastra horizontalmente (pan) sobre
/// toda la franja; cada desplazamiento horizontal mueve el valor en
/// minutos de forma proporcional al ancho visible (3 horas ~ ancho total).
class _HourSlider extends StatefulWidget {
  final int minutes; // 0-1439
  final ValueChanged<int> onChanged;

  const _HourSlider({required this.minutes, required this.onChanged});

  @override
  State<_HourSlider> createState() => _HourSliderState();
}

class _HourSliderState extends State<_HourSlider> {
  static const _amber = Color(0xFFF5B93D);
  static const _windowMinutes = 180; // ventana visible: 3 horas, como en Lovable

  double? _dragStartDx;
  int? _dragStartMinutes;

  void _onPanStart(DragStartDetails details, double width) {
    _dragStartDx = details.localPosition.dx;
    _dragStartMinutes = widget.minutes;
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    if (_dragStartDx == null || _dragStartMinutes == null) return;
    final deltaDx = details.localPosition.dx - _dragStartDx!;
    final minutesPerPixel = _windowMinutes / width;
    var next = _dragStartMinutes! - (deltaDx * minutesPerPixel).round();
    next = next.clamp(0, 24 * 60 - 1);
    if (next != widget.minutes) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF161A2C), borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _onPanStart(d, width),
            onPanUpdate: (d) => _onPanUpdate(d, width),
            child: ClipRect(
              child: CustomPaint(
                size: Size(width, 68),
                painter: _HourRulerPainter(
                  minutes: widget.minutes,
                  windowMinutes: _windowMinutes,
                  amber: _amber,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HourRulerPainter extends CustomPainter {
  final int minutes;
  final int windowMinutes;
  final Color amber;

  _HourRulerPainter({required this.minutes, required this.windowMinutes, required this.amber});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final pxPerMinute = size.width / windowMinutes;
    final centerLineY = size.height * 0.42;

    // Franja central resaltada (ventana de ~1h alrededor del valor actual).
    final highlightPaint = Paint()..color = const Color(0xFF1E2338);
    final highlightWidth = pxPerMinute * 60;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, size.height / 2), width: highlightWidth, height: size.height),
      highlightPaint,
    );

    // Marcas verticales: una cada 30 minutos, dentro del rango visible +
    // margen para que no aparezcan huecos en los bordes al arrastrar.
    final firstVisibleMinute = minutes - (windowMinutes ~/ 2) - 60;
    final lastVisibleMinute = minutes + (windowMinutes ~/ 2) + 60;
    final firstTick = (firstVisibleMinute / 30).floor() * 30;
    for (var m = firstTick; m <= lastVisibleMinute; m += 30) {
      final dx = centerX + (m - minutes) * pxPerMinute;
      if (dx < -20 || dx > size.width + 20) continue;
      final isHour = m % 60 == 0;
      final tickPaint = Paint()
        ..color = isHour ? Colors.white38 : Colors.white24
        ..strokeWidth = 1.4;
      final tickHeight = isHour ? 16.0 : 9.0;
      canvas.drawLine(
        Offset(dx, centerLineY - tickHeight / 2),
        Offset(dx, centerLineY + tickHeight / 2),
        tickPaint,
      );
      if (isHour) {
        final normalizedHour = ((m ~/ 60) % 24 + 24) % 24;
        final textPainter = TextPainter(
          text: TextSpan(
            text: normalizedHour.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 10.5, color: Colors.white38),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(dx - textPainter.width / 2, size.height - textPainter.height - 4));
      }
    }

    // Línea vertical ámbar fina marcando el valor exacto seleccionado.
    final amberPaint = Paint()
      ..color = amber
      ..strokeWidth = 2.2;
    canvas.drawLine(
      Offset(centerX, 4),
      Offset(centerX, size.height - 20),
      amberPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HourRulerPainter oldDelegate) =>
      oldDelegate.minutes != minutes || oldDelegate.windowMinutes != windowMinutes;
}

// ==================== Peso: pantalla completa ====================

/// Pantalla completa de Peso: fondo rosa muy claro (a diferencia de
/// Sueño, que es oscura). Tarjeta "Evolución" con mini-gráfica, botón
/// ancho "+ Añadir" coral, tarjeta "Registros anteriores", tarjeta "Tus
/// datos" (formulario 2x2 persistido) y 3 tarjetas de calculadoras.
class _WeightFullScreen extends StatefulWidget {
  final AppThemeOption theme;
  final Map<String, DayEntry> Function() dataProvider;
  final String todayKey;
  final SettingsService settingsService;
  final Future<bool?> Function() onAddWeight;

  const _WeightFullScreen({
    required this.theme,
    required this.dataProvider,
    required this.todayKey,
    required this.settingsService,
    required this.onAddWeight,
  });

  @override
  State<_WeightFullScreen> createState() => _WeightFullScreenState();
}

class _WeightFullScreenState extends State<_WeightFullScreen> {
  static const _coral = Color(0xFFFF6F59);

  double? _heightCm;
  double? _waistCm;
  int? _age;
  bool _isMale = false; // por defecto Mujer
  bool _loaded = false;

  late final TextEditingController _heightController;
  late final TextEditingController _waistController;
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _waistController = TextEditingController();
    _ageController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _waistController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final height = await widget.settingsService.loadHeightCm();
    final waist = await widget.settingsService.loadWaistCm();
    final birth = await widget.settingsService.loadProfileBirthDate();
    final sex = await widget.settingsService.loadBiologicalSex();
    if (!mounted) return;
    setState(() {
      _heightCm = height;
      _waistCm = waist;
      _age = _ageFromBirthDate(birth);
      _isMale = sex == 'male';
      _heightController.text = height != null ? height.toStringAsFixed(0) : '';
      _waistController.text = waist != null ? waist.toStringAsFixed(0) : '';
      _ageController.text = _age != null ? _age.toString() : '';
      _loaded = true;
    });
  }

  int? _ageFromBirthDate(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  List<MapEntry<String, double>> _series() {
    final data = widget.dataProvider();
    final entries = <MapEntry<String, double>>[];
    final keys = data.keys.toList()..sort();
    for (final k in keys) {
      final v = data[k]?.weight;
      if (v != null) entries.add(MapEntry(k, v));
    }
    if (entries.length > 14) return entries.sublist(entries.length - 14);
    return entries;
  }

  double? get _latestWeight {
    final series = _series();
    if (series.isEmpty) return null;
    return series.last.value;
  }

  Future<void> _handleAdd() async {
    final saved = await widget.onAddWeight();
    if (saved == true && mounted) setState(() {});
  }

  void _saveHeight(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    setState(() => _heightCm = parsed);
    widget.settingsService.saveHeightCm(parsed);
  }

  void _saveWaist(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    setState(() => _waistCm = parsed);
    widget.settingsService.saveWaistCm(parsed);
  }

  void _saveAge(String value) {
    final parsed = int.tryParse(value);
    setState(() => _age = parsed);
    if (parsed != null) {
      // Se guarda como fecha de nacimiento aproximada (1 de enero de ese
      // año) para reutilizar `loadProfileBirthDate`/`saveProfileBirthDate`
      // ya existentes en vez de crear un campo de "edad" independiente que
      // se desincronizaría con el resto del perfil.
      final approxBirthYear = DateTime.now().year - parsed;
      widget.settingsService.saveProfileBirthDate(DateTime(approxBirthYear, 1, 1));
    }
  }

  void _saveSex(bool isMale) {
    setState(() => _isMale = isMale);
    widget.settingsService.saveBiologicalSex(isMale ? 'male' : 'female');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (!_loaded) {
      return Scaffold(backgroundColor: AppColors.background, body: const SizedBox.shrink());
    }
    final series = _series();
    final weight = _latestWeight;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.lifestyleWeight,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1E3E8)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 17, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  children: [
                    // ---- Tarjeta "Evolución" ----
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: _coral.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.lifestyleWeightEvolutionTitle,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          series.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    s.lifestyleWeightChartEmpty,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                )
                              : SizedBox(
                                  height: 180,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: _EvolutionChartPainter(series: series, lineColor: const Color(0xFFE64980)),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ---- Botón "+ Añadir" coral ----
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleAdd,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(s.lifestyleAddButton,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ---- Fila clicable "Registros anteriores" (abre bottom sheet) ----
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showPreviousRecordsSheet(context, s, series),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(s.lifestylePreviousRecords,
                                  style: const TextStyle(
                                      fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            ),
                            const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ---- Tarjeta "Tus datos" ----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.lifestyleYourDataTitle,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: _dataField(s.lifestyleHeightFieldLabel, _heightController, _saveHeight)),
                              const SizedBox(width: 10),
                              Expanded(child: _dataField(s.lifestyleWaistFieldLabel, _waistController, _saveWaist)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                  child: _dataField(s.lifestyleAgeFieldLabel, _ageController, _saveAge,
                                      isInt: true)),
                              const SizedBox(width: 10),
                              Expanded(child: _sexDropdown(s)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _calculatorCard(
                      title: s.lifestyleBmiCardFullTitle,
                      subtitle: s.lifestyleBmiFormulaSubtitle,
                      compute: () {
                        if (weight == null || _heightCm == null || _heightCm! <= 0) return null;
                        final heightM = _heightCm! / 100;
                        final bmi = weight / (heightM * heightM);
                        String category;
                        if (bmi < 18.5) {
                          category = s.lifestyleBmiCategoryUnderweight;
                        } else if (bmi < 25) {
                          category = s.lifestyleBmiCategoryNormal;
                        } else if (bmi < 30) {
                          category = s.lifestyleBmiCategoryOverweight;
                        } else {
                          category = s.lifestyleBmiCategoryObesity;
                        }
                        return _CalcResult(bmi.toStringAsFixed(1), category);
                      },
                    ),
                    const SizedBox(height: 12),
                    _calculatorCard(
                      title: s.lifestyleWhrCardTitle,
                      subtitle: s.lifestyleWhrFormulaSubtitle,
                      compute: () {
                        if (_waistCm == null || _waistCm! <= 0 || _heightCm == null || _heightCm! <= 0) return null;
                        final whr = _waistCm! / _heightCm!;
                        final category = whr < 0.5 ? s.lifestyleWhrCategoryLow : s.lifestyleWhrCategoryHigh;
                        return _CalcResult(whr.toStringAsFixed(2), category);
                      },
                    ),
                    const SizedBox(height: 12),
                    _calculatorCard(
                      title: s.lifestyleBodyFatCardTitle,
                      subtitle: s.lifestyleBodyFatFormulaSubtitle,
                      compute: () {
                        if (weight == null || _heightCm == null || _heightCm! <= 0 || _age == null) return null;
                        final heightM = _heightCm! / 100;
                        final bmi = weight / (heightM * heightM);
                        // Fórmula de Deurenberg: 1.20×IMC + 0.23×edad −
                        // 10.8×sexo − 5.4 (sexo = 1 hombre / 0 mujer).
                        final sexFactor = _isMale ? 1 : 0;
                        final bodyFat = 1.20 * bmi + 0.23 * _age! - 10.8 * sexFactor - 5.4;
                        return _CalcResult('${bodyFat.toStringAsFixed(1)}%', null);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreviousRecordsSheet(
      BuildContext context, AppStrings s, List<MapEntry<String, double>> series) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(s.lifestylePreviousRecords,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1E3E8)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close, size: 17, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: series.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(s.lifestyleNoPreviousRecords,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: series.reversed.map((e) => _historyRow(e.key, e.value)).toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _historyRow(String key, double value) {
    final parts = key.split('-');
    String label = key;
    if (parts.length == 3) {
      label = '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
          Text('${value.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFFE64980))),
        ],
      ),
    );
  }

  Widget _dataField(String label, TextEditingController controller, ValueChanged<String> onSubmit,
      {bool isInt = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          onChanged: onSubmit,
          onSubmitted: onSubmit,
          onEditingComplete: () => onSubmit(controller.text),
        ),
      ],
    );
  }

  Widget _sexDropdown(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.lifestyleSexFieldLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              value: _isMale,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
              items: [
                DropdownMenuItem(value: false, child: Text(s.lifestyleSexFemale)),
                DropdownMenuItem(value: true, child: Text(s.lifestyleSexMale)),
              ],
              onChanged: (value) {
                if (value != null) _saveSex(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Tarjeta de calculadora: título en negrita, subtítulo gris con la
  /// fórmula, resultado en número grande rosa/magenta (o placeholder si
  /// faltan datos), interpretación en gris debajo, y botón pill "Calcular"
  /// que fuerza un `setState` para recalcular con los valores actuales.
  Widget _calculatorCard({
    required String title,
    required String subtitle,
    required _CalcResult? Function() compute,
  }) {
    final result = compute();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          result == null
              ? Text(AppStrings.of(context).lifestylePlaceholderMissingData,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.value,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFE64980))),
                    if (result.interpretation != null) ...[
                      const SizedBox(height: 2),
                      Text(result.interpretation!,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}

/// Resultado simple de una calculadora: valor formateado + interpretación
/// opcional (la de % de grasa corporal no tiene categoría en el diseño).
class _CalcResult {
  final String value;
  final String? interpretation;
  const _CalcResult(this.value, this.interpretation);
}
