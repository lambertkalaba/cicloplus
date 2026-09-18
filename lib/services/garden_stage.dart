import 'cycle_predictor.dart' show dateKey;

/// Camino de assets para cada etapa del "jardín" de la racha diaria — de
/// muerta (0, varios días sin registrar) a máxima floración (4, racha
/// larga y activa). Ver [gardenStageIndex]. Compartido entre la tarjeta
/// "Tu jardín" de Hoy (today_screen.dart) y la vista previa de "siguiente
/// etapa" en Registrar (register_screen.dart) — vive aquí, fuera de
/// ambas pantallas, para que ninguna tenga que importar a la otra.
const List<String> gardenStageAssets = [
  'assets/garden/garden_dead.png',
  'assets/garden/garden_wilting.png',
  'assets/garden/garden_normal.png',
  'assets/garden/garden_healthy.png',
  'assets/garden/garden_bloom.png',
];

// Días que simula [gardenStageIndex] hacia atrás para llegar al estado
// actual — de sobra para que el punto de partida supuesto (ver
// [_initialSimulatedStage]) ya no influya en el resultado: como mucho
// hacen falta 4 días seguidos abriendo la app para ir de muerta a
// floración máxima, u 8 días seguidos sin abrirla para ir de floración
// máxima a muerta (ver reglas de [gardenStageIndex]), así que 20 días
// dejan margen de sobra en cualquiera de los dos sentidos.
const int _gardenSimulationWindowDays = 20;

// Etapa de la que arranca la simulación al principio de esa ventana de 20
// días — no importa mucho cuál sea (ver comentario de arriba, el efecto
// de partir de cualquier valor 0-4 desaparece bastante antes de esos 20
// días), es solo el punto de arranque del día a día.
const int _initialSimulatedStage = 2;

/// Calcula en qué etapa está el "jardín" (0 = muerta, 4 = floración
/// máxima) a partir de los días en que se ABRIÓ LA APP (ver
/// AppOpenController/SettingsService.recordAppOpenToday) — NO de si esos
/// días se registró algún síntoma.
///
/// Reglas pedidas explícitamente por la usuaria (antes una sola ausencia
/// ya bajaba una etapa entera de golpe, y volver a entrar recuperaba de
/// golpe la etapa que tocara por la racha, sin transición):
/// - Si NO se abre la app un día, el jardín se va "pudriendo" cada DOS
///   días de ausencia seguidos, no cada uno — una ausencia aislada de un
///   solo día no le resta nada todavía.
/// - Si SÍ se abre la app un día, el jardín revive UN escalón ese día
///   (nunca de golpe a plena floración) — por ejemplo, tras más de una
///   semana sin entrar (jardín ya muerto), hacen falta 4 días seguidos
///   abriendo la app para llegar de nuevo a la floración máxima.
///
/// Se simula día a día desde hace [_gardenSimulationWindowDays] días hasta
/// hoy en vez de mirar solo la racha final, para poder aplicar estas dos
/// velocidades distintas de subida/bajada.
int gardenStageIndex(Set<String> appOpenDates) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  bool wasOpened(DateTime d) => appOpenDates.contains(dateKey(d));

  int stage = _initialSimulatedStage;
  int missedStreak = 0;
  for (int i = _gardenSimulationWindowDays - 1; i >= 0; i--) {
    final day = todayDate.subtract(Duration(days: i));
    if (wasOpened(day)) {
      missedStreak = 0;
      stage = (stage + 1).clamp(0, 4);
    } else {
      missedStreak++;
      // Una etapa menos cada DOS días consecutivos sin abrir la app (no
      // cada uno): el primer día de ausencia (missedStreak == 1) todavía
      // no resta nada, el segundo sí (missedStreak == 2, par), y así
      // sucesivamente.
      if (missedStreak.isEven) {
        stage = (stage - 1).clamp(0, 4);
      }
    }
  }
  return stage;
}
