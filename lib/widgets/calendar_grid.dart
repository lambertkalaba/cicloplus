import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/day_entry.dart';
import '../services/calendar_style_controller.dart';
import '../services/cycle_predictor.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Tipo de rango al que pertenece un día del calendario, usado para
/// decidir el color de la cápsula y si se conecta con sus vecinos.
enum _DayKind { none, period, predicted, fertile, ovulation }

/// Icono pequeño + color mostrado debajo del número del día para indicar
/// una categoría puntual (vida sexual, método anticonceptivo, cita/
/// recordatorio) — reemplaza el punto genérico anterior; ver `hidden
/// LegendCategories` en `CalendarGrid.build` para el filtro de privacidad.
///
/// `halfHeart`: caso especial para "sexo con protección" — pedido
/// explícito de la usuaria de diferenciarlo del corazón COMPLETO de "sexo
/// sin protección" con un corazón A LA MITAD (en vez del escudo genérico
/// que se usaba antes), para que de un vistazo se note cuál de los dos fue.
/// Cuando es `true`, `icon` no se usa — se pinta con `_HalfHeartIcon`.
class _DayIndicator {
  final IconData icon;
  final Color color;
  final bool halfHeart;
  const _DayIndicator(this.icon, this.color, {this.halfHeart = false});
}

