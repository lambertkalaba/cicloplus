/// Representa el registro de un solo día: flujo menstrual, síntomas,
/// diario personal, actividad sexual y datos opcionales de bienestar
/// (temperatura, agua, sueño, peso, foto).
class DayEntry {
  final String flow; // 'none' | 'light' | 'medium' | 'heavy'
  final List<String> symptoms;
  final Map<String, String> symptomLevels; // id síntoma -> 'leve'|'moderado'|'fuerte'
  final String note; // texto libre tipo diario
  final bool sex; // hubo relación sexual
  final bool unprotected; // relación sexual sin protección
  final double? temp; // temperatura basal en °C
  final int? water; // vasos de agua
  final double? sleep; // horas de sueño
  final String? sleepBedtime; // hora de dormir "Ayer", formato 'HH:mm'
  final String? sleepWakeTime; // hora de despertar "Hoy", formato 'HH:mm'
  final double? weight; // peso en kg
  final String? photo; // foto adjunta en base64 (data URL)
  final String? cervicalMucus; // 'dry' | 'sticky' | 'creamy' | 'eggwhite' | 'watery'
  final String? spotting; // 'brown' | 'pink' | 'red' (manchado fuera del flujo principal)

  // ---- Campos ampliados para la pestaña "Registrar" (rediseño de 5
  // pestañas inspirado en apps de referencia tipo Flo) ----
  final List<String> medication; // ids de kMedicationCatalog, medicamentos tomados ese día
  final String? breastSelfExam; // id de kBreastSelfExamCatalog (autoexamen de mamas)
  final List<String> mood; // ids de kMoodCatalog (ánimo, puede ser múltiple)
  final String? energy; // id de kEnergyOptions
  final List<String> skinHair; // ids de kSkinHairCatalog
  final int? sexTimes; // "Veces" de vida sexual ese día (solo informativo)
  final bool sexDesire; // "Deseo sexual" registrado sin actividad sexual en sí
  final bool sexMasturbation; // masturbación (distinto de sexo en pareja)
  final bool sexNoOrgasm; // "Sin orgasmo"
  final bool sexOrgasm; // "Orgasmo"
  final bool diu; // DIU colocado/en uso ese día (método anticonceptivo), independiente de `medication`
  final bool sexNone; // "No tuve" elegido explícitamente (Veces queda fijo en 0); distinto de "sin datos"

  const DayEntry({
    this.flow = 'none',
    this.symptoms = const [],
    this.symptomLevels = const {},
    this.note = '',
    this.sex = false,
    this.unprotected = false,
    this.temp,
    this.water,
    this.sleep,
    this.sleepBedtime,
    this.sleepWakeTime,
    this.weight,
    this.photo,
    this.cervicalMucus,
    this.spotting,
    this.medication = const [],
    this.breastSelfExam,
    this.mood = const [],
    this.energy,
    this.skinHair = const [],
    this.sexTimes,
    this.sexDesire = false,
    this.sexMasturbation = false,
    this.sexNoOrgasm = false,
    this.sexOrgasm = false,
    this.diu = false,
    this.sexNone = false,
  });

  bool get isPeriodDay => flow != 'none';

  bool get isEmpty =>
      flow == 'none' &&
      symptoms.isEmpty &&
      note.isEmpty &&
      !sex &&
      !unprotected &&
      temp == null &&
      water == null &&
      sleep == null &&
      sleepBedtime == null &&
      sleepWakeTime == null &&
      weight == null &&
      photo == null &&
      cervicalMucus == null &&
      spotting == null &&
      medication.isEmpty &&
      breastSelfExam == null &&
      mood.isEmpty &&
      energy == null &&
      skinHair.isEmpty &&
      sexTimes == null &&
      !sexDesire &&
      !sexMasturbation &&
      !sexNoOrgasm &&
      !sexOrgasm &&
      !diu &&
      !sexNone;

