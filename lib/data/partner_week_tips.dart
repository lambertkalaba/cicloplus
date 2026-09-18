// Contenido semana a semana (1-40) para la pestaña "Consejos" que ve la
// PAREJA/socia vinculada (ver PartnerTipsScreen), no la dueña del embarazo
// — ese contenido para la dueña ya existe en pregnancy_week_info.dart. Aquí
// el enfoque es "qué puede estar sintiendo ella esta semana" + "cómo
// puedes ayudarla/acompañarla" desde el punto de vista del acompañante.
//
// Igual que pregnancy_week_info.dart: contenido educativo general, resumido
// a partir de fuentes médicas de referencia (Mayo Clinic, Cleveland Clinic,
// ACOG), no sustituye el consejo de un profesional de la salud. Español
// solamente, no pasa por AppStrings (mismo criterio que el resto del
// contenido semanal de embarazo).
class PartnerWeekTip {
  final int week;
  final String whatSheMayFeel;
  final String howToHelp;

  const PartnerWeekTip({
    required this.week,
    required this.whatSheMayFeel,
    required this.howToHelp,
  });
}

/// Devuelve el consejo de la semana pedida, con clamp a 1-40 — mismo
/// patrón que pregnancyWeekInfoFor.
PartnerWeekTip partnerWeekTipFor(int week) {
  final w = week.clamp(1, 40);
  return partnerWeekTipList.firstWhere(
    (e) => e.week == w,
    orElse: () => partnerWeekTipList.last,
  );
}

