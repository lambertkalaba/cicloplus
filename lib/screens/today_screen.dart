import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/app_open_controller.dart';
import '../services/couple_illustration_controller.dart';
import '../services/cycle_predictor.dart';
import '../services/garden_stage.dart';
import '../services/settings_service.dart' show AppThemeOption, PregnancySettings, kAppThemes, themeById;
import '../theme/app_theme.dart';
import '../widgets/uterus_phase_illustration.dart';
import 'body_stage_detail_screen.dart';
import 'invite_partner_screen.dart';
import 'pregnancy_tracking_screen.dart';
import 'register_screen.dart';

/// Pestaña "Hoy": nueva pantalla principal de la barra inferior (índice 0),
/// construida a partir de una captura de referencia. Reemplaza a la
/// tarjeta de fase/embarazo que antes vivía como decoración condicional en
/// MainTabScreen (solo visible con `_currentTab == 0`) — ahora esa lógica
/// vive aquí dentro, como parte del layout completo de esta pestaña, en
/// vez de como un adorno sobre otra pantalla.
class TodayScreen extends StatelessWidget {
  final Map<String, DayEntry> data;
  final PregnancySettings pregnancy;
  final bool irregularCycleMode;
  // Duración de ciclo/periodo autoinformadas en el cuestionario de
  // "Intentar concebir" — respaldo para CyclePredictor mientras no hay
  // suficientes datos reales (ver conceive_intake_sheet.dart).
  final int? selfReportedCycleLen;
  final int? selfReportedPeriodLen;
  final String themeId;
  final String userId;
  final String userEmail;
  // "Mi objetivo" (Configuración/Yo): 'period' | 'conceive' | 'pregnancy' —
  // solo se usa aquí para resaltar más la tarjeta de ovulación/ventana
  // fértil cuando la usuaria eligió "Intentar concebir", igual que ya
  // hacen otras apps de seguimiento. No cambia ningún cálculo, solo el
  // énfasis visual de datos que la tarjeta ya mostraba.
  final String userGoal;

  /// Callback para refrescar datos tras cerrar el editor del día actual
  /// (mismo patrón que HomeScreen: onSave arma el Map actualizado y lo
  /// sube al padre, que persiste con StorageService).
  final ValueChanged<Map<String, DayEntry>> onDataChanged;

  const TodayScreen({
    super.key,
    required this.data,
    required this.pregnancy,
    required this.irregularCycleMode,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
    required this.themeId,
    required this.userId,
    required this.userEmail,
    this.userGoal = 'period',
    required this.onDataChanged,
  });

  CyclePredictor get _predictor => CyclePredictor(
        data,
        forceIrregular: irregularCycleMode,
        selfReportedCycleLen: selfReportedCycleLen,
        selfReportedPeriodLen: selfReportedPeriodLen,
      );

  // Editor de "hoy" — usa siempre RegisterScreen (más actualizado que el
  // antiguo DayEditorSheet en hoja modal, ya retirado de este flujo).
  void _openTodayEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          data: data,
          onDataChanged: onDataChanged,
          themeId: themeId,
          showCloseButton: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = themeById(themeId);
    final today = DateTime.now();
    final todayKey = dateKey(today);
    final isPeriodToday = (data[todayKey]?.isPeriodDay) ?? false;
    final inPregnancyMode = pregnancy.enabled && pregnancy.lmp != null;

    final dayInCycle = _predictor.currentDayInCycle();
    final cycleDayLabel = dayInCycle != null ? '${dayInCycle + 1}' : '—';

    DateTime? ovulation;
    bool isFertileToday = false;
    if (!inPregnancyMode) {
      final nextPeriod = _predictor.predictNextPeriod();
      ovulation = _predictor.predictOvulation(nextPeriod);
      if (ovulation != null) {
        final prediction = _predictor.predict();
        isFertileToday = prediction.fertileDates.contains(todayKey);
      }
    }
    // Solo para resaltar la parte correspondiente en la tarjeta de
    // anatomía interactiva — reutiliza el mismo cálculo de fase que ya
    // usa la tarjeta de etapa corporal, sin duplicar lógica nueva.
    final currentPhaseKey = inPregnancyMode ? null : _predictor.currentPhaseKey();
    // Igual que en otras apps de seguimiento: con el objetivo "Intentar
    // concebir" activo, la tarjeta de ovulación/ventana fértil se resalta
    // más (no cambia ninguna fecha ni cálculo, solo el estilo).
    final tryingToConceive = !inPregnancyMode && userGoal == 'conceive';