  /// Si el día ya tiene algún dato de la sección "Más detalles" (vida
  /// sexual, temperatura, bienestar o foto), replicando `hasExtra` del
  /// prototipo — se usa para decidir si esa sección debe abrirse sola.
  bool get hasExtraDetails =>
      sex || unprotected || temp != null || water != null || sleep != null || weight != null || photo != null;

  Map<String, dynamic> toJson() => {
        'flow': flow,
        'symptoms': symptoms,
        'symptomLevels': symptomLevels,
        'note': note,
        'sex': sex,
        'unprotected': unprotected,
        'temp': temp,
        'water': water,
        'sleep': sleep,
        'sleepBedtime': sleepBedtime,
        'sleepWakeTime': sleepWakeTime,
        'weight': weight,
        'photo': photo,
        'cervicalMucus': cervicalMucus,
        'spotting': spotting,
        'medication': medication,
        'breastSelfExam': breastSelfExam,
        'mood': mood,
        'energy': energy,
        'skinHair': skinHair,
        'sexTimes': sexTimes,
        'sexDesire': sexDesire,
        'sexMasturbation': sexMasturbation,
        'sexNoOrgasm': sexNoOrgasm,
        'sexOrgasm': sexOrgasm,
        'diu': diu,
        'sexNone': sexNone,
      };