const List<PartnerWeekTip> partnerWeekTipList = [
  PartnerWeekTip(
    week: 1,
    whatSheMayFeel: 'Todavía no hay síntomas físicos — el embarazo apenas se cuenta desde su última regla.',
    howToHelp: 'Si están buscando el embarazo, anímala a empezar (o seguir) tomando ácido fólico.',
  ),
  PartnerWeekTip(
    week: 2,
    whatSheMayFeel: 'Es la semana de la ovulación, puede que note algo de hinchazón o mayor sensibilidad.',
    howToHelp: 'Apóyala si están evitando alcohol o tabaco mientras intentan concebir — hazlo también tú.',
  ),
  PartnerWeekTip(
    week: 3,
    whatSheMayFeel: 'Todavía no suele haber síntomas notables, aunque algunas mujeres sienten cambios sutiles.',
    howToHelp: 'Cocinar comidas equilibradas juntos es un buen hábito para empezar desde ya.',
  ),
  PartnerWeekTip(
    week: 4,
    whatSheMayFeel: 'Puede notar un retraso en su regla y los primeros indicios: cansancio o pechos sensibles.',
    howToHelp: 'Si sospecha que está embarazada, acompáñala a hacerse la prueba y a pedir la primera cita médica.',
  ),
  PartnerWeekTip(
    week: 5,
    whatSheMayFeel: 'Las náuseas y el cansancio suelen empezar por esta semana, a veces de forma intensa.',
    howToHelp: 'Ten a mano snacks suaves (galletas saladas, fruta) y no te ofendas si algunos olores de repente le molestan.',
  ),
  PartnerWeekTip(
    week: 6,
    whatSheMayFeel: 'Náuseas matutinas (que pueden durar todo el día), fatiga y cambios de humor son comunes.',
    howToHelp: 'Sé paciente con los cambios de ánimo — son hormonales, no algo personal contra ti.',
  ),
  PartnerWeekTip(
    week: 7,
    whatSheMayFeel: 'El olfato más sensible puede hacer que rechace comidas u olores que antes le gustaban.',
    howToHelp: 'Pregunta qué olores le molestan (perfume, café, ciertas comidas) y evítalos cerca de ella por ahora.',
  ),
  PartnerWeekTip(
    week: 8,
    whatSheMayFeel: 'El cansancio puede ser muy fuerte — dormir más de lo normal es completamente esperable.',
    howToHelp: 'Encárgate de alguna tarea de la casa que normalmente hace ella, sin que tenga que pedirlo.',
  ),
  PartnerWeekTip(
    week: 9,
    whatSheMayFeel: 'Puede sentirse hinchada y con la ropa más ajustada, aunque todavía no se note por fuera.',
    howToHelp: 'Evita comentarios sobre su cuerpo, aunque sean bienintencionados — deja que ella marque el tema.',
  ),
  PartnerWeekTip(
    week: 10,
    whatSheMayFeel: 'Las náuseas suelen estar en su punto más alto; algunos antojos o aversiones raras son normales.',
    howToHelp: 'Si le apetece algo específico a horas raras, consigue lo que puedas sin juzgar — es hormonal, no capricho.',
  ),
  PartnerWeekTip(
    week: 11,
    whatSheMayFeel: 'Puede empezar a sentirse un poco mejor de las náuseas, aunque el cansancio sigue.',
    howToHelp: 'Anímala a moverse un poco (caminar suave) si le apetece, pero sin presionar si prefiere descansar.',
  ),
  PartnerWeekTip(
    week: 12,
    whatSheMayFeel: 'Se acerca el final del primer trimestre — para muchas, un alivio emocional importante.',
    howToHelp: 'Es un buen momento para hablar juntos de cómo va todo y qué necesita de ti de aquí en adelante.',
  ),
  PartnerWeekTip(
    week: 13,
    whatSheMayFeel: 'Las náuseas suelen empezar a ceder para la mayoría, y la energía puede empezar a volver.',
    howToHelp: 'Celebra con ella el cierre del primer trimestre — ha sido la parte más dura para su cuerpo.',
  ),
  PartnerWeekTip(
    week: 14,
    whatSheMayFeel: 'Suele sentirse con más energía; el segundo trimestre es, para muchas, el más cómodo.',
    howToHelp: 'Aprovechen esta etapa para planear cosas juntos (una escapada corta, organizar el cuarto del bebé).',
  ),
  PartnerWeekTip(
    week: 15,
    whatSheMayFeel: 'La piel y el cabello pueden verse más brillantes por los cambios hormonales.',
    howToHelp: 'Hazle saber que se la ve bien — en esta etapa muchas mujeres agradecen el cumplido.',
  ),
  PartnerWeekTip(
    week: 16,
    whatSheMayFeel: 'Puede empezar a notar un ligero abultamiento en el abdomen.',
    howToHelp: 'Si quiere, acompáñala a comprar su primera ropa premamá — puede ser un momento bonito juntos.',
  ),
  PartnerWeekTip(
    week: 17,
    whatSheMayFeel: 'Molestias leves en la zona baja del abdomen (ligamentos estirándose) son normales.',
    howToHelp: 'Un masaje suave de espalda o simplemente ayudarla a sentarse cómoda puede aliviarla bastante.',
  ),
  PartnerWeekTip(
    week: 18,
    whatSheMayFeel: 'Muchas empiezan a sentir los primeros movimientos del bebé por estas semanas.',
    howToHelp: 'Pregúntale seguido si ya sintió algo — compartir esa emoción con ella la hace sentir acompañada.',
  ),
  PartnerWeekTip(
    week: 19,
    whatSheMayFeel: 'El abdomen crece más notablemente; puede aparecer algo de dolor de espalda.',
    howToHelp: 'Ofrécele apoyo al caminar o levantarse, y evita que cargue cosas pesadas.',
  ),
  PartnerWeekTip(
    week: 20,
    whatSheMayFeel: 'Llegan a la mitad del embarazo — suele ser cuando se hace la ecografía morfológica.',
    howToHelp: 'Si pueden, acompáñala a esa cita — ver al bebé juntos suele ser un momento muy especial.',
  ),
  PartnerWeekTip(
    week: 21,
    whatSheMayFeel: 'Los movimientos del bebé se vuelven más claros y frecuentes.',
    howToHelp: 'Pon la mano en su vientre cuando te avise que el bebé se mueve — a muchas les encanta compartir eso.',
  ),
  PartnerWeekTip(
    week: 22,
    whatSheMayFeel: 'Puede notar estrías, comezón en la piel del abdomen, o hinchazón leve en los pies.',
    howToHelp: 'Ofrécele crema hidratante y ayúdale a subir los pies cuando descanse en el sofá.',
  ),
  PartnerWeekTip(
    week: 23,
    whatSheMayFeel: 'Contracciones leves e indoloras (Braxton Hicks) pueden empezar a sentirse de vez en cuando.',
    howToHelp: 'Tranquilízala si le preocupan — son normales, pero anímala a comentarlo en su próxima cita si tiene dudas.',
  ),
  PartnerWeekTip(
    week: 24,
    whatSheMayFeel: 'Puede sentir acidez o indigestión con más frecuencia a medida que el útero crece.',
    howToHelp: 'Sugieran juntos comidas más pequeñas y frecuentes en vez de platos grandes.',
  ),
  PartnerWeekTip(
    week: 25,
    whatSheMayFeel: 'Calambres en las piernas, sobre todo de noche, son bastante comunes en esta etapa.',
    howToHelp: 'Un estiramiento suave de pantorrilla antes de dormir, hecho junto a ella, puede ayudar.',
  ),
  PartnerWeekTip(
    week: 26,
    whatSheMayFeel: 'Puede costarle encontrar una posición cómoda para dormir.',
    howToHelp: 'Consíguele almohadas extra para apoyar la espalda o entre las rodillas al dormir de lado.',
  ),
  PartnerWeekTip(
    week: 27,
    whatSheMayFeel: 'Termina el segundo trimestre — el cansancio puede empezar a volver poco a poco.',
    howToHelp: 'Es un buen momento para retomar juntos la conversación sobre el plan de parto.',
  ),
  PartnerWeekTip(
    week: 28,
    whatSheMayFeel: 'Empieza el tercer trimestre; las citas médicas suelen volverse más frecuentes.',
    howToHelp: 'Ayúdala a organizar las próximas citas y, si puedes, acompáñala a alguna.',
  ),
  PartnerWeekTip(
    week: 29,
    whatSheMayFeel: 'La falta de aire al moverse es normal — el útero empuja hacia arriba, contra los pulmones.',
    howToHelp: 'No la apures al caminar; deja que marque su propio ritmo.',
  ),
  PartnerWeekTip(
    week: 30,
    whatSheMayFeel: 'El sueño puede ser más difícil por la falta de aire, la acidez o simplemente el tamaño de la barriga.',
    howToHelp: 'Sé comprensivo si duerme mal — evita planear actividades muy exigentes para el día siguiente.',
  ),
  PartnerWeekTip(
    week: 31,
    whatSheMayFeel: 'Puede sentirse más torpe o pesada al moverse, algo totalmente esperado a esta altura.',
    howToHelp: 'Ofrece ayuda con tareas que impliquen agacharse o cargar peso, sin que tenga que pedirlo.',
  ),
  PartnerWeekTip(
    week: 32,
    whatSheMayFeel: 'Hinchazón en pies y tobillos puede aumentar, sobre todo al final del día.',
    howToHelp: 'Anímala a subir los pies un rato cada tarde, y ofrécele un masaje si le apetece.',
  ),
  PartnerWeekTip(
    week: 33,
    whatSheMayFeel: 'El bebé se mueve menos por falta de espacio, pero los movimientos son más fuertes.',
    howToHelp: 'Este es buen momento para terminar juntos de preparar la habitación o la maleta para el hospital.',
  ),
  PartnerWeekTip(
    week: 34,
    whatSheMayFeel: 'Puede sentir más ansiedad o nervios normales según se acerca la fecha de parto.',
    howToHelp: 'Escúchala si quiere hablar de sus miedos sobre el parto, sin minimizarlos ni intentar "arreglarlos".',
  ),
  PartnerWeekTip(
    week: 35,
    whatSheMayFeel: 'Puede sentir más presión en la pelvis a medida que el bebé se acomoda para nacer.',
    howToHelp: 'Repasen juntos el camino al hospital y qué llevar — tenerlo listo da tranquilidad a ambos.',
  ),
  PartnerWeekTip(
    week: 36,
    whatSheMayFeel: 'Las citas médicas suelen ser semanales desde ahora; puede sentirse impaciente por que llegue el momento.',
    howToHelp: 'Mantén el teléfono cerca y a mano las cosas importantes — el parto se puede adelantar.',
  ),
  PartnerWeekTip(
    week: 37,
    whatSheMayFeel: 'El embarazo ya se considera "a término temprano" — el bebé podría nacer en cualquier momento.',
    howToHelp: 'Confirmen juntos el plan: a quién avisar, cómo llegar al hospital, quién se queda con otros hijos si los hay.',
  ),
  PartnerWeekTip(
    week: 38,
    whatSheMayFeel: 'Puede sentir el "instinto de nido": ganas de limpiar, ordenar y dejar todo listo.',
    howToHelp: 'Ayúdala con esas tareas en vez de decirle que descanse — para muchas, hacerlo las tranquiliza.',
  ),
  PartnerWeekTip(
    week: 39,
    whatSheMayFeel: 'La espera puede sentirse larga; las contracciones de práctica pueden ser más frecuentes.',
    howToHelp: 'Sé paciente con la incertidumbre de "cuándo será" — ella también quisiera saberlo.',
  ),
  PartnerWeekTip(
    week: 40,
    whatSheMayFeel: 'Es la fecha probable de parto, aunque muchos bebés nacen unos días antes o después.',
    howToHelp: 'Mantén la calma y ten todo listo — tu tranquilidad le ayuda a ella a estar más tranquila también.',
  ),
];
