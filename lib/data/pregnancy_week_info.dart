// Contenido semana a semana (1-40) para la pantalla de "Simulacro" de
// embarazo (pregnancy_simulator_screen.dart): tamaño comparado del bebé,
// texto de desarrollo y un consejo para la madre. Traducido y resumido a
// partir de fuentes médicas de referencia (Mayo Clinic, Cleveland Clinic,
// ACOG, ver notas de la sesión) — no sustituye el consejo de un
// profesional de la salud, es contenido educativo general.
//
// Es contenido secundario en español solamente (como _factFor y
// _babySizes en pregnancy_tracking_screen.dart), no pasa por AppStrings.
class PregnancyWeekInfo {
  final int week;
  final String size;
  final String development;
  final String tip;

  const PregnancyWeekInfo({
    required this.week,
    required this.size,
    required this.development,
    required this.tip,
  });
}

/// Devuelve la info de la semana pedida, con clamp a 1-40.
PregnancyWeekInfo pregnancyWeekInfoFor(int week) {
  final w = week.clamp(1, 40);
  return pregnancyWeekInfoList.firstWhere(
    (e) => e.week == w,
    orElse: () => pregnancyWeekInfoList.last,
  );
}

// Imagen de la barriga de embarazo para la semana indicada — generadas con
// IA en assets/pregnancy_belly/week_01.png .. week_40.png, mismo estilo
// consistente entre semanas para poder verlas evolucionar en el
// simulacro (pregnancy_simulator_screen.dart). Si el asset de una semana
// concreta todavía no existe, quien la use debe manejarlo con
// Image.asset(...).errorBuilder (ver PregnancySimulatorScreen) en vez de
// que la app se rompa — así el simulacro funciona ya con las fotos del
// bebé aunque las de la barriga se añadan más tarde.
// [appearance] elige el set de fotos a usar: 'default' (mujer de piel
// clara, set original) o 'black' (mujer negra, set añadido después a
// pedido explícito de la usuaria — ver assets/pregnancy_belly_black/).
// Se guarda como texto simple vía SettingsService.loadBellyAppearance,
// igual patrón que _calendarPaletteKey.
String pregnancyBellyImagePath(int week, {String appearance = 'default'}) {
  final w = week.clamp(1, 40);
  final folder = appearance == 'black' ? 'pregnancy_belly_black' : 'pregnancy_belly';
  return 'assets/$folder/week_${w.toString().padLeft(2, '0')}.png';
}