    return Scaffold(
      backgroundColor: AppColors.background,
      // Fondo con leve degradado (en vez de color plano) — mismo lenguaje
      // visual del rediseño "Después" aprobado por la usuaria: más
      // profundidad sin cambiar la paleta base de la app.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFFFF8F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4],
          ),
        ),
        child: SingleChildScrollView(
        // Antes 14 de padding arriba — pedido de la usuaria: quitar la
        // "línea blanca" (el hueco claro) entre la cabecera rosa
        // ondulada y la foto del jardín, así que se reduce este margen
        // superior (ver también el SizedBox justo antes de
        // _buildGardenCard, más abajo).
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            // Pedido explícito de la usuaria: el jardín va ARRIBA DE TODO,
            // antes incluso de la tarjeta del bebé/concebir/etapa corporal,
            // y en ese mismo orden para los 3 objetivos (seguir mi período,
            // intentar concebir, seguir mi embarazo).
            //
            // "Fin del período" vivía antes como botón suelto arriba de
            // esta tarjeta — pedido explícito de la usuaria de integrarlo
            // DENTRO de la tarjeta del jardín ("la caseta"), así que ahora
            // se dibuja como overlay de _buildGardenCard en vez de aquí.
            //
            // Con el embarazo activo, la tarjeta del jardín SE SIGUE
            // MOSTRANDO (pedido explícito de la usuaria: "en seguir mi
            // embarazo quiero que salga tu jardín") pero fija en su etapa
            // más bonita (floración máxima) en vez de calcularla por la
            // racha de días abiertos — no tiene sentido que se "seque" ni
            // que aparezca el botón/contador de "Fin del período" durante
            // el embarazo, así que _buildGardenCard recibe
            // inPregnancyMode para forzar esa etapa y ocultar esa parte.
            _buildGardenCard(s, theme, context, isPeriodToday, inPregnancyMode: inPregnancyMode),
            const SizedBox(height: 10),
            // Segunda tarjeta, justo debajo del jardín, según el objetivo
            // activo (pedido explícito de la usuaria):
            //  - "Seguir mi embarazo" -> tarjeta del bebé (foto real del
            //    día + semana).
            //  - "Intentar concebir" -> tarjeta de ovulación/ventana fértil
            //    ("Intento concebir"), que es la que de verdad importa para
            //    quien busca el embarazo.
            //  - "Seguir mi período" (o sin datos aún para calcular la
            //    ovulación) -> "Etapa corporal" tal cual estaba, con su
            //    acceso a BodyStageDetailScreen.
            if (inPregnancyMode)
              _buildPregnancyCard(s, context)
            else if (tryingToConceive && ovulation != null)
              _buildOvulationCard(s, theme, ovulation, isFertileToday, tryingToConceive)
            else
              _TapScale(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BodyStageDetailScreen(
                      data: data,
                      pregnancy: pregnancy,
                      irregularCycleMode: irregularCycleMode,
                      themeId: themeId,
                      userGoal: userGoal,
                    ),
                  ),
                ),
                child: _buildBodyStageCard(s, theme, cycleDayLabel),
              ),
            const SizedBox(height: 10),
            // "¿Cómo te sientes hoy?" — debajo de la tarjeta de objetivo,
            // igual para los 3 objetivos (pedido explícito de la usuaria).
            _buildHowDoYouFeelCard(s, theme, context),
            // "Invitar a un socio" lleva a InvitePartnerScreen, que ahora
            // comparte en modo lectura el embarazo (si está activo) o el
            // calendario de ciclo — previsto/ventana fértil — en los otros
            // dos objetivos, igual que hacen otras apps del rubro (p. ej.
            // Flo): compartir con la pareja no es exclusivo del embarazo,
            // así que esta tarjeta ya no se oculta fuera de ese modo.
            const SizedBox(height: 10),
            _SyncPartnerCard(
              s: s,
              themeId: themeId,
              userId: userId,
              userEmail: userEmail,
              userGoal: userGoal,
              pregnancy: pregnancy,
              irregularCycleMode: irregularCycleMode,
              selfReportedCycleLen: selfReportedCycleLen,
              selfReportedPeriodLen: selfReportedPeriodLen,
              data: data,
            ),
            const SizedBox(height: 10),
            _buildFunFactCard(s, theme, tryingToConceive: tryingToConceive, inPregnancyMode: inPregnancyMode),
            const SizedBox(height: 10),
            _UterusAnatomyCard(
              theme: theme,
              currentPhase: currentPhaseKey,
              inPregnancyMode: inPregnancyMode,
            ),
          ],
        ),
        ),
      ),
    );
  }

  // ---- Header: fecha + día del ciclo + subtítulo de ovulación, alineado a
  // la izquierda (layout original antes del experimento de "escena tipo
  // pradera"). ----
  Widget _buildHeader(
    AppStrings s,
    AppThemeOption theme,
    DateTime today,
    int? dayInCycle,
    DateTime? ovulation, {
    bool inPregnancyMode = false,
  }) {
    const months = {
      'es': ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'],
    };
    final monthNames = months['es']!;
    final dateLabel = '${today.day} ${monthNames[today.month - 1]}';

    String? subtitle;
    if (ovulation != null) {
      final daysLeft = ovulation.difference(DateTime(today.year, today.month, today.day)).inDays;
      if (daysLeft >= 0) subtitle = s.todayOvulationInDays(daysLeft);
    }

    final primaryDark = Color(theme.primaryDark);

    // En modo embarazo no hay "día de ciclo" que mostrar, así que en vez
    // del bloque de texto se muestra una fila tipo píldora con la fecha —
    // mismo lenguaje visual de la maqueta "Después" aprobada por la
    // usuaria.
    if (inPregnancyMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Icon(Icons.calendar_today, size: 16, color: primaryDark),
            const SizedBox(width: 10),
            Text(dateLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(width: 12),
            Container(width: 1, height: 18, color: AppColors.border),
            const Spacer(),
            Text(s.todayDayLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    dayInCycle != null ? '${dayInCycle + 1}' : '—',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: primaryDark, height: 1.0),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.todayDayLabel,
                    style: TextStyle(fontSize: 16, color: primaryDark, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // `light`: variante en blanco con un leve fondo oscuro semitransparente,
  // pensada para dibujarse ENCIMA de la foto del jardín (mismo criterio de
  // contraste que ya usa el "TU JARDÍN"/texto de estado de esa tarjeta, y
  // el mismo scrim que el botón redondo de "ver foto completa").
  Widget _buildPeriodEndButton(AppStrings s, AppThemeOption theme, BuildContext context, {bool light = false}) {
    final color = light ? Colors.white : Color(theme.primaryDark);
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _openTodayEditor(context),
        icon: Icon(Icons.medication_outlined, size: 18, color: color),
        label: Text(
          s.todayPeriodEnd,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: light ? Colors.black.withOpacity(0.18) : null,
          side: BorderSide(color: color, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  // Días que quedan del período actual (solo cálculo de visualización,
  // reutilizando currentDayInCycle()/getAvgPeriodLength() de
  // CyclePredictor tal cual ya existen — no toca el motor de predicción).
  // Pedido explícito de la usuaria de mostrar "cuánto queda" dentro de la
  // tarjeta del jardín. Devuelve null si no hay datos suficientes o si el
  // período calculado ya terminó.
  int? _periodDaysRemaining() {
    final dayInCycle = _predictor.currentDayInCycle();
    if (dayInCycle == null) return null;
    final remaining = _predictor.getAvgPeriodLength() - dayInCycle;
    return remaining > 0 ? remaining : null;
  }

  Widget _buildBodyStageCard(AppStrings s, AppThemeOption theme, String cycleDayLabel) {
    final phase = _predictor.currentPhaseKey();
    final stageText = switch (phase) {
      'menstrual' => s.todayStageMenstrual,
      'folicular' => s.todayStageFollicular,
      'ovulacion' => s.todayStageOvulation,
      'lutea' => s.todayStageLuteal,
      _ => null,
    };
    // Si aun no hay suficientes datos para calcular la fase (currentPhaseKey()
    // devuelve null en cuentas nuevas o sin registros), la tarjeta ya NO se
    // queda plana sin imagen — usa la ilustracion "folicular" (la mas neutra/
    // de bienvenida de las 4) como estado por defecto, para que la primera
    // impresion de la app siga siendo la tarjeta viva con foto + animacion,
    // en vez de un bloque de texto vacio invitando a "contarnos mas".
    final visual = _phaseVisuals[phase] ?? _phaseVisuals['folicular']!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: visual.glow,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        // Sombra suave a juego con el degradado de la tarjeta — le da
        // profundidad en vez de quedar plana sobre el fondo.
        boxShadow: [
          BoxShadow(
            color: visual.glow.last.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PhaseGlowImage(key: ValueKey(phase ?? 'default'), asset: visual.asset, glowColor: visual.glow.last),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.todayBodyStageHeader,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ovulation, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  stageText ?? s.todayTellUsMore,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (phase != null) ...[
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward, size: 16, color: Color(theme.primaryDark).withOpacity(0.6)),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cycleDayLabel, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(theme.primaryDark))),
                Text(
                  s.todayCycleDayHeader,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, letterSpacing: 0.3, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Tarjeta NUEVA y separada del "jardín" de la racha diaria — pedida
  // explícitamente por la usuaria encima de "Tu cuerpo hoy", que se deja
  // sin cambios. Rediseñada a pedido explícito de la usuaria ("nada de
  // anillo, la flores tiene que verse bien grande que ocupe toda la
  // tarjeta"), con una captura de otra app como referencia: ya NO es una
  // miniatura circular con halo junto a un bloque de texto — ahora la
  // imagen de la etapa del jardín ocupa toda la tarjeta de lado a lado
  // (estilo "banner"), con el texto superpuesto abajo sobre un degradado
  // oscuro para que siga siendo legible.
  Widget _buildGardenCard(
    AppStrings s,
    AppThemeOption theme,
    BuildContext context,
    bool isPeriodToday, {
    bool inPregnancyMode = false,
  }) {
    // Con el embarazo activo, la etapa se fija siempre en la floración
    // máxima (la más bonita) en vez de calcularse por la racha de días
    // abiertos — pedido explícito de la usuaria: quiere ver "tu jardín"
    // durante el embarazo, pero que no se seque ni se vea feo.
    final gardenStage =
        inPregnancyMode ? gardenStageAssets.length - 1 : gardenStageIndex(AppOpenController.instance.openDates);
    final asset = gardenStageAssets[gardenStage.clamp(0, gardenStageAssets.length - 1)];
    // Solo se calcula/muestra cuando hoy es día de período (pedido de la
    // usuaria: la info de "cuánto queda" vive en la tarjeta del jardín) —
    // y nunca durante el embarazo, donde no hay período que contar.
    final daysLeft = (!inPregnancyMode && isPeriodToday) ? _periodDaysRemaining() : null;
    final stageText = switch (gardenStage) {
      0 => s.todayGardenStageDead,
      1 => s.todayGardenStageWilting,
      2 => s.todayGardenStageNormal,
      3 => s.todayGardenStageHealthy,
      _ => s.todayGardenStageBloom,
    };

    // El toque para ver la foto completa vive en ESTE GestureDetector
    // externo (no en _GardenStageBanner) a propósito: probado en el
    // emulador que un GestureDetector con onTap Y onHorizontalDragUpdate
    // a la vez (el de _GardenStageBanner, para el efecto de deslizar) no
    // dispara onTap de forma confiable — el reconocedor de arrastre se
    // queda con el gesto incluso con movimiento mínimo. Separar el toque
    // en un GestureDetector propio, por fuera, sí funciona siempre.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openFullGardenImage(context, asset),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      // 1:0.60 (ancho:alto) — la tarjeta muestra el 60% de la altura de la
      // imagen cuadrada (480×480), recortada con BoxFit.cover. Antes era
      // 50% ("cortalo a la mitad"), luego 65% ("que sea un 65%"); la
      // usuaria bajó un poco ese último valor: "prefiero que sea 60%".
      child: AspectRatio(
        aspectRatio: 1 / 0.60,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _GardenStageBanner(key: ValueKey('garden_banner_$gardenStage'), asset: asset),
            // Degradado oscuro solo en la parte de abajo, para que el
            // texto se lea bien sobre cualquier imagen sin tapar la flor.
            // Se deja siempre visible (no se desvanece) porque el botón
            // "Fin del período" y "cuánto queda" siguen necesitándolo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Color(0xB3143314)],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pedido explícito de la usuaria: SOLO el encabezado y
                  // el texto de la etapa ("TU JARDÍN" + "Tus flores están
                  // en plena floración...") se quedan 20 segundos en
                  // pantalla y luego se desvanecen — "cuánto queda" y el
                  // botón "Fin del período" (más abajo, fuera de este
                  // overlay) se quedan siempre visibles. Se reinicia
                  // (otros 20s) cada vez que cambia la etapa del jardín,
                  // gracias a la key con [gardenStage].
                  _GardenCaptionOverlay(
                    key: ValueKey('garden_caption_$gardenStage'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.todayGardenHeader,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stageText,
                          style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  // "Cuánto queda" del período — solo mientras hoy es día
                  // de período (pedido explícito de la usuaria), y se
                  // queda siempre visible (no se desvanece con lo de
                  // arriba).
                  if (daysLeft != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          s.todayGardenDaysLeft(daysLeft),
                          style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  // Botón "Fin del período" integrado en la tarjeta del
                  // jardín ("la caseta") en vez de suelto arriba — pedido
                  // explícito de la usuaria. Sigue siendo condicional a
                  // isPeriodToday, exactamente igual que antes, y nunca
                  // durante el embarazo (no hay período que finalizar).
                  // Se queda siempre visible (no se desvanece).
                  if (!inPregnancyMode && isPeriodToday) ...[
                    const SizedBox(height: 10),
                    _buildPeriodEndButton(s, theme, context, light: true),
                  ],
                ],
              ),
            ),
            // Pista visual de que se puede tocar para ver la foto
            // completa (la tarjeta la recorta para llenar el cuadro).
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_full, size: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // Abre la foto del jardín a pantalla completa (fondo negro, con zoom vía
  // InteractiveViewer) cuando la usuaria toca la tarjeta "Tu jardín" — la
  // tarjeta recorta la foto con BoxFit.cover para llenar el cuadro, así
  // que quien quiera verla entera solo tiene que tocarla. Mismo patrón ya
  // usado para "Tu bebé" en el Simulacro (ver _openFullImage en
  // pregnancy_simulator_screen.dart).
  void _openFullGardenImage(BuildContext context, String assetPath) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.95),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 6,
                        child: _FullGardenImage(asset: assetPath),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Tarjeta de embarazo con la foto real del bebé del día (misma imagen
  // que usa PregnancyTrackingScreen, vía pregnancyDayImagePath), en vez
  // del bloque de solo texto que había antes. Es lo primero que ve la
  // usuaria en Hoy cuando el modo embarazo está activo.
  Widget _buildPregnancyCard(AppStrings s, BuildContext context) {
    final lmp = pregnancy.lmp;
    String weekText = '—';
    String subText = s.pregnancySetLmpHint;
    int daysSince = 0;
    double progress = 0.0;
    if (lmp != null) {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final rawDaysSince = todayMidnight.difference(DateTime(lmp.year, lmp.month, lmp.day)).inDays;
      daysSince = rawDaysSince < 0 ? 0 : rawDaysSince;
      // Misma duración total (37/259 con mellizos, 40/280 embarazo único) y
      // mismo margen de "postérmino" (+2 semanas) que PregnancyTrackingScreen
      // — evita mostrar semanas absurdas con una FUM vieja u olvidada.
      final totalDays = pregnancy.isTwins ? 259 : 280;
      final capDays = totalDays + 7;
      // +1: misma corrección que en PregnancyTrackingScreen — "semana"
      // 1-indexada (el día 0 desde la FUM es "semana 1", no "semana 0").
      // Antes esta tarjeta de "Hoy" mostraba "Semana 0" el primer día y se
      // quedaba una semana por detrás de PregnancyTrackingScreen el resto
      // del embarazo. Bug reportado en la auditoría previa a publicación.
      final weeks = ((daysSince > capDays ? capDays : daysSince) / 7).floor() + 1;
      final dueDate = lmp.add(Duration(days: totalDays));
      weekText = '$weeks';
      subText = s.pregnancyDueDate('${dueDate.day}/${dueDate.month}/${dueDate.year}');
      // Fracción de progreso del embarazo, para el anillo alrededor de la
      // foto — mismo lenguaje visual de la maqueta "Después".
      progress = (daysSince / totalDays).clamp(0.0, 1.0);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: lmp == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PregnancyTrackingScreen(lmp: lmp, themeId: themeId, isTwins: pregnancy.isTwins),
                ),
              ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Antes llevaba un degradado amarillo/naranja plano; ahora un
          // fondo crema muy suave, a juego con la maqueta "Después"
          // aprobada por la usuaria, con anillo de progreso + puntos +
          // botón de flecha en vez del bloque de solo texto.
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7EC), Color(0xFFFDE9EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.16),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(right: -14, top: -18, child: _leafDecor(size: 58, angle: 0.5, color: AppColors.primary.withOpacity(0.08))),
              Positioned(left: -10, bottom: -16, child: _leafDecor(size: 46, angle: -0.6, color: AppColors.primaryDark.withOpacity(0.07))),
              Padding(
                // Tarjeta grande más compacta (menos relleno) para
                // compensar el círculo del bebé más grande — el círculo en
                // sí (SizedBox/CustomPaint/Image de arriba) no se toca.
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lmp != null)
                  SizedBox(
                    // Se agranda el círculo/anillo con la foto del bebé (antes
                    // 116x116) sin tocar el tamaño de la tarjeta grande que
                    // muestra "SEMANAS DE EMBARAZO" — esa tarjeta no tiene
                    // alto fijo, así que simplemente se hace un poco más alta
                    // para acomodar el círculo más grande.
                    width: 148,
                    height: 148,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(148, 148),
                          painter: _PregnancyRingPainter(progress: progress, color: AppColors.primaryDark),
                        ),
                        ClipOval(
                          child: Image.asset(
                            pregnancyDayImagePath(daysSince),
                            width: 132,
                            height: 132,
                            fit: BoxFit.cover,
                            // Mismo respaldo que en PregnancyTrackingScreen: si
                            // falla la decodificación, un ícono en vez de nada.
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('pregnancyDayImagePath fallo al cargar: $error');
                              return Container(
                                color: AppColors.primaryDark.withOpacity(0.08),
                                alignment: Alignment.center,
                                child: Icon(Icons.pregnant_woman, size: 48, color: AppColors.primaryDark.withOpacity(0.7)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (lmp != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: lmp != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: lmp != null ? MainAxisAlignment.start : MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(weekText, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              s.pregnancyWeeksLabel,
                              style: const TextStyle(fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subText,
                        style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                        textAlign: lmp != null ? TextAlign.start : TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (lmp != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 12),
                  ),
                ],
              ),
            ],
          ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildOvulationCard(
    AppStrings s,
    AppThemeOption theme,
    DateTime ovulation,
    bool isFertileToday,
    bool tryingToConceive,
  ) {
    final cycleLen = _predictor.getAvgCycleLength();
    final periodLen = _predictor.getAvgPeriodLength();
    final dayInCycle = _predictor.currentDayInCycle() ?? 0;
    final ovulationLabel = '${ovulation.day}/${ovulation.month}/${ovulation.year}';

    // Segmentos del slider visual, como fracción del ciclo completo:
    // rosa = período (día 0 al final del sangrado), amarillo/naranja =
    // ventana fértil (5 días antes de la ovulación + el día de ovulación,
    // mismo criterio que CyclePredictor.predict() usa para fertileDates),
    // gris claro = el resto del ciclo. Todo con los colores ya definidos en
    // AppColors, sin inventar ninguno nuevo. El índice de la ovulación
    // dentro del ciclo se deriva de "hoy": dayInCycle ya es la posición de
    // hoy, y (ovulation - hoy).inDays es cuántos días faltan/pasaron, así
    // que sumados dan la posición de la ovulación en el mismo eje.
    final today0 = DateTime.now();
    final todayMidnight = DateTime(today0.year, today0.month, today0.day);
    final ovulationDayIndex = dayInCycle + ovulation.difference(todayMidnight).inDays;
    // Fecha del primer día del ciclo actual, derivada de "hoy - dayInCycle
    // días" — equivalente a leer el inicio real del ciclo, pero sin
    // necesitar acceso al parseo privado de claves de CyclePredictor.
    final cycleStartDate = todayMidnight.subtract(Duration(days: dayInCycle));
    // Fase actual, para el dibujo anatómico que reemplaza al punto de
    // color plano de la leyenda "Etapa corporal" (pedido explícito de la
    // usuaria) — mismo cálculo ya usado en _buildBodyStageCard, sin
    // duplicar lógica nueva.
    final phaseKey = _predictor.currentPhaseKey();

    return _OvulationSliderCard(
      s: s,
      theme: theme,
      cycleLen: cycleLen,
      periodLen: periodLen,
      todayDayInCycle: dayInCycle,
      ovulationDayIndex: ovulationDayIndex,
      cycleStartDate: cycleStartDate,
      ovulationLabel: ovulationLabel,
      isFertileToday: isFertileToday,
      tryingToConceive: tryingToConceive,
      phaseKey: phaseKey,
    );
  }

  Widget _buildHowDoYouFeelCard(AppStrings s, AppThemeOption theme, BuildContext context) {
    final primary = Color(theme.primary);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        // Antes llevaba un borde plano (AppColors.border); ahora una sombra
        // suave le da la misma sensación de "tarjeta elevada" del resto del
        // rediseño, en vez de un contorno.
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(right: -12, bottom: -16, child: _leafDecor(size: 52, angle: -0.5, color: primary.withOpacity(0.07))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: primary.withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(Icons.sentiment_satisfied_alt_outlined, size: 18, color: primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.todayHowDoYouFeel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(s.todayTellUsMore, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.35)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openTodayEditor(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(s.todayAddSymptom, style: const TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 6,
                        shadowColor: primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta de "diversión" pedida por la usuaria para llenar el espacio
  // libre que quedó debajo de "¿Cómo te sientes hoy?" tras compactar el
  // resto de tarjetas — un dato curioso / frase ligera distinta cada día
  // (puramente decorativa, sin tocar datos ni lógica real de la app), en
  // el mismo lenguaje visual de tarjeta blanca elevada del resto de Hoy.
  //
  // Pedido posterior ("que haga bien la diferencia con los 3 objetivos"):
  // el dato ya no es el mismo texto genérico sin importar el objetivo —
  // ahora se elige la lista de datos según `tryingToConceive`/
  // `inPregnancyMode` (mismas banderas que ya usa el resto de Hoy para
  // diferenciar Seguir mi período / Intentar concebir / Seguir mi
  // embarazo), así que el contenido es relevante en cada caso:
  // fertilidad/ventana fértil para "concebir", desarrollo del bebé para
  // "embarazo", y bienestar/ciclo general para "período".
  //
  // Pedido también ("que este siempre en buena condición" = que el texto
  // nunca se corte): ambos Text de abajo NO llevan maxLines/overflow —
  // se dejan crecer y ajustar líneas libremente (softWrap explícito) para
  // que ninguna traducción, por larga que sea, quede truncada.
  Widget _buildFunFactCard(
    AppStrings s,
    AppThemeOption theme, {
    required bool tryingToConceive,
    required bool inPregnancyMode,
  }) {
    final funFacts = inPregnancyMode
        ? s.todayFunFactsPregnancy
        : tryingToConceive
            ? s.todayFunFactsFertility
            : s.todayFunFacts;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final fact = funFacts[dayOfYear % funFacts.length];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(right: -14, top: -18, child: _leafDecor(size: 54, angle: 0.4, color: Color(theme.primary).withOpacity(0.08))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Color(theme.primary).withOpacity(0.12), shape: BoxShape.circle),
                    child: const Center(child: Text('✨', style: TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.todayFunFactLabel,
                          softWrap: true,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ovulation, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fact,
                          softWrap: true,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frases ligeras/curiosas que rotan a diario en la tarjeta "Dato curioso
/// del día" de la pestaña Hoy — contenido puramente decorativo, pensado
/// para dar un toque ameno, no información médica. El texto real vive en
/// `AppStrings.todayFunFacts` (traducido a los 9 idiomas de la app) para
/// que cambie junto con el idioma elegido en Configuración.

/// Punto de interés anatómico sobre la ilustración del útero: posición
/// relativa (0.0–1.0) sobre la imagen y una clave (`key`) que identifica
/// el texto educativo general (fijo, no depende de los datos reales del
/// ciclo de la usuaria). El texto en sí vive en `AppStrings` (métodos
/// `hotspotTitleXxx`/`hotspotDescriptionXxx`, ver [_hotspotTitle] y
/// [_hotspotDescription] más abajo) para que se traduzca con el idioma.
class _AnatomyHotspot {
  final String key;
  final double dx;
  final double dy;

  const _AnatomyHotspot({
    required this.key,
    required this.dx,
    required this.dy,
  });
}

const List<_AnatomyHotspot> _uterusHotspots = [
  _AnatomyHotspot(key: 'ovarios', dx: 0.145, dy: 0.30),
  _AnatomyHotspot(key: 'trompas', dx: 0.27, dy: 0.14),
  _AnatomyHotspot(key: 'endometrio', dx: 0.50, dy: 0.40),
  _AnatomyHotspot(key: 'miometrio', dx: 0.31, dy: 0.53),
  _AnatomyHotspot(key: 'cervix', dx: 0.50, dy: 0.85),
];

/// Traduce la clave de un [_AnatomyHotspot] a su título según el idioma
/// actual de la app.
String _hotspotTitle(AppStrings s, String key) {
  switch (key) {
    case 'ovarios':
      return s.hotspotTitleOvarios;
    case 'trompas':
      return s.hotspotTitleTrompas;
    case 'endometrio':
      return s.hotspotTitleEndometrio;
    case 'miometrio':
      return s.hotspotTitleMiometrio;
    case 'cervix':
      return s.hotspotTitleCervix;
    default:
      return '';
  }
}

/// Igual que [_hotspotTitle] pero para la descripción educativa.
String _hotspotDescription(AppStrings s, String key) {
  switch (key) {
    case 'ovarios':
      return s.hotspotDescriptionOvarios;
    case 'trompas':
      return s.hotspotDescriptionTrompas;
    case 'endometrio':
      return s.hotspotDescriptionEndometrio;
    case 'miometrio':
      return s.hotspotDescriptionMiometrio;
    case 'cervix':
      return s.hotspotDescriptionCervix;
    default:
      return '';
  }
}

/// Texto/punto destacado automáticamente en la tarjeta de anatomía según
/// la fase de ciclo (o embarazo) ya calculada en otras tarjetas de esta
/// misma pantalla — solo LEE ese resultado para decidir qué parte resaltar
/// y qué frase mostrar por defecto; no añade ningún cálculo nuevo sobre
/// los datos de la usuaria.
class _PhaseAnatomyInfo {
  final int hotspotIndex;
  final String label;
  final String description;
  final String shortName;
  const _PhaseAnatomyInfo({
    required this.hotspotIndex,
    required this.label,
    required this.description,
    required this.shortName,
  });
}

_PhaseAnatomyInfo? _currentPhaseAnatomyInfo(AppStrings s, {required String? phase, required bool inPregnancyMode}) {
  if (inPregnancyMode) {
    return _PhaseAnatomyInfo(
      hotspotIndex: 2,
      label: s.phaseLabelPregnancy,
      shortName: s.phaseShortNamePregnancy,
      description: s.phaseDescriptionPregnancy,
    );
  }
  switch (phase) {
    case 'menstrual':
      return _PhaseAnatomyInfo(
        hotspotIndex: 2,
        label: s.phaseLabelMenstrual,
        shortName: s.phaseShortNameMenstrual,
        description: s.phaseDescriptionMenstrual,
      );
    case 'folicular':
      return _PhaseAnatomyInfo(
        hotspotIndex: 0,
        label: s.phaseLabelFolicular,
        shortName: s.phaseShortNameFolicular,
        description: s.phaseDescriptionFolicular,
      );
    case 'ovulacion':
      return _PhaseAnatomyInfo(
        hotspotIndex: 0,
        label: s.phaseLabelOvulacion,
        shortName: s.phaseShortNameOvulacion,
        description: s.phaseDescriptionOvulacion,
      );
    case 'lutea':
      return _PhaseAnatomyInfo(
        hotspotIndex: 2,
        label: s.phaseLabelLutea,
        shortName: s.phaseShortNameLutea,
        description: s.phaseDescriptionLutea,
      );
    default:
      return null;
  }
}

/// Orden natural de las fases del ciclo, usado solo para calcular cuál es
/// la fase "siguiente" a la actual y así animar hacia dónde va el ciclo —
/// no recalcula ninguna fecha ni dato real, solo ordena las mismas claves
/// que ya calcula el predictor existente.
const List<String> _cyclePhaseOrder = ['menstrual', 'folicular', 'ovulacion', 'lutea'];

_PhaseAnatomyInfo? _nextPhaseAnatomyInfo(AppStrings s, String? currentPhase) {
  if (currentPhase == null) return null;
  final idx = _cyclePhaseOrder.indexOf(currentPhase);
  if (idx == -1) return null;
  final nextKey = _cyclePhaseOrder[(idx + 1) % _cyclePhaseOrder.length];
  return _currentPhaseAnatomyInfo(s, phase: nextKey, inPregnancyMode: false);
}

/// Tarjeta "Explora tu anatomía": ilustración médica realista del útero
/// (imagen estática) que la usuaria puede "mover" arrastrando con el dedo
/// o el ratón (efecto de inclinación 3D vía Matrix4) o con flechas. Al
/// abrir la tarjeta se resalta automáticamente la parte relacionada con
/// la fase actual del ciclo (o el embarazo) con una frase sobre lo que
/// pasa "ahora mismo"; si la usuaria toca otro punto o usa las flechas,
/// pasa a exploración libre con las explicaciones fijas de anatomía
/// general de cada parte, y puede volver a ver su estado actual con el
/// enlace de abajo.
class _UterusAnatomyCard extends StatefulWidget {
  final AppThemeOption theme;
  final String? currentPhase;
  final bool inPregnancyMode;
  const _UterusAnatomyCard({
    required this.theme,
    this.currentPhase,
    this.inPregnancyMode = false,
  });

  @override
  State<_UterusAnatomyCard> createState() => _UterusAnatomyCardState();
}

class _UterusAnatomyCardState extends State<_UterusAnatomyCard> with SingleTickerProviderStateMixin {
  // Colapsada por defecto: mientras no se activa, ni se construye la
  // ilustración ni corre ninguna animación — así la tarjeta no consume
  // batería del móvil hasta que la usuaria decide abrirla a propósito.
  bool _activated = false;
  int? _selected;
  bool _manualMode = false;
  double _tiltX = 0;
  double _tiltY = 0;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Anima, en bucle, el "latido" sobre el punto resaltado y el brillo que
    // viaja hacia la parte que corresponde a la fase siguiente del ciclo —
    // puramente decorativo, para transmitir "por dónde va" el ciclo y "qué
    // le espera" a continuación; no depende de ningún timer de datos. No
    // arranca sola: solo se pone en marcha cuando la tarjeta se activa (ver
    // _toggleActivated), para no gastar batería mientras está escondida.
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleActivated() {
    setState(() => _activated = !_activated);
    if (_activated) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
    }
  }

  void _selectByArrow(int direction) {
    setState(() {
      _manualMode = true;
      final current = _selected ?? -1;
      final next = (current + direction) % _uterusHotspots.length;
      _selected = next < 0 ? _uterusHotspots.length - 1 : next;
      _tiltY = direction * 0.14;
    });
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _tiltY = 0);
    });
  }

  Widget _buildCollapsedTeaser(Color accent, {required String subtitle, required bool highlightSubtitle}) {
    final s = AppStrings.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.16), blurRadius: 22, offset: const Offset(0, 9)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
            child: const Center(child: Text('🔬', style: TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.exploreAnatomyTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: highlightSubtitle ? accent.withOpacity(0.85) : AppColors.textMuted,
                    fontWeight: highlightSubtitle ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _toggleActivated,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
              child: Text(s.anatomyViewButton, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final accent = Color(widget.theme.primary);
    final phaseInfo = _currentPhaseAnatomyInfo(s, phase: widget.currentPhase, inPregnancyMode: widget.inPregnancyMode);

    // Colapsada: tarjeta pequeña con un botón "Ver" — no se construye la
    // imagen ni los puntos táctiles y la animación no corre, así no gasta
    // batería mientras la usuaria no pide verla. Aun así, ya adelanta en
    // qué fase está y cuál sigue, para que se vea de un vistazo sin tener
    // que abrir la tarjeta.
    if (!_activated) {
      String teaserSubtitle;
      bool highlight;
      if (phaseInfo == null) {
        teaserSubtitle = s.anatomyInteractiveModelSubtitle;
        highlight = false;
      } else if (widget.inPregnancyMode) {
        teaserSubtitle = s.anatomyNowMoment(phaseInfo.shortName);
        highlight = true;
      } else {
        final next = _nextPhaseAnatomyInfo(s, widget.currentPhase);
        teaserSubtitle = next != null
            ? s.anatomyNowAndNext(phaseInfo.shortName, next.shortName)
            : s.anatomyNow(phaseInfo.shortName);
        highlight = true;
      }
      return _buildCollapsedTeaser(accent, subtitle: teaserSubtitle, highlightSubtitle: highlight);
    }

    final bool showingPhase = !_manualMode && phaseInfo != null;
    final int? effectiveSelected = showingPhase ? phaseInfo!.hotspotIndex : _selected;
    final hotspot = effectiveSelected != null ? _uterusHotspots[effectiveSelected] : null;
    final nextPhaseInfo = showingPhase && !widget.inPregnancyMode ? _nextPhaseAnatomyInfo(s, widget.currentPhase) : null;
    final bool animateTravel = showingPhase && nextPhaseInfo != null && nextPhaseInfo.hotspotIndex != phaseInfo!.hotspotIndex;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.16), blurRadius: 22, offset: const Offset(0, 9)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
                child: const Center(child: Text('🔬', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.exploreAnatomyTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              InkWell(
                onTap: _toggleActivated,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.anatomyDragHint,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _tiltY = (_tiltY + details.delta.dx * 0.004).clamp(-0.35, 0.35);
                _tiltX = (_tiltX - details.delta.dy * 0.004).clamp(-0.35, 0.35);
              });
            },
            onPanEnd: (_) {
              setState(() {
                _tiltX = 0;
                _tiltY = 0;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0016)
                ..rotateX(_tiltX)
                ..rotateY(_tiltY),
              transformAlignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: 1000 / 663,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset('assets/decorative/utero_anatomia_3d.png', fit: BoxFit.cover),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              ...List.generate(_uterusHotspots.length, (i) {
                              final h = _uterusHotspots[i];
                              final isSelected = effectiveSelected == i;
                              final isPhaseDot = showingPhase && i == phaseInfo!.hotspotIndex;
                              return Positioned(
                                left: constraints.maxWidth * h.dx - 12,
                                top: constraints.maxHeight * h.dy - 12,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _manualMode = true;
                                    _selected = i;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isSelected ? 24 : 20,
                                    height: isSelected ? 24 : 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? accent : Colors.white,
                                      border: Border.all(color: accent, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4, offset: const Offset(0, 2)),
                                        if (isPhaseDot)
                                          BoxShadow(color: accent.withOpacity(0.45), blurRadius: 12, spreadRadius: 2),
                                      ],
                                    ),
                                    child: Center(
                                      child: isSelected
                                          ? const Icon(Icons.circle, color: Colors.white, size: 8)
                                          : Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                              }),
                              if (showingPhase)
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, _) {
                                    final t = _pulseController.value;
                                    final origin = _uterusHotspots[phaseInfo!.hotspotIndex];
                                    final originCenter = Offset(
                                      constraints.maxWidth * origin.dx,
                                      constraints.maxHeight * origin.dy,
                                    );
                                    final ringChildren = <Widget>[
                                      _phasePulseRing(center: originCenter, t: t, color: accent),
                                    ];
                                    if (animateTravel) {
                                      final target = _uterusHotspots[nextPhaseInfo!.hotspotIndex];
                                      final targetCenter = Offset(
                                        constraints.maxWidth * target.dx,
                                        constraints.maxHeight * target.dy,
                                      );
                                      ringChildren.add(
                                        _phaseTravelDot(from: originCenter, to: targetCenter, t: t, color: accent),
                                      );
                                    }
                                    return Stack(children: ringChildren);
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _anatomyArrowButton(icon: Icons.chevron_left, color: accent, onTap: () => _selectByArrow(-1)),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: showingPhase
                      ? Column(
                          key: const ValueKey('phase'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phaseInfo!.label,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.3),
                            ),
                            const SizedBox(height: 3),
                            Text(phaseInfo.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35)),
                            if (nextPhaseInfo != null) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: accent.withOpacity(0.8)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      s.anatomyNextPhaseFollows(nextPhaseInfo.shortName),
                                      style: TextStyle(fontSize: 11.5, color: accent.withOpacity(0.85), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        )
                      : hotspot == null
                          ? Text(
                              s.anatomyEmptyHint,
                              key: const ValueKey('empty'),
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.35),
                            )
                          : Column(
                              key: ValueKey(_selected),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_hotspotTitle(s, hotspot.key), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                                const SizedBox(height: 3),
                                Text(_hotspotDescription(s, hotspot.key), style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35)),
                              ],
                            ),
                ),
              ),
              const SizedBox(width: 10),
              _anatomyArrowButton(icon: Icons.chevron_right, color: accent, onTap: () => _selectByArrow(1)),
            ],
          ),
          if (_manualMode && phaseInfo != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _manualMode = false),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, size: 14, color: accent),
                  const SizedBox(width: 4),
                  Text(s.anatomyViewCurrentState, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Anillo que se expande y se desvanece en bucle sobre el punto
  /// resaltado (efecto "latido"), para que se note que ese es tu estado
  /// actual sin depender solo del color fijo.
  Widget _phasePulseRing({required Offset center, required double t, required Color color}) {
    final size = 16 + t * 28;
    final opacity = (1 - t).clamp(0.0, 1.0) * 0.55;
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(opacity), width: 2),
          ),
        ),
      ),
    );
  }

  /// Punto brillante que viaja del lugar actual hacia el de la fase que
  /// sigue, en bucle, para transmitir "hacia dónde va" el ciclo — se
  /// desvanece al inicio/fin del recorrido para que el bucle no se note.
  Widget _phaseTravelDot({required Offset from, required Offset to, required double t, required Color color}) {
    final dx = from.dx + (to.dx - from.dx) * t;
    final dy = from.dy + (to.dy - from.dy) * t;
    final opacity = math.sin(math.pi * t).clamp(0.0, 1.0);
    return Positioned(
      left: dx - 5,
      top: dy - 5,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _anatomyArrowButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// Tarjeta de ovulación con slider arrastrable: al arrastrar el marcador
/// circular horizontalmente, la fecha/día del ciclo mostrados arriba y la
/// leyenda "Alta/Media/Baja fertilidad" se recalculan para el día
/// seleccionado en vez de mostrar siempre el día de hoy fijo — mismo
/// patrón interactivo que el slider de BodyStageDetailScreen, pero
/// integrado en la tarjeta que ya vivía en la pestaña Hoy en vez de una
/// pantalla nueva.
class _OvulationSliderCard extends StatefulWidget {
  final AppStrings s;
  final AppThemeOption theme;
  final int cycleLen;
  final int periodLen;
  final int todayDayInCycle;
  final int ovulationDayIndex;
  final DateTime cycleStartDate;
  final String ovulationLabel;
  final bool isFertileToday;
  // Resalta la tarjeta (borde + insignia) cuando el objetivo elegido en
  // Configuración/Yo es "Intentar concebir" — mismo dato ya calculado,
  // solo más énfasis visual, como en otras apps de seguimiento.
  final bool tryingToConceive;
  // Fase actual del ciclo ('menstrual'|'folicular'|'ovulacion'|'lutea'),
  // para el dibujo anatómico de la leyenda "Etapa corporal" — null si aún
  // no hay datos suficientes (se usa un valor neutro por defecto al
  // dibujar, ver build()).
  final String? phaseKey;

  const _OvulationSliderCard({
    required this.s,
    required this.theme,
    required this.cycleLen,
    required this.periodLen,
    required this.todayDayInCycle,
    required this.ovulationDayIndex,
    required this.cycleStartDate,
    required this.ovulationLabel,
    required this.isFertileToday,
    this.tryingToConceive = false,
    this.phaseKey,
  });

  @override
  State<_OvulationSliderCard> createState() => _OvulationSliderCardState();
}

class _OvulationSliderCardState extends State<_OvulationSliderCard> {
  late int _selectedDayInCycle;

  @override
  void initState() {
    super.initState();
    _selectedDayInCycle = widget.todayDayInCycle;
  }

  @override
  void didUpdateWidget(covariant _OvulationSliderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambian los datos subyacentes (p. ej. se registró un nuevo día y
    // today_screen se reconstruye), solo resincronizamos la selección si
    // seguía en "hoy" — si la usuaria estaba explorando otro día del
    // slider, no le movemos el marcador de debajo sin que lo pida.
    if (oldWidget.todayDayInCycle != widget.todayDayInCycle && _selectedDayInCycle == oldWidget.todayDayInCycle) {
      _selectedDayInCycle = widget.todayDayInCycle;
    }
  }

  bool get _isToday => _selectedDayInCycle == widget.todayDayInCycle;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final theme = widget.theme;
    final cycleLen = widget.cycleLen;
    final periodLen = widget.periodLen;

    final periodFraction = cycleLen > 0 ? (periodLen / cycleLen).clamp(0.0, 1.0).toDouble() : 0.0;
    final fertileStartFraction =
        cycleLen > 0 ? ((widget.ovulationDayIndex - 5) / cycleLen).clamp(0.0, 1.0).toDouble() : 0.0;
    final fertileEndFraction =
        cycleLen > 0 ? ((widget.ovulationDayIndex + 1) / cycleLen).clamp(0.0, 1.0).toDouble() : 0.0;
    final isFertileSelected = _selectedDayInCycle >= widget.ovulationDayIndex - 5 && _selectedDayInCycle <= widget.ovulationDayIndex + 1;

    final selectedDate = widget.cycleStartDate.add(Duration(days: _selectedDayInCycle));
    final selectedDateLabel = '${selectedDate.day} ${s.monthShort(selectedDate.month)}';
    final headerLabel = _isToday
        ? widget.ovulationLabel
        : s.todayOvulationCardDateAndDay(selectedDateLabel, _selectedDayInCycle + 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: widget.tryingToConceive ? Border.all(color: AppColors.ovulation, width: 1.6) : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pedido explícito de la usuaria: el chip "Intento concebir" y la
          // fecha comparten la misma línea (antes iban en dos filas
          // separadas) — el chip se redujo un 8% (padding/ícono/texto) para
          // dejarle espacio a la fecha al lado.
          Row(
            children: [
              if (widget.tryingToConceive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9.6, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ovulation.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 11.6, color: AppColors.ovulation),
                      const SizedBox(width: 3.9),
                      Text(
                        s.meGoalTryConceive,
                        style: const TextStyle(fontSize: 10.1, fontWeight: FontWeight.w700, color: AppColors.ovulation),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.egg_alt_outlined, size: 18, color: Color(theme.primary)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headerLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const trackHeight = 10.0;
              const markerSize = 22.0;
              final width = constraints.maxWidth;
              final selectedFraction = cycleLen > 0 ? (_selectedDayInCycle / cycleLen).clamp(0.0, 1.0).toDouble() : 0.0;
              final markerX = (selectedFraction * width).clamp(markerSize / 2, width - markerSize / 2);

              void updateFromDx(double dx) {
                final clampedDx = dx.clamp(0.0, width);
                final fraction = width > 0 ? clampedDx / width : 0.0;
                final newDay = (fraction * cycleLen).round().clamp(0, cycleLen - 1);
                if (newDay != _selectedDayInCycle) {
                  setState(() => _selectedDayInCycle = newDay);
                }
              }

              // Un único GestureDetector (sin anidar otro sobre el
              // marcador) cubre toda la barra con un área de toque más
              // generosa (padding vertical), y maneja tap + arrastre con la
              // posición absoluta del dedo. El marcador visual en sí es
              // IgnorePointer para que no compita por el gesto.
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragDown: (details) => updateFromDx(details.localPosition.dx),
                  onHorizontalDragUpdate: (details) => updateFromDx(details.localPosition.dx),
                  onTapDown: (details) => updateFromDx(details.localPosition.dx),
                  child: SizedBox(
                    height: markerSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        // Barra base: gris claro (resto del ciclo).
                        ClipRRect(
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                          child: Container(height: trackHeight, color: AppColors.background),
                        ),
                        // Segmento de período (rosa), desde el inicio del ciclo.
                        if (periodFraction > 0)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: periodFraction,
                              child: ClipRRect(
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(trackHeight / 2)),
                                child: Container(height: trackHeight, color: Color(theme.primary)),
                              ),
                            ),
                          ),
                        // Segmento de ventana fértil (amarillo/naranja), alrededor
                        // de la ovulación.
                        if (fertileEndFraction > fertileStartFraction)
                          Positioned(
                            left: fertileStartFraction * width,
                            width: (fertileEndFraction - fertileStartFraction) * width,
                            child: Container(height: trackHeight, color: AppColors.fertile),
                          ),
                        // Marcador circular arrastrable en la posición del
                        // día seleccionado (hoy por defecto).
                        Positioned(
                          left: markerX - markerSize / 2,
                          child: IgnorePointer(
                            child: Container(
                              width: markerSize,
                              height: markerSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Color(theme.primaryDark), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          // Pill "Día N" indicando el día seleccionado (solo se muestra si
          // no coincide con hoy, para no duplicar información cuando el
          // marcador está en su posición por defecto).
          if (!_isToday)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(theme.primaryDark),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.todayOvulationCardDayPill(_selectedDayInCycle + 1),
                  style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          if (!_isToday) const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendBodyStage(
                phaseKey: widget.phaseKey,
                primary: Color(theme.primary),
                label: s.todayLegendBodyStage,
              ),
              _legendDot(color: AppColors.fertile, label: s.todayLegendFertile),
              _legendDot(color: AppColors.ovulation, label: s.todayLegendOvulation),
            ],
          ),
          if (_isToday && widget.isFertileToday || !_isToday && isFertileSelected) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.favorite, size: 14, color: AppColors.ovulation),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(s.todayHighFertility, style: const TextStyle(fontSize: 12, color: AppColors.ovulation, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Punto de leyenda (color + etiqueta) bajo el slider de ovulación.
  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// Igual que [_legendDot] pero para "Etapa corporal": en vez del punto
  /// de color plano dibuja el mismo esquema anatómico (útero/ovarios) que
  /// ya se usa en Revisión y Estadísticas — pedido explícito de la
  /// usuaria ("que esté dentro de etapa corporal... con gráfico") en vez
  /// de la etiqueta "Período" que había antes.
  Widget _legendBodyStage({required String? phaseKey, required Color primary, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UterusPhaseIllustration(phaseKey: phaseKey ?? 'folicular', primary: primary, size: 14),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Envoltorio táctil reutilizable: al tocar la tarjeta, esta se encoge
/// ligeramente y recupera su tamaño al soltar (con un pequeño rebote),
/// en vez de reaccionar solo con la navegación instantánea de un
/// GestureDetector plano — es la reacción visual al tap que pidió la
/// usuaria ("que reaccione") antes de abrir BodyStageDetailScreen.
/// `onTapCancel` cubre el caso de que el dedo se arrastre fuera de la
/// tarjeta tras el tapDown (p. ej. si el usuario cambia de opinión y
/// desliza para hacer scroll) — sin eso, la tarjeta se quedaría encogida.
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 1.0,
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: _onTapUp,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Tarjeta "Invitar a un socio" — deslizable horizontalmente. El color de
/// fondo/acento de la tarjeta cicla entre las 5 paletas de `kAppThemes`
/// (rosa, violeta, azul, verde, oscuro) al deslizar con el dedo, con
/// puntitos indicadores debajo — es un efecto puramente decorativo de ESTA
/// tarjeta, no cambia el tema real de la app (eso se sigue eligiendo en
/// Configuración). El contenido (avatar, corazones, botón "+", texto y CTA)
/// es igual en las 5 variantes; solo cambia el color.
class _SyncPartnerCard extends StatefulWidget {
  final AppStrings s;
  final String themeId;
  final String userId;
  final String userEmail;
  // Se reenvían tal cual a InvitePartnerScreen, que los necesita para
  // sincronizar el calendario de ciclo compartido cuando el objetivo no es
  // "Seguir mi embarazo" (ver syncCycleData en partner_service.dart).
  final String userGoal;
  final PregnancySettings pregnancy;
  final bool irregularCycleMode;
  final int? selfReportedCycleLen;
  final int? selfReportedPeriodLen;
  final Map<String, DayEntry> data;

  const _SyncPartnerCard({
    required this.s,
    required this.themeId,
    required this.userId,
    required this.userEmail,
    required this.userGoal,
    required this.pregnancy,
    required this.irregularCycleMode,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
    required this.data,
  });

  @override
  State<_SyncPartnerCard> createState() => _SyncPartnerCardState();
}

class _SyncPartnerCardState extends State<_SyncPartnerCard> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variants = kAppThemes;
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: variants.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _SyncPartnerCardContent(
              s: widget.s,
              themeId: widget.themeId,
              theme: variants[i],
              userId: widget.userId,
              userEmail: widget.userEmail,
              userGoal: widget.userGoal,
              pregnancy: widget.pregnancy,
              irregularCycleMode: widget.irregularCycleMode,
              selfReportedCycleLen: widget.selfReportedCycleLen,
              selfReportedPeriodLen: widget.selfReportedPeriodLen,
              data: widget.data,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(variants.length, (i) {
            final active = _page == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? Color(variants[i].primaryDark) : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SyncPartnerCardContent extends StatelessWidget {
  final AppStrings s;
  final String themeId;
  final AppThemeOption theme;
  final String userId;
  final String userEmail;
  final String userGoal;
  final PregnancySettings pregnancy;
  final bool irregularCycleMode;
  final int? selfReportedCycleLen;
  final int? selfReportedPeriodLen;
  final Map<String, DayEntry> data;

  const _SyncPartnerCardContent({
    required this.s,
    required this.themeId,
    required this.theme,
    required this.userId,
    required this.userEmail,
    required this.userGoal,
    required this.pregnancy,
    required this.irregularCycleMode,
    this.selfReportedCycleLen,
    this.selfReportedPeriodLen,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Color(theme.primary);
    final primaryDark = Color(theme.primaryDark);
    // Fondo pastel muy suave derivado de la paleta de esta página (en vez de
    // un color fijo): cada variante que aparece al deslizar luce "real"/
    // fotogénica, igual que con el tema activo de la app.
    final softTop = Color.lerp(primary, Colors.white, 0.82)!;
    final softBottom = Color.lerp(primaryDark, Colors.white, 0.72)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [softTop, softBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Antes era una columna centrada con avatar + botón circular +
      // texto + botón ancho debajo; ahora un layout en dos columnas
      // (ilustración de pareja a la izquierda, texto + botón a la
      // derecha) con hojitas decorativas de fondo, a juego con la
      // maqueta "Después" aprobada por la usuaria.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(right: -12, top: -16, child: _leafDecor(size: 62, angle: 0.6, color: primary.withOpacity(0.10))),
            Positioned(left: -16, bottom: -14, child: _leafDecor(size: 52, angle: -0.5, color: primaryDark.withOpacity(0.09))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildCoupleIllustration(primary, primaryDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.todaySyncPartner,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary.withOpacity(0.85), height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InvitePartnerScreen(
                                  userId: userId,
                                  userEmail: userEmail,
                                  themeId: themeId,
                                  userGoal: userGoal,
                                  pregnancy: pregnancy,
                                  irregularCycleMode: irregularCycleMode,
                                  selfReportedCycleLen: selfReportedCycleLen,
                                  selfReportedPeriodLen: selfReportedPeriodLen,
                                  data: data,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    s.todayInvitePartner,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ilustración vectorial simplificada de una pareja abrazada (sin
  // depender de ninguna imagen nueva): dos siluetas superpuestas con una
  // insignia de corazón en el punto de encuentro, en los colores de la
  // paleta activa — aproxima la ilustración de la maqueta "Después" sin
  // necesitar un asset nuevo.
  Widget _buildCoupleIllustration(Color primary, Color primaryDark) {
    // Ilustración real generada (pareja abrazada), pedida explícitamente
    // por la usuaria para que coincida con su maqueta "Después" — sustituye
    // a la silueta vectorial aproximada usada antes. La imagen concreta
    // (tono de piel de la pareja) es elegible en Configuración >
    // "Apariencia de tu pareja" vía CoupleIllustrationController; por
    // defecto se usa la variante "mixta".
    final asset = CoupleIllustrationController.instance.illustration.asset;
    return SizedBox(
      width: 92,
      height: 98,
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

/// Hojas/pétalos decorativos reales (imágenes generadas), usados como
/// acento sutil de fondo en varias tarjetas de la pestaña Hoy — mismo
/// lenguaje visual de la maqueta "Después" aprobada por la usuaria.
/// Antes de tener estas imágenes se dibujaba una hoja simple por código;
/// ahora se alterna entre las 3 variantes reales para dar variedad.
const List<String> _leafAssets = [
  'assets/decorative/leaf1.png',
  'assets/decorative/leaf2.png',
  'assets/decorative/leaf3.png',
];

Widget _leafDecor({required double size, required double angle, required Color color}) {
  // El "color" original solo se usaba para pintar la hoja vectorial; ahora
  // que la hoja es una imagen real con su propio color, se reutiliza como
  // opacidad (para mantener el mismo aspecto sutil en cada tarjeta) sin
  // tocar el tono de la ilustración.
  final asset = _leafAssets[(size * 10 + angle * 100).round().abs() % _leafAssets.length];
  return IgnorePointer(
    child: Opacity(
      opacity: color.opacity.clamp(0.35, 1.0),
      child: Transform.rotate(
        angle: angle,
        child: Image.asset(asset, width: size, height: size * 1.2, fit: BoxFit.contain),
      ),
    ),
  );
}

/// Ilustración 3D fotorrealista (render cálido tipo Pixar, generada con IA)
/// asociada a cada fase del ciclo + degradado de fondo a juego para la
/// tarjeta "Tu cuerpo hoy". Sustituye al texto plano por una imagen real,
/// pedida explícitamente por la usuaria como referencia visual ("que salga
/// como esa foto o mejor"). Las 4 imágenes se generaron con el mismo estilo
/// y composición para que el cambio de una a otra se sienta coherente.
class _PhaseVisual {
  final String asset;
  final List<Color> glow;
  const _PhaseVisual(this.asset, this.glow);
}

const Map<String, _PhaseVisual> _phaseVisuals = {
  'menstrual': _PhaseVisual('assets/cycle_phases/menstrual.jpg', [Color(0xFFFFD3D3), Color(0xFFFFAFAF)]),
  'folicular': _PhaseVisual('assets/cycle_phases/folicular.jpg', [Color(0xFFFFF1C7), Color(0xFFD3EFB8)]),
  'ovulacion': _PhaseVisual('assets/cycle_phases/ovulacion.jpg', [Color(0xFFFFE3B8), Color(0xFFAEE9DC)]),
  'lutea': _PhaseVisual('assets/cycle_phases/lutea.jpg', [Color(0xFFFFDBB8), Color(0xFFDCC6F5)]),
};

/// Foto circular de la fase actual del ciclo, con un halo de color fijo
/// detrás a juego con el degradado de la tarjeta "Tu cuerpo hoy". Sin
/// animación propia (el pulso+flotación que tenía antes se quitó — ver
/// historial); es una imagen estática dentro de un círculo con sombra de
/// color.
class _PhaseGlowImage extends StatelessWidget {
  final String asset;
  final Color glowColor;

  const _PhaseGlowImage({super.key, required this.asset, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: glowColor.withOpacity(0.38), blurRadius: 20, spreadRadius: 3),
              ],
            ),
          ),
          ClipOval(
            child: SizedBox(
              width: 58,
              height: 58,
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniatura circular de la etapa actual del "jardín" de la racha diaria
/// (ver [_gardenStageIndex]), con un halo de color fijo detrás — mismo
/// tamaño y estilo que la foto de fase que reemplaza.
///
/// Tiene dos efectos, pedidos explícitamente por la usuaria:
///
/// 1. Un "mini efecto, que se mueva un poco": una respiración lenta y
///    sutil (escala ~1.0↔1.045 cada 3.2s). A diferencia de la animación
///    de pulso+flotación que se quitó antes de la tarjeta de fase (ver
///    historial), esta es mucho más barata: es solo un Transform.scale
///    sobre un recorte de 58×58, sin repintar la imagen en sí, así que el
///    costo de batería es mínimo comparado con lo que se quitó — y aquí
///    el movimiento es el punto central del pedido ("que se sienta viva"),
///    no un adorno de más.
/// 2. Un gesto de deslizar izquierda/derecha, contenido dentro de esta
///    miniatura (no en toda la tarjeta, para no chocar con el deslizar
///    entre pestañas Hoy/Calendario/Yo): al arrastrar aparece una gota de
///    agua translúcida del lado contrario, como el ícono de "responder"
///    al deslizar un mensaje en WhatsApp, y suelta con un rebote suave de
///    vuelta al centro.
class _GardenStageThumb extends StatefulWidget {
  final int stageIndex;
  final Color glowColor;

  const _GardenStageThumb({super.key, required this.stageIndex, required this.glowColor});

  @override
  State<_GardenStageThumb> createState() => _GardenStageThumbState();
}

class _GardenStageThumbState extends State<_GardenStageThumb> with TickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  late final AnimationController _snapBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  static const double _maxDrag = 22;
  double _dragDx = 0;
  double _dragStartValue = 0;

  @override
  void dispose() {
    _breathe.dispose();
    _snapBack.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDx = (_dragDx + details.delta.dx * 0.5).clamp(-_maxDrag, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    _dragStartValue = _dragDx;
    _snapBack.removeListener(_onSnapBackTick);
    _snapBack
      ..value = 0
      ..addListener(_onSnapBackTick)
      ..forward();
  }

  void _onSnapBackTick() {
    setState(() {
      _dragDx = _dragStartValue * (1 - Curves.easeOutBack.transform(_snapBack.value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = gardenStageAssets[widget.stageIndex.clamp(0, gardenStageAssets.length - 1)];
    final dropIntensity = (_dragDx.abs() / _maxDrag).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => _onDragEnd(DragEndDetails()),
      child: SizedBox(
        width: 76,
        height: 82,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: widget.glowColor.withOpacity(0.38), blurRadius: 20, spreadRadius: 3),
                ],
              ),
            ),
            // Gota de agua translúcida, del lado contrario al que se
            // desliza (mismo lenguaje visual que "responder" en WhatsApp).
            if (dropIntensity > 0.01)
              Positioned(
                left: _dragDx > 0 ? -2 : null,
                right: _dragDx > 0 ? null : -2,
                child: Opacity(
                  opacity: dropIntensity * 0.6,
                  child: _WaterDrop(size: 14 + dropIntensity * 8),
                ),
              ),
            AnimatedBuilder(
              animation: _breathe,
              builder: (context, child) {
                final scale = 1.0 + (_breathe.value * 0.045);
                return Transform.translate(
                  offset: Offset(_dragDx, 0),
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: ClipOval(
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Image.asset(asset, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Imagen de la etapa del jardín a pantalla completa dentro de la tarjeta
/// "Tu jardín" — reemplaza a [_GardenStageThumb] en esa tarjeta a pedido
/// explícito de la usuaria: "nada de anillo, la flores tiene que verse
/// bien grande que ocupe toda la tarjeta" (con una captura de otra app
/// como referencia). Sin círculo, sin halo/sombra de color: es solo la
/// imagen en BoxFit.cover llenando el Stack de la tarjeta. Conserva los
/// mismos dos efectos que [_GardenStageThumb] (respiración lenta +
/// deslizar para ver la gota de agua translúcida), ahora aplicados a la
/// imagen completa en vez de a una miniatura.
// Envuelve el encabezado + texto de etapa de la tarjeta "Tu jardín" para
// que se desvanezcan automáticamente 20 segundos después de aparecer
// (pedido explícito de la usuaria) — el "cuánto queda" y el botón "Fin
// del período" viven FUERA de este widget y por eso no se ven afectados.
// La key en el sitio de uso (con [gardenStage]) hace que este State se
// recree — y por lo tanto el temporizador se reinicie — cada vez que
// cambia la etapa del jardín.
class _GardenCaptionOverlay extends StatefulWidget {
  final Widget child;

  const _GardenCaptionOverlay({super.key, required this.child});

  @override
  State<_GardenCaptionOverlay> createState() => _GardenCaptionOverlayState();
}

class _GardenCaptionOverlayState extends State<_GardenCaptionOverlay> {
  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _hideTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _GardenStageBanner extends StatefulWidget {
  final String asset;

  const _GardenStageBanner({super.key, required this.asset});

  @override
  State<_GardenStageBanner> createState() => _GardenStageBannerState();
}

class _GardenStageBannerState extends State<_GardenStageBanner> with TickerProviderStateMixin {
  late final AnimationController _snapBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  // "Respiración" lenta y sutil pedida por la usuaria ("quiero que las
  // flores se muevan y efecto lento"): un zoom suave de ida y vuelta, muy
  // lento (20s el ciclo completo). A diferencia del zoom que se probó
  // antes y no gustó ("la parte alrededor no quiero que se vea borrosa"),
  // este NO agranda un fondo borroso alrededor — escala la misma foto
  // nítida que ya llena el marco entero (BoxFit.cover), y el ClipRect de
  // más abajo recorta cualquier borde que se pase, así que nunca aparece
  // desenfoque ni un borde distinto alrededor.
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat(reverse: true);

  // Segundo efecto de movimiento pedido por la usuaria ("el jardín de las
  // flores no se mueve"): la respiración de arriba es muy sutil (solo 6%
  // de escala), así que se añade este brillo de motitas/pétalos flotando
  // hacia arriba, en bucle continuo (sin reverse) — mucho más notorio a
  // simple vista que el zoom, sin tocar la imagen en sí (se dibuja aparte
  // con CustomPaint, así que nunca introduce desenfoque ni recorta la foto).
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  static const double _maxDrag = 26;
  double _dragDx = 0;
  double _dragStartValue = 0;

  @override
  void dispose() {
    _snapBack.dispose();
    _breathe.dispose();
    _drift.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDx = (_dragDx + details.delta.dx * 0.5).clamp(-_maxDrag, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    _dragStartValue = _dragDx;
    _snapBack.removeListener(_onSnapBackTick);
    _snapBack
      ..value = 0
      ..addListener(_onSnapBackTick)
      ..forward();
  }

  void _onSnapBackTick() {
    setState(() {
      _dragDx = _dragStartValue * (1 - Curves.easeOutBack.transform(_snapBack.value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final dropIntensity = (_dragDx.abs() / _maxDrag).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => _onDragEnd(DragEndDetails()),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // Recorte nítido de lado a lado, sin desenfoque alrededor (la
            // usuaria probó antes un zoom con fondo borroso y no le gustó
            // ese borde: "la parte alrededor no quiero que se vea
            // borrosa"). La "respiración" lenta de _breathe evita ese
            // problema porque escala la MISMA foto que ya llena el marco
            // (BoxFit.cover) — nunca aparece un borde ni fondo distinto,
            // el ClipRect de arriba recorta cualquier sobra.
            Transform.translate(
              offset: Offset(_dragDx, 0),
              // Alineación sesgada hacia arriba (no Alignment.center): al
              // pasar del 50% al 65%/60% de alto, lo que se revela de más
              // debe verse arriba (las flores más altas), no repartido
              // igual arriba y abajo.
              child: AnimatedBuilder(
                animation: _breathe,
                builder: (context, child) {
                  final scale = 1.0 + Curves.easeInOut.transform(_breathe.value) * 0.06;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Image.asset(widget.asset, fit: BoxFit.cover, alignment: const Alignment(0, -0.5)),
              ),
            ),
            // Motitas/pétalos flotando hacia arriba — el movimiento
            // "grande" y constante que pidió la usuaria, encima de la
            // foto pero sin afectarla (IgnorePointer: no compite con el
            // gesto de deslizar de arriba).
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _drift,
                  builder: (context, child) => CustomPaint(painter: _FloatingPetalsPainter(t: _drift.value)),
                ),
              ),
            ),
            if (dropIntensity > 0.01)
              Positioned(
                left: _dragDx > 0 ? 10 : null,
                right: _dragDx > 0 ? null : 10,
                child: Opacity(
                  opacity: dropIntensity * 0.7,
                  child: _WaterDrop(size: 22 + dropIntensity * 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Foto del jardín a pantalla completa (dentro de [_openFullGardenImage]),
/// con el mismo movimiento que ya tiene la tarjeta "Tu jardín" en vez de
/// una foto congelada — pedido explícito de la usuaria: "cuando se ponga
/// la foto entero que haya de jardín que también haya efecto de
/// movimiento de las flores". Reutiliza los mismos dos efectos que
/// [_GardenStageBanner] (respiración lenta + pétalos flotando), pero con
/// BoxFit.contain en vez de cover (aquí se ve la foto entera, sin
/// recortar) y sin el gesto de deslizar (esta vista ya usa el arrastre
/// para el zoom de [InteractiveViewer]).
class _FullGardenImage extends StatefulWidget {
  final String asset;
  const _FullGardenImage({required this.asset});

  @override
  State<_FullGardenImage> createState() => _FullGardenImageState();
}

class _FullGardenImageState extends State<_FullGardenImage> with TickerProviderStateMixin {
  // Duraciones alargadas a pedido del usuario ("que vaya muy despacio el
  // efecto") — antes 10s/7s, ahora mucho más lento.
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat(reverse: true);

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void dispose() {
    _breathe.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _breathe,
          builder: (context, child) {
            final scale = 1.0 + Curves.easeInOut.transform(_breathe.value) * 0.06;
            return Transform.scale(scale: scale, child: child);
          },
          child: Image.asset(widget.asset, fit: BoxFit.contain),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) => CustomPaint(painter: _FloatingPetalsPainter(t: _drift.value)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Forma simple de gota de agua (círculo con una punta arriba), usada
/// como efecto translúcido al deslizar [_GardenStageThumb] y [_GardenStageBanner].
class _WaterDrop extends StatelessWidget {
  final double size;
  const _WaterDrop({required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(size, size * 1.3),
        painter: _WaterDropPainter(),
      ),
    );
  }
}

/// Motitas de luz/pétalos que suben lentamente desde abajo y se desvanecen
/// cerca de arriba, en bucle continuo — el efecto de movimiento "grande"
/// que pidió la usuaria para la tarjeta "Tu jardín" (la respiración de
/// [_GardenStageBannerState._breathe] es demasiado sutil por sí sola).
/// Posiciones base fijas (semilla constante) para que no "salten" de
/// lugar entre reconstrucciones del widget — solo su altura y opacidad
/// avanzan con [t] (0.0-1.0, un ciclo completo de [_drift]).
class _FloatingPetalsPainter extends CustomPainter {
  final double t;
  const _FloatingPetalsPainter({required this.t});

  static const _count = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < _count; i++) {
      final baseX = rnd.nextDouble();
      final radius = 2.0 + rnd.nextDouble() * 2.2;
      // Cada motita sube con un desfase distinto (i / _count) para que no
      // suban todas a la vez, como copos dispersos en el tiempo.
      final localT = (t + i / _count) % 1.0;
      final dy = size.height * (1 - localT);
      final sway = math.sin((localT * 2 * math.pi) + i) * 9;
      // Aparece y se desvanece dentro de su propio recorrido (0 al subir
      // desde abajo, máximo a mitad de camino, 0 otra vez cerca de arriba).
      final opacity = math.sin(localT * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(baseX * size.width + sway, dy),
        radius,
        Paint()..color = Colors.white.withOpacity(0.5 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingPetalsPainter oldDelegate) => oldDelegate.t != t;
}

class _WaterDropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.85), const Color(0xFFBEE7FF).withOpacity(0.55)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..quadraticBezierTo(size.width, size.height * 0.55, size.width / 2, size.height)
      ..quadraticBezierTo(0, size.height * 0.55, size.width / 2, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) => false;
}

/// Anillo de progreso alrededor de la foto del embarazo (fracción de días
/// transcurridos sobre el total), a juego con la maqueta "Después"
/// aprobada por la usuaria — antes la foto no llevaba ningún indicador.
class _PregnancyRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _PregnancyRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const startAngle = -1.5707963267948966; // -pi/2: empieza arriba del todo
    final sweepAngle = 6.283185307179586 * progress; // 2*pi * progreso
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _PregnancyRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