  factory DayEntry.fromJson(Map<String, dynamic> json) => DayEntry(
        flow: json['flow'] as String? ?? 'none',
        symptoms: (json['symptoms'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        symptomLevels: (json['symptomLevels'] as Map<dynamic, dynamic>? ?? {})
            .map((key, value) => MapEntry(key.toString(), value.toString())),
        note: json['note'] as String? ?? '',
        sex: json['sex'] as bool? ?? false,
        unprotected: json['unprotected'] as bool? ?? false,
        temp: (json['temp'] as num?)?.toDouble(),
        water: (json['water'] as num?)?.toInt(),
        sleep: (json['sleep'] as num?)?.toDouble(),
        sleepBedtime: json['sleepBedtime'] as String?,
        sleepWakeTime: json['sleepWakeTime'] as String?,
        weight: (json['weight'] as num?)?.toDouble(),
        photo: json['photo'] as String?,
        cervicalMucus: json['cervicalMucus'] as String?,
        spotting: json['spotting'] as String?,
        medication: (json['medication'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        breastSelfExam: json['breastSelfExam'] as String?,
        mood: (json['mood'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        energy: json['energy'] as String?,
        skinHair: (json['skinHair'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        sexTimes: (json['sexTimes'] as num?)?.toInt(),
        sexDesire: json['sexDesire'] as bool? ?? false,
        sexMasturbation: json['sexMasturbation'] as bool? ?? false,
        sexNoOrgasm: json['sexNoOrgasm'] as bool? ?? false,
        sexOrgasm: json['sexOrgasm'] as bool? ?? false,
        diu: json['diu'] as bool? ?? false,
        sexNone: json['sexNone'] as bool? ?? false,
      );

  DayEntry copyWith({
    String? flow,
    List<String>? symptoms,
    Map<String, String>? symptomLevels,
    String? note,
    bool? sex,
    bool? unprotected,
    double? temp,
    bool clearTemp = false,
    int? water,
    bool clearWater = false,
    double? sleep,
    bool clearSleep = false,
    String? sleepBedtime,
    bool clearSleepBedtime = false,
    String? sleepWakeTime,
    bool clearSleepWakeTime = false,
    double? weight,
    bool clearWeight = false,
    String? photo,
    bool clearPhoto = false,
    String? cervicalMucus,
    bool clearCervicalMucus = false,
    String? spotting,
    bool clearSpotting = false,
    List<String>? medication,
    String? breastSelfExam,
    bool clearBreastSelfExam = false,
    List<String>? mood,
    String? energy,
    bool clearEnergy = false,
    List<String>? skinHair,
    int? sexTimes,
    bool clearSexTimes = false,
    bool? sexDesire,
    bool? sexMasturbation,
    bool? sexNoOrgasm,
    bool? sexOrgasm,
    bool? diu,
    bool? sexNone,
  }) =>
      DayEntry(
        flow: flow ?? this.flow,
        symptoms: symptoms ?? this.symptoms,
        symptomLevels: symptomLevels ?? this.symptomLevels,
        note: note ?? this.note,
        sex: sex ?? this.sex,
        unprotected: unprotected ?? this.unprotected,
        temp: clearTemp ? null : (temp ?? this.temp),
        water: clearWater ? null : (water ?? this.water),
        sleep: clearSleep ? null : (sleep ?? this.sleep),
        sleepBedtime: clearSleepBedtime ? null : (sleepBedtime ?? this.sleepBedtime),
        sleepWakeTime: clearSleepWakeTime ? null : (sleepWakeTime ?? this.sleepWakeTime),
        weight: clearWeight ? null : (weight ?? this.weight),
        photo: clearPhoto ? null : (photo ?? this.photo),
        cervicalMucus: clearCervicalMucus ? null : (cervicalMucus ?? this.cervicalMucus),
        spotting: clearSpotting ? null : (spotting ?? this.spotting),
        medication: medication ?? this.medication,
        breastSelfExam: clearBreastSelfExam ? null : (breastSelfExam ?? this.breastSelfExam),
        mood: mood ?? this.mood,
        energy: clearEnergy ? null : (energy ?? this.energy),
        skinHair: skinHair ?? this.skinHair,
        sexTimes: clearSexTimes ? null : (sexTimes ?? this.sexTimes),
        sexDesire: sexDesire ?? this.sexDesire,
        sexMasturbation: sexMasturbation ?? this.sexMasturbation,
        sexNoOrgasm: sexNoOrgasm ?? this.sexNoOrgasm,
        sexOrgasm: sexOrgasm ?? this.sexOrgasm,
        diu: diu ?? this.diu,
        sexNone: sexNone ?? this.sexNone,
      );
}

/// Catálogo de síntomas disponibles para registrar (id, etiqueta, emoji).
///
/// Hinchazón/Acné/Cabeza se cambiaron a petición del usuario (los
/// originales 🎈/🔴/🤕 no se leían bien de un vistazo, poco relacionados
/// visualmente con lo que representan): 🫃 evoca hinchazón abdominal de
/// forma más directa que un globo, 🩹 remite a cuidado de la piel en vez
/// de un punto rojo genérico, y 🧠 es más reconocible como "cabeza/dolor
/// de cabeza" que la cara con venda. El resto (Dolor, Ánimo, Energía,
/// Antojos, Sueño) se mantiene igual.
const List<Map<String, String>> kSymptomCatalog = [
  {'id': 'dolor', 'label': 'Dolor', 'emoji': '😖'},
  {'id': 'animo', 'label': 'Ánimo', 'emoji': '🙂'},
  {'id': 'energia', 'label': 'Energía', 'emoji': '⚡'},
  {'id': 'antojos', 'label': 'Antojos', 'emoji': '🍫'},
  {'id': 'hinchazon', 'label': 'Hinchazón', 'emoji': '🫃'},
  {'id': 'sueno', 'label': 'Sueño', 'emoji': '😴'},
  {'id': 'acne', 'label': 'Acné', 'emoji': '🩹'},
  {'id': 'dolorcab', 'label': 'Cabeza', 'emoji': '🧠'},
];

/// Mapa rápido id -> emoji, usado en línea de tiempo e insights.
const Map<String, String> kSymptomEmoji = {
  'dolor': '😖',
  'animo': '🙂',
  'energia': '⚡',
  'antojos': '🍫',
  'hinchazon': '🫃',
  'sueno': '😴',
  'acne': '🩹',
  'dolorcab': '🧠',
};

/// Mapa rápido id -> etiqueta legible, para mostrar el nombre del síntoma
/// en la línea de tiempo y en los insights.
const Map<String, String> kSymptomLabel = {
  'dolor': 'Dolor',
  'animo': 'Ánimo',
  'energia': 'Energía',
  'antojos': 'Antojos',
  'hinchazon': 'Hinchazón',
  'sueno': 'Sueño',
  'acne': 'Acné',
  'dolorcab': 'Cabeza',
};

const List<Map<String, String>> kFlowOptions = [
  {'id': 'none', 'label': 'Sin flujo'},
  {'id': 'light', 'label': 'Ligero'},
  {'id': 'medium', 'label': 'Medio'},
  {'id': 'heavy', 'label': 'Abundante'},
];

const Map<String, String> kFlowLabel = {
  'light': 'Ligero',
  'medium': 'Medio',
  'heavy': 'Abundante',
};

/// Manchado (spotting) fuera del flujo principal: sangrado ligero e
/// irregular que puede darse entre periodos, por ovulación, anticonceptivos
/// hormonales, etc. Es un dato distinto del flujo menstrual normal, por eso
/// se registra en su propio campo. El color aproximado de cada tipo ayuda a
/// distinguir de un vistazo si es sangre más antigua (marrón), muy ligera
/// (rosa) o reciente/fresca (rojo).
const List<Map<String, String>> kSpottingOptions = [
  {'id': 'none', 'label': 'Ninguno'},
  {'id': 'brown', 'label': 'Marrón'},
  {'id': 'pink', 'label': 'Rosa'},
  {'id': 'red', 'label': 'Rojo'},
];

/// Catálogo de tipos de moco cervical (escala tipo Billings), del menos al
/// más fértil. Se usa junto a la temperatura basal para el método
/// sintotérmico: el tipo "clara de huevo" (elástico y transparente) marca
/// los días de mayor fertilidad, justo antes de la ovulación.
///
/// Emojis cambiados a petición del usuario: antes eran un cactus, un
/// círculo amarillo genérico, una nube y un huevo entero, que no daban
/// sensación de progresión ni se relacionaban bien entre sí. Ahora usan
/// una progresión de "gota" (vacía -> llena) más consistente visualmente
/// de un vistazo, terminando en la burbuja transparente y el huevo para
/// el tipo más fértil.
const List<Map<String, String>> kCervicalMucusOptions = [
  {'id': 'dry', 'label': 'Seco', 'emoji': '🏜️'},
  {'id': 'sticky', 'label': 'Pegajoso', 'emoji': '🔸'},
  {'id': 'creamy', 'label': 'Cremoso', 'emoji': '🥛'},
  {'id': 'watery', 'label': 'Acuoso', 'emoji': '💧'},
  {'id': 'eggwhite', 'label': 'Clara de huevo', 'emoji': '🥚'},
];

/// Niveles de intensidad disponibles para un síntoma, en el mismo orden
/// que usa el prototipo web al "ciclar" con cada toque.
const List<String> kSymptomLevels = ['leve', 'moderado', 'fuerte'];

/// Replica `cycleSymptomLevel` del prototipo: sin nivel -> leve -> moderado
/// -> fuerte -> sin nivel (null). Devuelve el siguiente nivel, o null si
/// el síntoma debe quedar sin marcar.
String? cycleSymptomLevel(String? current) {
  final idx = kSymptomLevels.indexOf(current ?? '');
  if (idx == -1) return kSymptomLevels.first;
  if (idx == kSymptomLevels.length - 1) return null;
  return kSymptomLevels[idx + 1];
}

// ==================== Catálogos nuevos (pestaña "Registrar") ====================
// Añadidos en el rediseño de 5 pestañas inspirado en apps de referencia tipo
// Flo. Mismo patrón id/label/emoji que kSymptomCatalog — el label aquí es
// solo un fallback en español; la UI siempre debe preferir la traducción
// correspondiente en app_strings.dart (una función tipo `moodLabel(id)` por
// catálogo) en vez de leer 'label' directamente.

/// Ánimo del día (puede marcarse más de uno).
const List<Map<String, String>> kMoodCatalog = [
  {'id': 'feliz', 'label': 'Feliz', 'emoji': '😊'},
  {'id': 'enfadada', 'label': 'Enfadada', 'emoji': '😠'},
  {'id': 'enamorada', 'label': 'Enamorada', 'emoji': '🥰'},
  {'id': 'agotada', 'label': 'Agotada', 'emoji': '🥱'},
  {'id': 'triste', 'label': 'Triste', 'emoji': '😢'},
  {'id': 'deprimida', 'label': 'Deprimida', 'emoji': '😞'},
  {'id': 'sensible', 'label': 'Sensible', 'emoji': '🥹'},
  {'id': 'ansiosa', 'label': 'Ansiosa', 'emoji': '😰'},
];

/// Nivel de energía del día (selección única).
const List<Map<String, String>> kEnergyOptions = [
  {'id': 'baja', 'label': 'Baja', 'emoji': '🔋'},
  {'id': 'media', 'label': 'Media', 'emoji': '🔋'},
  {'id': 'alta', 'label': 'Alta', 'emoji': '⚡'},
  {'id': 'con_energia', 'label': 'Con energía', 'emoji': '✨'},
];

/// Autoexamen de mamas (selección única: el hallazgo principal del día).
const List<Map<String, String>> kBreastSelfExamCatalog = [
  {'id': 'normal', 'label': 'Todo en orden', 'emoji': '✅'},
  {'id': 'congestion', 'label': 'Congestión', 'emoji': '🔴'},
  {'id': 'bulto', 'label': 'Bulto', 'emoji': '⚠️'},
  {'id': 'hoyuelo', 'label': 'Hoyuelo', 'emoji': '🔘'},
  {'id': 'irritacion', 'label': 'Irritación piel', 'emoji': '🩹'},
  {'id': 'pezones_agrietados', 'label': 'Pezones agrietados', 'emoji': '💢'},
  {'id': 'dolor', 'label': 'Dolor', 'emoji': '😖'},
  {'id': 'secrecion', 'label': 'Secreción del pezón', 'emoji': '💧'},
];

/// Piel y cabello del día (puede marcarse más de uno).
const List<Map<String, String>> kSkinHairCatalog = [
  {'id': 'brillo_saludable', 'label': 'Brillo saludable', 'emoji': '✨'},
  {'id': 'enrojecimiento', 'label': 'Enrojecimiento', 'emoji': '🔴'},
  {'id': 'piel_reseca', 'label': 'Piel reseca', 'emoji': '🏜️'},
  {'id': 'piel_grasa', 'label': 'Piel con grasa', 'emoji': '💧'},
  {'id': 'buen_dia_cabello', 'label': 'Buen día cabello', 'emoji': '💇'},
  {'id': 'mal_dia_cabello', 'label': 'Mal día cabello', 'emoji': '😩'},
  {'id': 'caida_cabello', 'label': 'Caída cabello', 'emoji': '🪮'},
  {'id': 'cabello_graso', 'label': 'Cabello con grasa', 'emoji': '💦'},
];

/// Medicamentos de uso frecuente, ofrecidos como catálogo rápido; la
/// pantalla "Registrar" también permite añadir uno con texto libre (botón
/// "+") que se guarda con el mismo formato de id (slug del texto escrito).
const List<Map<String, String>> kMedicationCatalog = [
  {'id': 'analgesico', 'label': 'Analgésico', 'emoji': '💊'},
  {'id': 'anticonceptivo', 'label': 'Anticonceptivo', 'emoji': '💊'},
  {'id': 'antiinflamatorio', 'label': 'Antiinflamatorio', 'emoji': '💊'},
  {'id': 'vitaminas', 'label': 'Vitaminas', 'emoji': '💊'},
  {'id': 'hierro', 'label': 'Hierro', 'emoji': '💊'},
  {'id': 'otro', 'label': 'Otro', 'emoji': '💊'},
];