const List<PregnancyWeekInfo> pregnancyWeekInfoList = [
  PregnancyWeekInfo(
    week: 1,
    size: 'Todavía no hay embrión: tu cuerpo se prepara para ovular',
    development:
        'El embarazo se cuenta desde el primer día de tu última regla, aunque la concepción todavía no ha ocurrido. Tu cuerpo se está preparando para la ovulación.',
    tip: 'Si estás buscando quedar embarazada, es un buen momento para empezar a tomar ácido fólico.',
  ),
  PregnancyWeekInfo(
    week: 2,
    size: 'Semana de la ovulación: el óvulo está listo para ser fecundado',
    development: 'La ovulación ocurre aproximadamente a mitad de tu ciclo. El óvulo está listo para ser fecundado.',
    tip: 'Evita el alcohol y el tabaco si estás intentando concebir.',
  ),
  PregnancyWeekInfo(
    week: 3,
    size: 'Del tamaño de un grupo diminuto de células',
    development:
        'El espermatozoide fecunda al óvulo y comienza la división celular. La placenta empieza a formarse mientras el óvulo fecundado viaja hacia el útero.',
    tip: 'Mantén una dieta equilibrada; muchos de los órganos del bebé empezarán a formarse muy pronto.',
  ),
  PregnancyWeekInfo(
    week: 4,
    size: 'una semilla de amapola 🌱',
    development:
        'El óvulo fecundado se implanta en el útero y comienza a desarrollarse como embrión. El cordón umbilical empieza a formarse a partir de la placenta.',
    tip: 'Si tienes un retraso en tu regla, es buen momento para hacerte una prueba de embarazo y pedir cita con tu médico.',
  ),
  PregnancyWeekInfo(
    week: 5,
    size: 'una semilla de naranja',
    development:
        'Se forma el tubo neural, que dará origen al cerebro y la médula espinal. El corazón empieza a formarse y puede comenzar a latir estos días.',
    tip: 'Empieza (o continúa) con tus vitaminas prenatales. Las náuseas pueden comenzar por estas fechas.',
  ),
  PregnancyWeekInfo(
    week: 6,
    size: 'una semilla de granada',
    development:
        'El embrión toma una forma curvada en "C". Aparecen los primeros brotes que más adelante serán los brazos y las piernas.',
    tip: 'Descansa cuanto puedas y mantente bien hidratada; el cansancio de estas semanas es normal.',
  ),
  PregnancyWeekInfo(
    week: 7,
    size: 'un arándano 🫐',
    development:
        'El cerebro y la cara crecen con rapidez. Empiezan a formarse los párpados y los primeros huesos, además de las fosas nasales.',
    tip: 'Si las náuseas te afectan, prueba comidas pequeñas y frecuentes a lo largo del día.',
  ),
  PregnancyWeekInfo(
    week: 8,
    size: 'una frambuesa 🍇',
    development:
        'Todos los órganos principales ya se han formado y siguen madurando. A partir de esta semana, deja de llamarse embrión y pasa a llamarse feto.',
    tip: 'Si aún no lo has hecho, agenda tu primera consulta prenatal y ecografía.',
  ),
  PregnancyWeekInfo(
    week: 9,
    size: 'una cereza 🍒',
    development:
        'Se definen los rasgos de la cara, incluida una naricita más marcada. La cabeza sigue siendo grande en proporción al cuerpo.',
    tip: 'Mantente activa con ejercicio suave (como caminar) si tu médico te lo permite.',
  ),
  PregnancyWeekInfo(
    week: 10,
    size: 'una fresa 🍓',
    development: 'La cabeza se redondea y los párpados y los oídos siguen desarrollándose.',
    tip: 'Cuida tu alimentación priorizando alimentos ricos en hierro y calcio.',
  ),
  PregnancyWeekInfo(
    week: 11,
    size: 'una col de Bruselas',
    development:
        'Comienza a formarse el tejido muscular y algunos huesos empiezan a endurecerse. El hígado empieza a producir glóbulos rojos.',
    tip: 'Las náuseas suelen empezar a mejorar en las próximas semanas, ten paciencia.',
  ),
  PregnancyWeekInfo(
    week: 12,
    size: 'un maracuyá',
    development:
        'El bebé ya se mueve, aunque todavía no lo notarás. Las manos están más desarrolladas que las piernas y los rasgos faciales se afinan.',
    tip: 'Termina el primer trimestre: buen momento para compartir la noticia si así lo deseas.',
  ),
  PregnancyWeekInfo(
    week: 13,
    size: 'una ciruela grande',
    development:
        'Empiezan a producirse las hormonas sexuales. El bebé ya puede producir orina tras tragar líquido amniótico, y todos sus órganos están formados.',
    tip: 'Entras al segundo trimestre; muchas mujeres notan un aumento de energía por estas fechas.',
  ),
  PregnancyWeekInfo(
    week: 14,
    size: 'una nectarina',
    development:
        'El bebé puede llevarse las manos a la boca. Comienzan a desarrollarse el gusto y el olfato, y la piel empieza a engrosarse.',
    tip: 'Es un buen momento para practicar ejercicio moderado o yoga prenatal.',
  ),
  PregnancyWeekInfo(
    week: 15,
    size: 'una toronja pequeña',
    development: 'El bebé ya puede girar y voltearse. Su corazón bombea una gran cantidad de sangre cada día.',
    tip: 'Cuida tu postura: tu centro de gravedad está empezando a cambiar.',
  ),
  PregnancyWeekInfo(
    week: 16,
    size: 'una manzana 🍎',
    development: 'El sistema digestivo empieza a funcionar. El bebé ya puede escuchar algunos sonidos.',
    tip: 'Aprovecha para hablarle o cantarle a tu bebé: ya puede empezar a oírte.',
  ),
  PregnancyWeekInfo(
    week: 17,
    size: 'una pera 🍐',
    development:
        'Empieza a producirse el vérnix, una sustancia grasa que protege la piel del bebé. Las uñas de los pies comienzan a crecer.',
    tip: 'Hidrata bien tu piel, sobre todo el abdomen, que empieza a estirarse.',
  ),
  PregnancyWeekInfo(
    week: 18,
    size: 'un camote (boniato)',
    development:
        'Aparece el lanugo, un vello fino que cubre el cuerpo del bebé. Puede despertarse al notar tus movimientos.',
    tip: 'Si no la has programado aún, este es el momento habitual para la ecografía morfológica.',
  ),
  PregnancyWeekInfo(
    week: 19,
    size: 'un mango 🥭',
    development:
        'Los movimientos del bebé se hacen más fuertes. Se han formado los ovarios (en niñas) o los testículos (en niños).',
    tip: 'Usa crema hidratante para aliviar la tirantez de la piel del abdomen.',
  ),
  PregnancyWeekInfo(
    week: 20,
    size: 'un pimiento 🫑',
    development:
        '¡Mitad del embarazo! En la ecografía ya pueden verse algunos rasgos faciales y, si quieres saberlo, el sexo del bebé.',
    tip: 'Aprovecha la ecografía de las 20 semanas para revisar con calma la anatomía de tu bebé.',
  ),
  PregnancyWeekInfo(
    week: 21,
    size: 'un plátano 🍌',
    development: 'Los dedos de manos y pies ya están completamente formados. El bebé puede tener episodios de hipo.',
    tip: 'Empieza a familiarizarte con los patrones de movimiento de tu bebé.',
  ),
  PregnancyWeekInfo(
    week: 22,
    size: 'una papaya 🥭',
    development: 'Los cinco sentidos se están desarrollando. El bebé ya oye tu voz, tu corazón y sonidos del exterior.',
    tip: 'Cuida una dieta rica en omega-3, importante para el desarrollo del cerebro.',
  ),
  PregnancyWeekInfo(
    week: 23,
    size: 'una berenjena 🍆',
    development: 'El bebé puede responder a tu voz moviéndose, y pasa buena parte del tiempo en fase de sueño REM.',
    tip: 'Vigila la hinchazón de pies y tobillos: suele ser normal en esta etapa, coméntalo en tu consulta.',
  ),
  PregnancyWeekInfo(
    week: 24,
    size: 'una mazorca de maíz 🌽',
    development:
        'Los pulmones siguen formándose, aunque aún no son funcionales. Con cuidados intensivos, esta semana marca un punto de viabilidad temprana.',
    tip: 'Por estas semanas suele realizarse la prueba de tolerancia a la glucosa.',
  ),
  PregnancyWeekInfo(
    week: 25,
    size: 'una calabaza pequeña',
    development: 'El sistema nervioso se desarrolla con rapidez. El bebé empieza a ganar grasita en las mejillas.',
    tip: 'Cuida tu descanso; dormir de lado izquierdo ayuda a mejorar la circulación.',
  ),
  PregnancyWeekInfo(
    week: 26,
    size: 'un calabacín',
    development: 'El bebé empieza a producir melanina, el pigmento de la piel. Los pulmones comienzan a producir surfactante.',
    tip: 'Revisa tu presión arterial con regularidad en tus consultas.',
  ),
  PregnancyWeekInfo(
    week: 27,
    size: 'una coliflor 🥦',
    development: 'El bebé ya puede hacer movimientos de agarre. Tu voz puede calmarlo y hacer que su ritmo cardíaco baje.',
    tip: 'Entras al tercer trimestre: prepárate para consultas prenatales más frecuentes.',
  ),
  PregnancyWeekInfo(
    week: 28,
    size: 'una lechuga',
    development: 'Los ojos del bebé ya se abren y se cierran. Empiezan a crecerle las pestañas.',
    tip: 'Muchas mamás empiezan a llevar la cuenta de las pataditas diarias desde esta semana.',
  ),
  PregnancyWeekInfo(
    week: 29,
    size: 'una calabaza butternut',
    development: 'Los movimientos del bebé se notan cada vez más y con más frecuencia.',
    tip: 'Descansa las piernas en alto de vez en cuando para aliviar la hinchazón.',
  ),
  PregnancyWeekInfo(
    week: 30,
    size: 'un repollo 🥬',
    development: 'El lanugo empieza a caerse poco a poco. El bebé puede tener ya algo de pelo en la cabeza.',
    tip: 'Practicar ejercicios de respiración puede ayudarte a prepararte para el parto.',
  ),
  PregnancyWeekInfo(
    week: 31,
    size: 'un coco 🥥',
    development:
        'El bebé ya regula su propia temperatura corporal. Sus huesos empiezan a endurecerse, aunque el cráneo sigue siendo flexible.',
    tip: 'Poco a poco, empieza a preparar la maleta para el hospital.',
  ),
  PregnancyWeekInfo(
    week: 32,
    size: 'una col china',
    development: 'Las uñas de los pies ya son visibles. La piel es cada vez menos transparente al ganar grasa.',
    tip: 'En tus consultas, tu médico empezará a revisar la posición del bebé.',
  ),
  PregnancyWeekInfo(
    week: 33,
    size: 'una piña 🍍',
    development: 'El bebé gana en torno a medio kilo por semana a partir de ahora. Los cinco sentidos ya funcionan.',
    tip: 'Baja el ritmo cuando lo necesites y prioriza el descanso.',
  ),
  PregnancyWeekInfo(
    week: 34,
    size: 'un melón cantalupo',
    development: 'El bebé puede empezar a colocarse boca abajo, preparándose para el parto. Sigue ganando peso.',
    tip: 'Aprende a reconocer las señales de inicio del trabajo de parto.',
  ),
  PregnancyWeekInfo(
    week: 35,
    size: 'un melón dulce',
    development:
        'Su piel se vuelve más rosada a medida que gana grasa. El sistema musculoesquelético ya está completo.',
    tip: 'Termina de organizar los preparativos del hospital y de casa.',
  ),
  PregnancyWeekInfo(
    week: 36,
    size: 'una lechuga romana',
    development: 'El bebé ocupa ya casi todo el espacio disponible dentro del útero.',
    tip: 'A partir de ahora, las consultas prenatales suelen pasar a ser semanales.',
  ),
  PregnancyWeekInfo(
    week: 37,
    size: 'una acelga',
    development: 'Se considera término temprano. El bebé ha perdido casi todo el lanugo y sigue ganando grasa.',
    tip: 'Repasa con tu pareja o acompañante las señales de un parto en marcha.',
  ),
  PregnancyWeekInfo(
    week: 38,
    size: 'un ruibarbo',
    development:
        'El hígado y los pulmones están casi maduros del todo. El bebé puede empezar a encajarse en la pelvis.',
    tip: 'Mantente en contacto cercano con tu médico o matrona estos días.',
  ),
  PregnancyWeekInfo(
    week: 39,
    size: 'una sandía pequeña 🍉',
    development: '¡Término completo! El cerebro del bebé sigue desarrollándose y lo seguirá haciendo tras nacer.',
    tip: 'Descansa todo lo que puedas: el parto puede comenzar en cualquier momento.',
  ),
  PregnancyWeekInfo(
    week: 40,
    size: 'una sandía pequeña 🍉',
    development:
        'El bebé está completamente listo para nacer. Suele medir entre 46 y 51 cm y pesar entre 2,7 y 4 kg aproximadamente.',
    tip: 'Mantén la calma y confía en tu cuerpo y en tu equipo médico: pronto conocerás a tu bebé.',
  ),
];
