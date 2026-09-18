import 'package:flutter/material.dart';

import '../services/calendar_palette_controller.dart';
import '../services/settings_service.dart' show AppThemeOption;

/// Paleta de colores consistente con el prototipo web (rosa/violeta).
class AppColors {
  static const primary = Color(0xFFD6336C);
  static const primaryDark = Color(0xFFA61E4D);
  static const primaryLight = Color(0xFFF8D7E3);
  static const fertile = Color(0xFFA78BFA);
  static const fertileLight = Color(0xFFEDE9FE);
  static const ovulation = Color(0xFF7C3AED);
  // Verde usado exclusivamente para marcar visualmente "hoy" en el
  // calendario — antes ese indicador era un halo rosa apenas perceptible
  // sobre fondos ya rosados; el verde no se usa en ningún otro estado
  // (período/predicción/fértil/ovulación), así que siempre destaca.
  static const today = Color(0xFF2F9E44);
  static const background = Color(0xFFFFF5F7);
  static const cardBackground = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF3D2436);
  static const textMuted = Color(0xFF9B8290);
  static const border = Color(0xFFF3D9E2);
}

/// Colores EXACTOS del rediseño de calendario aprobado en v0 (React/Next.js)
/// y portado tal cual a Flutter — ver `lib/widgets/calendar_grid.dart`. A
/// diferencia de `CalendarPastel` (paleta pastel anterior, todavía usada
/// por otras pantallas para leyendas antiguas), estos son los tonos
/// definitivos del diseño aprobado por el usuario: período y ovulación con
/// relleno sólido, previsto y fértil con relleno muy claro + borde
/// punteado.
class CalendarPhaseColors {
  /// Período (dato real registrado): rosa magenta sólido.
  ///
  /// Los 7 colores de esta sección (period/predicted/fertile/today/
  /// ovulation) YA NO son `const` — se leen en vivo de la paleta elegida
  /// en Configuración > "Colores del calendario"
  /// (`CalendarPaletteController.instance.palette`), para que la persona
  /// pueda cambiar de paleta si con la original ("Pastel") le cuesta
  /// distinguir Previsto de Fértil. El resto de colores de esta clase
  /// (texto, píldoras, fondo de pantalla) siguen fijos porque no forman
  /// parte del problema de contraste reportado.
  static Color get periodFill => Color(CalendarPaletteController.instance.palette.periodFill);
  static const periodText = Color(0xFFFFFFFF);

  /// Previsto/predicción de período.
  static Color get predictedFill => Color(CalendarPaletteController.instance.palette.predictedFill);
  static const predictedText = Color(0xFF1F8FC4);
  static Color get predictedBorder => Color(CalendarPaletteController.instance.palette.predictedBorder);

  /// Ventana fértil.
  static Color get fertileFill => Color(CalendarPaletteController.instance.palette.fertileFill);
  // Antes magenta (0xFFC2185B) — se pisaba visualmente con el rojo de
  // "Período" ahora que ese es un cuadrado sólido rojo. Se cambia a un
  // ámbar oscuro a juego con el relleno/borde naranja de "Fértil" en las 3
  // paletas (ver kCalendarPalettes).
  static const fertileText = Color(0xFF9A5000);
  static Color get fertileBorder => Color(CalendarPaletteController.instance.palette.fertileBorder);

  /// Día de ovulación: morado sólido — mismo tono usado para el
  /// círculo de día seleccionado/hoy.
  static Color get ovulationFill => Color(CalendarPaletteController.instance.palette.ovulationFill);
  static const ovulationText = Color(0xFFFFFFFF);

  /// Círculo de día seleccionado (morado oscuro sólido) — cuando la persona
  /// toca un día distinto a hoy. Reutiliza el mismo tono que ovulación.
  static Color get selectedDayFill => Color(CalendarPaletteController.instance.palette.ovulationFill);
  static const selectedDayText = Color(0xFFFFFFFF);

  /// Anillo de "hoy": borde grueso, sin relleno (transparente por dentro)
  /// — deliberadamente distinto del morado sólido de ovulación/selección
  /// para que "hoy" se distinga de un vistazo en el grid, incluso cuando
  /// cae junto a un día de ovulación.
  static Color get todayRingColor => Color(CalendarPaletteController.instance.palette.todayRing);
  static const todayDayText = AppColors.textPrimary;

  /// Fondo pastel lavanda/rosa muy pálido de toda la pantalla de
  /// calendario (no blanco puro).
  static const screenBackground = Color(0xFFFBF3FA);

  /// Marcador de inicio de período: círculo dibujado a mano + etiqueta
  /// manuscrita.
  static const periodStartMarker = Color(0xFF9B59B6);

  /// Botón "Hoy" en píldora rosa clara.
  static const todayPillBg = Color(0xFFFBD9E6);
  static const todayPillText = Color(0xFFE91E8C);

  /// Botón "Editar período" (píldora rosa pastel).
  static const editPeriodPillBg = Color(0xFFFFD9EC);
  static const editPeriodPillText = Color(0xFFE91E8C);

  /// Botón "Notas" (píldora lavanda pastel).
  static const notesPillBg = Color(0xFFE8D9F5);
  static const notesPillText = Color(0xFF7A3FA0);

  /// Líneas divisorias muy sutiles entre celdas del grid.
  static const gridDivider = Color(0xFFEDE3F0);
}

/// Construye el `ThemeData` global a partir del tema de color elegido en
/// Configuración (`theme`, del catálogo `kAppThemes`). El AppBar de todas
/// las pantallas que no fijan su propio `backgroundColor` (por ejemplo
/// Configuración) hereda de aquí, y Flutter usa ese mismo color para la
/// barra de estado del sistema Android — por eso ambos cambian juntos
/// cuando la persona elige otro color en Configuración.
ThemeData buildAppTheme(AppThemeOption theme) {
  final primary = Color(theme.primary);
  final primaryDark = Color(theme.primaryDark);
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
    ),
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: primaryDark,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.textPrimary),
    ),
  );
}