/// Corazón "a la mitad": un corazón contorneado completo (`favorite_border`)
/// con la mitad izquierda rellena encima (`favorite` recortado al 50% del
/// ancho) — misma técnica que las calificaciones de media estrella.
class _HalfHeartIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _HalfHeartIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.favorite_border, size: size, color: color),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Icon(Icons.favorite, size: size, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paleta pastel "vieja" del calendario — se conserva pública porque
/// `review_screen.dart` todavía pinta con estos tonos en un par de sitios
/// legados fuera de este widget. El diseño aprobado en v0 (colores EXACTOS)
/// vive ahora en `CalendarPhaseColors` (theme/app_theme.dart) y es lo que
/// usa este archivo.
class CalendarPastel {
  static const periodBg = Color(0xFFF3AFC6);
  static const periodFg = Color(0xFF7A2E49);
  static const predictedBg = Color(0xFFFBD9E6);
  static const predictedFg = Color(0xFF9C5A75);
  static const fertileBg = Color(0xFFDDD3F8);
  static const fertileFg = Color(0xFF5B4A8A);
  static const ovulationBg = Color(0xFFC9B8F5);
  static const ovulationFg = Color(0xFF4A3A7A);
}

/// Colores (fondo, texto, borde opcional) para cada tipo de día según el
/// diseño aprobado. `null` significa "sin fondo" (día normal).
///
/// `borderColor` ya no dibuja siempre un trazo PUNTEADO (antes se pintaba
/// con `_DashedPillBorderPainter`) — desde que "Forma"/"Relleno" son
/// elegibles por la usuaria (ver `CalendarStyleController.markerShape`/
/// `markerFill`), este color se usa como borde SÓLIDO normal de
/// `BoxDecoration`, tanto para el contorno suave de previsto/fértil en
/// modo "Con relleno" como para el contorno completo de cualquier
/// categoría en modo "Sin relleno".
class _PillColors {
  final Color background;
  final Color foreground;
  final Color? borderColor;
  const _PillColors(this.background, this.foreground, {this.borderColor});
}

_PillColors? _pillColors(_DayKind kind) {
  // Ya no son `const` porque CalendarPhaseColors.periodFill (y el resto de
  // colores de fase) leen en vivo la paleta elegida en Configuración —
  // ver comentario en theme/app_theme.dart.
  switch (kind) {
    case _DayKind.period:
      return _PillColors(CalendarPhaseColors.periodFill, CalendarPhaseColors.periodText);
    case _DayKind.predicted:
      return _PillColors(
        CalendarPhaseColors.predictedFill,
        CalendarPhaseColors.predictedText,
        borderColor: CalendarPhaseColors.predictedBorder,
      );
    case _DayKind.fertile:
      return _PillColors(
        CalendarPhaseColors.fertileFill,
        CalendarPhaseColors.fertileText,
        borderColor: CalendarPhaseColors.fertileBorder,
      );
    case _DayKind.ovulation:
      return _PillColors(CalendarPhaseColors.ovulationFill, CalendarPhaseColors.ovulationText);
    case _DayKind.none:
      return null;
  }
}

/// Calendario mensual con navegación y pintado de días según estado
/// (periodo registrado, predicción, ventana fértil, ovulación).
///
/// Rediseño fiel al prototipo v0 aprobado: selector de mes/año en dos
/// píldoras + botón "Hoy", fondo pastel lavanda, cápsulas de fase con
/// colores exactos (bordes punteados en previsto/fértil), y día
/// seleccionado/hoy como círculo morado sólido.
class CalendarGrid extends StatelessWidget {
  final DateTime viewMonth;
  final DateTime selectedDate;
  final Map<String, DayEntry> data;
  final CyclePrediction prediction;
  // Citas médicas programadas (tanto desde Configuración como desde la
  // vista de día futuro) — se usan solo para saber en qué días mostrar la
  // campana 🔔, no para ningún otro cálculo de este widget.
  final List<MedicalAppointment> appointments;
  // Ids de CalendarLegendCategory que la usuaria desactivó en el panel
  // "Leyenda" — el icono correspondiente deja de pintarse en cada día
  // mientras su categoría esté aquí, sin borrar el dato guardado. Pensado
  // para privacidad al mostrarle el calendario a alguien más.
  final Set<String> hiddenLegendCategories;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;
  // Menú contextual (Prolongar período/Notas/Leyenda/Cancelar) — ya no
  // se abre con un solo toque (eso ahora solo selecciona el día, ver
  // onSelectDay), hace falta doble toque o mantener pulsado, a
  // petición de la usuaria.
  final ValueChanged<DateTime> onDayMenu;
  // Callbacks nuevos del rediseño: elegir mes/año en el desplegable de las
  // píldoras, e ir directo al mes de hoy con el botón "Hoy". Son opcionales
  // para no romper otros posibles usos del widget: si no se pasan, las
  // píldoras y el botón simplemente no hacen nada al tocarlos más allá de
  // lo que ya cubren onPrevMonth/onNextMonth.
  final ValueChanged<DateTime>? onJumpToMonth;
  // Resalta más los días de ventana fértil/ovulación (borde sólido en vez
  // de punteado, y un halo en el día de ovulación) cuando el objetivo de
  // la usuaria ("Mi objetivo" en Configuración/Yo) es "Intentar concebir"
  // — mismos días ya calculados por CyclePrediction, solo más énfasis
  // visual, como en otras apps de seguimiento.
  final bool emphasizeFertility;

  const CalendarGrid({
    super.key,
    required this.viewMonth,
    required this.selectedDate,
    required this.data,
    required this.prediction,
    this.appointments = const [],
    this.hiddenLegendCategories = const {},
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDay,
    required this.onDayMenu,
    this.onJumpToMonth,
    this.emphasizeFertility = false,
  });

  // Selector combinado mes+año en formato "rueda" estilo iOS (dos columnas
  // que giran verticalmente, una para el mes y otra para el año), pedido
  // por la usuaria en vez de las dos hojas independientes (grid de 12
  // meses + lista de años) que había antes. Una sola hoja con botón
  // "Cancelar"/"Listo" arriba, en vez de confirmar al tocar cada opción.
  Future<void> _pickMonthYear(BuildContext context) async {
    final s = AppStrings.of(context);
    var selectedMonth = viewMonth.month;
    final years = List<int>.generate(21, (i) => viewMonth.year - 10 + i);
    var selectedYearIndex = years.indexOf(viewMonth.year);
    if (selectedYearIndex < 0) selectedYearIndex = 10;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    // Padding horizontal generoso (no solo 12): en Xiaomi/MIUI
                    // (como el M2004J19C usado para probar) los ~20-24dp junto
                    // al borde de la pantalla están reservados para el gesto
                    // de "atrás" del sistema y NO le llegan los toques a los
                    // widgets de Flutter ahí — se comprobó que un botón pegado
                    // al borde derecho simplemente no respondía al tocarlo,
                    // mientras que el mismo botón en el borde izquierdo (o más
                    // adentro) sí. 28dp de margen deja los dos botones bien
                    // fuera de esa franja.
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(s.cancel),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, DateTime(years[selectedYearIndex], selectedMonth, 1)),
                        child: Text(
                          s.reminderTimeSheetDone,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 216,
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: selectedMonth - 1),
                            itemExtent: 40,
                            onSelectedItemChanged: (i) => setSheetState(() => selectedMonth = i + 1),
                            children: List.generate(
                              12,
                              (i) => Center(
                                child: Text(s.monthShort(i + 1), style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: selectedYearIndex),
                            itemExtent: 40,
                            onSelectedItemChanged: (i) => setSheetState(() => selectedYearIndex = i),
                            children: years
                                .map((y) => Center(child: Text('$y', style: const TextStyle(fontSize: 18))))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
    if (result != null) {
      (onJumpToMonth ?? (_) {}).call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final weekdayLabels = s.weekdayInitialsMondayFirstList;
    final year = viewMonth.year;
    final month = viewMonth.month;
    final firstDay = DateTime(year, month, 1);
    // Semana empieza en lunes: DateTime.weekday es Mon=1..Sun=7, así que
    // el offset (huecos antes del día 1) es weekday-1 (Lun=0..Dom=6).
    final startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    final appointmentDateKeys = appointments
        .where((a) => !a.id.startsWith('pill_'))
        .map((a) => dateKey(a.dateTime))
        .toSet();
    final pillReminderDateKeys = appointments
        .where((a) => a.id.startsWith('pill_'))
        .map((a) => dateKey(a.dateTime))
        .toSet();

    // El color de fase (Periodo/Previsto/Fértil) también respeta los
    // switches de privacidad del panel "Leyenda": si la usuaria apagó
    // "Periodo", por ejemplo, el día deja de pintarse como período aunque
    // el dato siga guardado — igual criterio que los iconos puntuales de
    // abajo (sexo, pastilla, DIU, etc.).
    _DayKind kindOf(String key) {
      final entry = data[key];
      final isLogged = entry != null && entry.isPeriodDay;
      final isOvulationDay = prediction.ovulationDate != null && dateKey(prediction.ovulationDate!) == key;
      if (isLogged && !hiddenLegendCategories.contains(CalendarLegendCategory.period)) return _DayKind.period;
      // Fértil/ovulación se pintan siempre que hay cálculo disponible,
      // sin importar el objetivo elegido — emphasizeFertility solo se
      // usa más abajo para darles un estilo extra (borde sólido/halo)
      // cuando el objetivo es "Intentar concebir", pero nunca los oculta.
      if (isOvulationDay && !hiddenLegendCategories.contains(CalendarLegendCategory.fertile)) {
        return _DayKind.ovulation;
      }
      if (prediction.fertileDates.contains(key) && !hiddenLegendCategories.contains(CalendarLegendCategory.fertile)) {
        return _DayKind.fertile;
      }
      if (prediction.predictedPeriodDates.contains(key) &&
          !hiddenLegendCategories.contains(CalendarLegendCategory.predicted)) {
        return _DayKind.predicted;
      }
      return _DayKind.none;
    }

    final cells = <Widget>[];
    for (var i = 0; i < startOffset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final dateObj = DateTime(year, month, d);
      final key = dateKey(dateObj);
      final entry = data[key];
      final isToday = dateKey(dateObj) == dateKey(today);
      final isSelected = dateKey(dateObj) == dateKey(selectedDate);
      final kind = kindOf(key);

      // Posición dentro de la semana (0=lunes..6=domingo) — si es 0 o el
      // día es 1 del mes, no hay vecino a la izquierda en esta fila; igual
      // para el borde derecho con el domingo o el último día del mes.
      final weekdayPos = (startOffset + d - 1) % 7;
      final isWeekStart = weekdayPos == 0;
      final isWeekEnd = weekdayPos == 6 || d == daysInMonth;

      final prevKey = d > 1 ? dateKey(DateTime(year, month, d - 1)) : null;
      final nextKey = d < daysInMonth ? dateKey(DateTime(year, month, d + 1)) : null;
      final rawConnectsLeft = !isWeekStart && kind != _DayKind.none && prevKey != null && kindOf(prevKey) == kind;
      final rawConnectsRight = !isWeekEnd && kind != _DayKind.none && nextKey != null && kindOf(nextKey) == kind;

      // "Forma"/"Relleno" elegidos en Configuración > Estilo de calendario
      // (solo aplican al estilo "Clásico"). "Cuadrado"/"Círculo" pintan una
      // figura de color detrás/alrededor del número; "Raya" (pedido
      // explícito de la usuaria: "falta añadir lo de raya") en cambio deja
      // el número sin fondo ni borde y pinta solo una rayita discontinua
      // de color debajo, mismo lenguaje visual que los estilos Elegante/
      // iOS pero como una tercera opción DENTRO de "Clásico" combinable
      // con "Con relleno"/"Sin relleno" (raya gruesa vs. fina). Fusionar
      // días consecutivos de la misma categoría en una sola barra continua
      // (sin separación ni esquinas redondeadas entre ellos) solo tiene
      // sentido con cuadrados rellenos — con círculos, con rayas, o con el
      // relleno "Sin relleno", cada día se dibuja como su propia figura
      // independiente.
      final markerShape = CalendarStyleController.instance.markerShape;
      final markerFill = CalendarStyleController.instance.markerFill;
      final isCircleShape = markerShape == 'circle';
      final isRayaShape = markerShape == 'raya';
      final mergeBar = markerShape == 'square' && markerFill == 'filled';
      final connectsLeft = mergeBar && rawConnectsLeft;
      final connectsRight = mergeBar && rawConnectsRight;

      final colors = _pillColors(kind);
      // Solo cuando el objetivo es "Intentar concebir": ventana fértil con
      // borde sólido reforzado (en vez del borde normal de la categoría) y
      // el día de ovulación con un halo extra — no cambia qué días se
      // calculan como fértiles.
      final emphasizeThisDay = emphasizeFertility && (kind == _DayKind.fertile || kind == _DayKind.ovulation);

      // Color de fondo y de borde de la figura de fase, según el modo de
      // relleno elegido:
      // - "Con relleno": fondo del color de la categoría (saturado en
      //   período/ovulación, muy claro en previsto/fértil) + el borde
      //   suave propio de esa categoría si lo tiene (previsto/fértil).
      // - "Sin relleno": fondo transparente (se ve el pastel de fondo del
      //   calendario) + borde de 2px SIEMPRE visible — período/ovulación
      //   no tienen `borderColor` propio (su fondo ya es bien saturado),
      //   así que en este modo usan su propio color de fondo como color
      //   de borde para no quedar invisibles.
      // Con "Raya" no se pinta ninguna figura detrás del número — el color
      // de la categoría se muestra SOLO en la rayita de abajo (ver
      // `rayaLineColor`), así que aquí queda todo en null.
      final Color? phaseBackground = (colors == null || isRayaShape)
          ? null
          : (markerFill == 'filled' ? colors.background : Colors.transparent);
      final Color? phaseBorderColor = (colors == null || isRayaShape)
          ? null
          : (markerFill == 'filled' ? colors.borderColor : (colors.borderColor ?? colors.background));
      final double phaseBorderWidth = markerFill == 'filled' ? 1.4 : 2.0;
      // Color de la rayita (mismo criterio que CalendarGridElegant/iOS:
      // periodFill/ovulationFill para período/ovulación sólidos, el borde
      // suave propio para previsto/fértil) — no depende de "Con relleno"/
      // "Sin relleno" salvo en el GROSOR de la línea (ver más abajo), para
      // que el color siga siendo reconocible en ambos modos.
      final Color? rayaLineColor = colors == null ? null : (colors.borderColor ?? colors.background);

      final hasAppointment = appointmentDateKeys.contains(key);
      final hasPillReminder = pillReminderDateKeys.contains(key);

      // Un solo icono/indicador por día, elegido por prioridad, y filtrado
      // por las categorías que la usuaria desactivó en "Leyenda" — así el
      // calendario puede mostrarse a alguien más ocultando de antemano lo
      // que no se quiere compartir (ver CalendarLegendCategory).
      bool visible(String categoryId) => !hiddenLegendCategories.contains(categoryId);
      _DayIndicator? indicator;
      if (entry != null && entry.sex && entry.unprotected && visible(CalendarLegendCategory.sexUnprotected)) {
        indicator = const _DayIndicator(Icons.favorite, Color(0xFFE24B4A));
      } else if (entry != null && entry.sex && !entry.unprotected && visible(CalendarLegendCategory.sexProtected)) {
        indicator = const _DayIndicator(Icons.favorite, Color(0xFF1D9E75), halfHeart: true);
      } else if (entry != null && entry.sexMasturbation && visible(CalendarLegendCategory.masturbation)) {
        indicator = const _DayIndicator(Icons.back_hand, Color(0xFFD4537E));
      } else if (entry != null &&
          entry.medication.contains('anticonceptivo') &&
          visible(CalendarLegendCategory.pill)) {
        indicator = const _DayIndicator(Icons.medication, Color(0xFFBA7517));
      } else if (entry != null && entry.diu && visible(CalendarLegendCategory.diu)) {
        indicator = const _DayIndicator(Icons.shield_moon, Color(0xFF7F77DD));
      } else if ((hasAppointment || hasPillReminder) && visible(CalendarLegendCategory.pill)) {
        indicator = const _DayIndicator(Icons.notifications, Color(0xFFF59F00));
      }

      // El círculo/anillo de "seleccionado/hoy" tiene prioridad visual
      // sobre la cápsula de fase (se dibuja encima, centrado, sin afectar
      // la conexión de la cápsula con sus vecinos). "Hoy" se marca con un
      // ANILLO VERDE sin relleno (para no confundirse nunca con el círculo
      // morado sólido de ovulación/selección) — si un día es hoy Y está
      // seleccionado a la vez, gana el anillo verde de "hoy" (es el dato
      // más útil de un vistazo).
      final showTodayRing = isToday;
      final showSolidCircle = isSelected && !isToday;

      // Borde final de la figura de fase: el refuerzo de "Intentar
      // concebir" (fértil con borde grueso) gana sobre el borde normal de
      // la categoría/modo de relleno. Con "Raya" nunca hay borde de caja —
      // el refuerzo de "Intentar concebir" ya se ve en el grosor de la
      // rayita (`rayaBold`, más abajo).
      final Border? phaseBorder = (showSolidCircle || showTodayRing || isRayaShape)
          ? null
          : (emphasizeThisDay && kind == _DayKind.fertile)
              ? Border.all(color: CalendarPhaseColors.fertileBorder, width: 2)
              : (phaseBorderColor != null ? Border.all(color: phaseBorderColor, width: phaseBorderWidth) : null);

      Widget dayCell = Container(
        height: 40,
        // Sin fusión de barra (círculo, o "Sin relleno"), se fija el ancho
        // igual al alto para que cada día sea un cuadrado/círculo propio y
        // bien proporcionado — de lo contrario el `Container` se estira
        // para llenar el ancho de la celda del grid (que no es cuadrada) y
        // el círculo saldría ovalado. Con fusión de barra (cuadrado
        // relleno), se deja sin ancho fijo para que sí se estire y una los
        // días conectados en una sola barra continua, como antes.
        width: mergeBar ? null : 40,
        margin: EdgeInsets.only(
          left: connectsLeft ? 0 : 3,
          right: connectsRight ? 0 : 3,
        ),
        decoration: BoxDecoration(
          color: (showSolidCircle || showTodayRing) ? null : phaseBackground,
          // "Forma" elegida en Configuración (solo estilo Clásico):
          // "Cuadrado" = sin esquinas redondeadas nunca (se fusiona en una
          // sola barra con los vecinos de la misma categoría cuando el
          // relleno es "Con relleno" — ver `mergeBar`); "Círculo" = cada
          // día siempre su propia figura circular, sin fusionar.
          shape: isCircleShape ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircleShape ? null : BorderRadius.zero,
          border: phaseBorder,
          boxShadow: (!showSolidCircle && !showTodayRing && !isRayaShape && emphasizeThisDay && kind == _DayKind.ovulation)
              ? [
                  BoxShadow(
                    color: CalendarPhaseColors.ovulationFill.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1.5,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$d',
          style: TextStyle(
            color: showSolidCircle
                ? CalendarPhaseColors.selectedDayText
                : showTodayRing
                    ? CalendarPhaseColors.todayDayText
                    // Con "Raya" el número nunca lleva color propio — el
                    // color de la categoría vive solo en la rayita de abajo
                    // (mismo criterio que Elegante/iOS), así que se queda en
                    // el color de texto normal de la app.
                    : (isRayaShape || colors == null)
                        ? AppColors.textPrimary
                        // En "Sin relleno" el fondo queda transparente, así
                        // que el texto blanco de período/ovulación (pensado
                        // para un fondo saturado) sería invisible — se usa
                        // el mismo color que el borde de esa categoría en
                        // su lugar.
                        : (markerFill == 'filled' ? colors.foreground : (phaseBorderColor ?? colors.foreground)),
            fontWeight: kind == _DayKind.none && !showSolidCircle && !showTodayRing ? FontWeight.normal : FontWeight.w700,
            fontSize: 15,
          ),
        ),
      );

      // Círculo sólido morado de día seleccionado (que no sea hoy), siempre
      // totalmente redondeado (círculo), independiente de si conecta con
      // vecinos.
      if (showSolidCircle) {
        dayCell = Container(
          height: 40,
          margin: EdgeInsets.only(
            left: connectsLeft ? 0 : 3,
            right: connectsRight ? 0 : 3,
          ),
          decoration: BoxDecoration(
            color: CalendarPhaseColors.selectedDayFill,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$d',
            style: const TextStyle(
              color: CalendarPhaseColors.selectedDayText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        );
      }

      // Anillo verde sin relleno de "hoy" — a diferencia del círculo
      // morado sólido de arriba, aquí el fondo queda transparente (se ve
      // el fondo pastel del calendario) y solo el borde se pinta, para que
      // "hoy" nunca se confunda visualmente con el morado de
      // ovulación/selección.
      if (showTodayRing) {
        dayCell = Container(
          height: 40,
          margin: EdgeInsets.only(
            left: connectsLeft ? 0 : 3,
            right: connectsRight ? 0 : 3,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CalendarPhaseColors.todayRingColor, width: 2.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '$d',
            style: const TextStyle(
              color: CalendarPhaseColors.todayDayText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        );
      }

      // Rayita discontinua de color bajo el número — solo con "Raya" y solo
      // si el día tiene alguna categoría (colors != null) y no es el
      // círculo de hoy/seleccionado (esos ya llevan su propio aro de
      // color, la rayita sobraría). El refuerzo de "Intentar concebir"
      // (fértil/ovulación con más énfasis) engruesa la línea igual que ya
      // hace con el borde en Cuadrado/Círculo; "Con relleno" también la
      // engruesa (una raya "rellena" se lee como más gruesa/sólida), y
      // "Sin relleno" la deja fina, para que el eje Relleno siga
      // significando lo mismo con las 3 formas.
      final showRayaLine = isRayaShape && !showSolidCircle && !showTodayRing && rayaLineColor != null;
      final rayaBold = markerFill == 'filled' || emphasizeThisDay;

      final Widget cell = GestureDetector(
        onTap: () => onSelectDay(dateObj),
        onDoubleTap: () => onDayMenu(dateObj),
        onLongPress: () => onDayMenu(dateObj),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            dayCell,
            const SizedBox(height: 3),
            SizedBox(
              width: 22,
              height: 5,
              child: showRayaLine
                  ? CustomPaint(painter: _RayaLinePainter(color: rayaLineColor!, bold: rayaBold))
                  : null,
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 8,
              child: indicator == null
                  ? null
                  : indicator.halfHeart
                      ? _HalfHeartIcon(size: 8, color: indicator.color)
                      : Icon(indicator.icon, size: 8, color: indicator.color),
            ),
          ],
        ),
      );

      // El marcador "Inicio de la regla" (círculo dibujado a mano +
      // etiqueta manuscrita sobre el primer día de cada racha de período)
      // se quitó a pedido de la usuaria — quedaba visualmente recargado
      // sobre el grid.

      cells.add(cell);
    }

    return Container(
      decoration: BoxDecoration(
        color: CalendarPhaseColors.screenBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          // Selector de mes/año: dos píldoras tocables + botón "Hoy".
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MonthYearPill(
                label: '${s.monthShort(month)} $year',
                onTap: () => _pickMonthYear(context),
              ),
              _TodayPillButton(
                label: s.calendarTodayButton,
                onTap: () => (onJumpToMonth ?? (_) {}).call(DateTime(today.year, today.month, 1)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Fila de días de la semana, L M X J V S D, sticky visualmente
          // encima del grid (no hay scroll dentro de este widget, pero
          // queda fija en su propia fila por encima siempre).
          Row(
            children: weekdayLabels
                .map((w) => Expanded(
                      child: Center(
                        child: Text(
                          w.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Grid del mes: líneas divisorias muy sutiles entre celdas.
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: CalendarPhaseColors.gridDivider, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: List.generate(cells.length, (i) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: (i % 7) != 6
                          ? const BorderSide(color: CalendarPhaseColors.gridDivider, width: 0.5)
                          : BorderSide.none,
                      bottom: i < cells.length - 7
                          ? const BorderSide(color: CalendarPhaseColors.gridDivider, width: 0.5)
                          : BorderSide.none,
                    ),
                  ),
                  child: cells[i],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora tocable de mes o año en el selector superior.
class _MonthYearPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MonthYearPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón "Hoy" en píldora rosa clara, centra el calendario en el día actual.
class _TodayPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TodayPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CalendarPhaseColors.todayPillBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CalendarPhaseColors.todayPillText,
            ),
          ),
        ),
      ),
    );
  }
}

// (El borde punteado que antes dibujaba esta clase con CustomPaint fue
// reemplazado por un `Border.all` sólido normal de `BoxDecoration` — ver
// `phaseBorder` en build() — desde que "Forma"/"Relleno" son elegibles
// por la usuaria en Configuración > Estilo de calendario.)

/// Rayita discontinua de color bajo el número del día — pintura de la
/// tercera opción de "Forma" ("Raya", pedido de la usuaria). Misma técnica
/// que `_EleDashedLinePainter` de `calendar_grid_elegant.dart` (duplicada
/// aquí porque esa es privada a ese archivo, mismo criterio de duplicación
/// que ya sigue el resto del código de estilos de calendario): `bold`
/// engruesa la línea para "Con relleno" y para el refuerzo de "Intentar
/// concebir" en fértil/ovulación.
class _RayaLinePainter extends CustomPainter {
  final Color color;
  final bool bold;
  const _RayaLinePainter({required this.color, this.bold = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = bold ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
    const dashGap = 3.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      final xEnd = (x + dashWidth) > size.width ? size.width : (x + dashWidth);
      canvas.drawLine(Offset(x, y), Offset(xEnd, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _RayaLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bold != bold;
}
