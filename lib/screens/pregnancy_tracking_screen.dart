import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart' show themeById;
import 'pregnancy_simulator_screen.dart';

// Imagen real del bebé para el día exacto de embarazo (más granular que
// por semana) — generadas con IA y recortadas en
// assets/pregnancy_days/day_001.png .. day_270.png. daysSince=0 es el día 1.
// No son medidas médicas exactas, solo una simulación visual del
// desarrollo día a día. Función de nivel superior (no privada de la
// clase) porque también la usa la tarjeta de embarazo de la pestaña Hoy
// (today_screen.dart), que necesita mostrar la misma foto ahí arriba.
String pregnancyDayImagePath(int daysSince) {
  final d = (daysSince + 1).clamp(1, 270);
  return 'assets/pregnancy_days/day_${d.toString().padLeft(3, '0')}.png';
}

/// Pantalla de seguimiento de embarazo: tarjeta hero con ilustración de
/// feto por trimestre + anillo de progreso (semana/40), 3 tarjetas de
/// datos (última regla, fecha de parto, semanas restantes), tarjeta de
/// tamaño del bebé y tarjeta de dato curioso de la semana.
///
/// Se accede desde la tarjeta de embarazo en MainTabScreen (solo si ya
/// hay LMP configurada) y desde "Mi salud" > sección Embarazo. Toda la
/// pantalla es cálculo derivado de [lmp], sin estado propio.
class PregnancyTrackingScreen extends StatelessWidget {
  final DateTime lmp;
  final String themeId;

  /// true si es un embarazo múltiple (mellizos/gemelos) — ver
  /// PregnancySettings.isTwins/PartnerPregnancyData.isTwins. Cambia la
  /// duración total del embarazo usada en todos los cálculos de esta
  /// pantalla: 37 semanas (259 días) en vez de las 40 semanas (280 días)
  /// habituales de un embarazo único, que es el promedio real al que suele
  /// llegar un embarazo de mellizos.
  final bool isTwins;

  /// true cuando esta pantalla se abre en modo "vista de socio" y la dueña
  /// del embarazo NO activó "Compartir fotos del bebé" (ver
  /// PartnerPregnancyScreen). En ese caso se sigue mostrando todo el
  /// seguimiento (semana, fechas, consejos) pero se reemplaza la foto real
  /// del bebé por un ícono genérico, y se oculta el botón "Simulacro"
  /// (que también enseña fotos semana a semana).
  final bool hideBabyPhoto;

  /// Qué hacer al tocar la "X" del encabezado. Por defecto (null) hace
  /// Navigator.pop(context), que es correcto en todos los usos normales
  /// (esta pantalla siempre se abre empujada sobre otra). La única
  /// excepción es PartnerViewerHomeScreen: ahí esta pantalla ES la raíz de
  /// la app para una cuenta anónima de solo-lectura, así que no hay nada
  /// que hacer "pop" — se pasa aquí la acción de cerrar sesión en su lugar.
  final VoidCallback? onClose;

  /// false cuando esta pantalla se usa como una PESTAÑA dentro de
  /// PartnerHubScreen (sección "Seguimiento"): ahí el propio Hub ya tiene
  /// su AppBar con botón de salir/atrás, así que esta "X" quedaría
  /// duplicada — se oculta (sigue mostrando el título). En cualquier otro
  /// uso (pantalla completa) se deja tal cual, por eso el valor por
  /// defecto es true.
  final bool showCloseButton;

  const PregnancyTrackingScreen({
    super.key,
    required this.lmp,
    required this.themeId,
    this.isTwins = false,
    this.hideBabyPhoto = false,
    this.onClose,
    this.showCloseButton = true,
  });

  /// Duración total del embarazo en semanas/días usada para calcular fecha
  /// de parto, progreso y semanas restantes — 37/259 para mellizos, 40/280
  /// para un embarazo único. Getters de instancia para que tanto build()
  /// como _buildStatsRow() (que también recalcula la fecha de parto) usen
  /// siempre el mismo valor.
  int get _totalWeeks => isTwins ? 37 : 40;
  int get _totalDays => isTwins ? 259 : 280;

  // Fondo y superficies oscuras propias de esta pantalla — el resto de
  // la app usa la paleta clara de AppColors, pero esta pantalla busca un
  // look "dark mode" premium tipo apps de seguimiento de embarazo.
  static const _bgColor = Color(0xFF0F0F14);
  static const _cardColor = Color(0xFF1A1A22);
  static const _cardColorAlt = Color(0xFF20202A);
  static const _textMuted = Color(0xFFA7A6B3);
  static const _gold = Color(0xFFFFC078);

  static const _monthShort = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  String _formatDate(DateTime d) => '${d.day} ${_monthShort[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final primary = Color(themeById(themeId).primary);

    // Misma lógica de cálculo que _buildPregnancyCard en main_tab_screen.dart.
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final rawDaysSince = todayMidnight.difference(DateTime(lmp.year, lmp.month, lmp.day)).inDays;
    final daysSince = rawDaysSince < 0 ? 0 : rawDaysSince;
    // "Semana X" nunca pasa de totalWeeks + 2 (unas 2 semanas de margen de
    // "postérmino") aunque la FUM guardada sea muy vieja — por ejemplo si
    // alguien olvidó desactivar el modo embarazo después del parto, o
    // configuró una fecha de prueba muy antigua. Sin este límite, se
    // mostraban semanas absurdas como "Semana 43" que no corresponden a
    // ningún embarazo real. Se limita aquí (sobre una copia de daysSince)
    // para que semana y "+X días" queden siempre consistentes entre sí.
    final capDays = _totalDays + 7;
    final displayDaysSince = daysSince > capDays ? capDays : daysSince;
    // "weeks" es la semana de embarazo actual tal como se comunica
    // normalmente (1-indexada: los días 0-6 desde la FUM son la "semana 1",
    // los días 7-13 la "semana 2", etc.) — antes era 0-indexada (edad
    // gestacional en semanas completas), lo que mostraba "Semana 0" el
    // primer día y desplazaba en 1 el mes, el trimestre, las "semanas
    // restantes" y el tamaño del bebé durante todo el embarazo. Bug
    // reportado en la auditoría previa a publicación.
    final weeks = (displayDaysSince / 7).floor() + 1;
    final extraDays = displayDaysSince % 7;
    final dueDate = lmp.add(Duration(days: _totalDays));
    final month = weeks <= 0 ? 1 : ((weeks / 4.345).ceil()).clamp(1, 9);
    final trimester = weeks <= 13 ? 1 : (weeks <= 27 ? 2 : 3);
    final weeksLeft = (_totalWeeks - weeks).clamp(0, _totalWeeks);
    final progress = (weeks / _totalWeeks).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, s),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _buildHeroCard(s, primary, weeks, extraDays, month, trimester, progress, daysSince),
                  const SizedBox(height: 12),
                  if (!hideBabyPhoto) ...[
                    _buildSimulatorButton(context, primary),
                    const SizedBox(height: 16),
                  ],
                  _buildStatsRow(context, s, primary, weeks, daysSince, weeksLeft),
                  const SizedBox(height: 16),
                  _buildBabySizeCard(s, weeks),
                  const SizedBox(height: 16),
                  _buildWeeklyFactCard(s, trimester),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            s.pregnancyTrackingTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          if (showCloseButton)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose ?? () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    AppStrings s,
    Color primary,
    int weeks,
    int extraDays,
    int month,
    int trimester,
    double progress,
    int daysSince,
  ) {
    // Borde con degradado: Container externo pintado con el gradiente,
    // Container interno (con margin = grosor del borde) pintado con el
    // color real de la tarjeta — simula un borde degradado sin paquetes.
    return Container(
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary.withOpacity(0.65), _gold.withOpacity(0.35), Colors.white.withOpacity(0.06)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cardColorAlt, _cardColor],
          ),
        ),
        child: Column(
          children: [
            Text(
              s.pregnancyTrackingHeroText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500, height: 1.3),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _ProgressRingPainter(progress: progress, progressColor: _gold),
                  ),
                  if (hideBabyPhoto)
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.pregnant_woman, size: 72, color: _gold.withOpacity(0.7)),
                    )
                  else
                    ClipOval(
                      child: Image.asset(
                        pregnancyDayImagePath(daysSince),
                        width: 190,
                        height: 190,
                        fit: BoxFit.cover,
                        // Si la imagen del día exacto fallara al decodificar
                        // por cualquier motivo (visto solo en dispositivo
                        // real iOS, nunca en el emulador), antes se quedaba
                        // en blanco sin avisar. Ahora se ve al menos un
                        // ícono en vez de nada, y loguea el error concreto
                        // para poder diagnosticarlo si vuelve a pasar.
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('pregnancyDayImagePath fallo al cargar: $error');
                          return Container(
                            color: Colors.white.withOpacity(0.06),
                            alignment: Alignment.center,
                            child: Icon(Icons.pregnant_woman, size: 72, color: _gold.withOpacity(0.7)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              s.pregnancyMonthLabel,
              style: const TextStyle(fontSize: 11, color: _textMuted, letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            Text(
              '$month',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: _gold, height: 1.0),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: Text(
                s.pregnancyWeekPill(weeks, extraDays),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            if (isTwins) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '👯 Mellizos/gemelos · fechas ajustadas',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _gold.withOpacity(0.9)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Botón que abre PregnancySimulatorScreen — pedido de la usuaria para
  // poder "adelantar la fecha" y ver cómo evolucionan el bebé y la
  // barriga en cualquier semana del embarazo, no solo hoy.
  Widget _buildSimulatorButton(BuildContext context, Color primary) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PregnancySimulatorScreen(lmp: lmp, themeId: themeId, isTwins: isTwins)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: BorderSide(color: _gold.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Simulacro: ver otras semanas', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // Las 3 tarjetas ahora son botones: pedido de la usuaria de poder tocar
  // cada dato (última regla / fecha de parto / cuenta atrás) y ver una
  // pantalla con más contexto, consejos y una gráfica explicativa — antes
  // solo mostraban el número sin poder profundizar en qué significa.
  Widget _buildStatsRow(
    BuildContext context,
    AppStrings s,
    Color primary,
    int weeks,
    int daysSince,
    int weeksLeft,
  ) {
    final dueDate = lmp.add(Duration(days: _totalDays));
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.water_drop,
            iconColor: const Color(0xFFFF6B6B),
            value: _formatDate(lmp),
            label: s.pregnancyLastPeriodLabel,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PregnancyStatDetailScreen(
                type: _StatDetailType.lastPeriod,
                lmp: lmp,
                dueDate: dueDate,
                weeks: weeks,
                daysSince: daysSince,
                weeksLeft: weeksLeft,
                primary: primary,
                isTwins: isTwins,
              ),
            )),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.child_care,
            iconColor: const Color(0xFF9775FA),
            value: _formatDate(dueDate),
            label: s.pregnancyDueDateShortLabel,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PregnancyStatDetailScreen(
                type: _StatDetailType.dueDate,
                lmp: lmp,
                dueDate: dueDate,
                weeks: weeks,
                daysSince: daysSince,
                weeksLeft: weeksLeft,
                primary: primary,
                isTwins: isTwins,
              ),
            )),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.hourglass_bottom,
            iconColor: const Color(0xFF51CF66),
            value: s.pregnancyWeeksShort(weeksLeft),
            label: s.pregnancyDueInLabel,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PregnancyStatDetailScreen(
                type: _StatDetailType.dueIn,
                lmp: lmp,
                dueDate: dueDate,
                weeks: weeks,
                daysSince: daysSince,
                weeksLeft: weeksLeft,
                primary: primary,
                isTwins: isTwins,
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: iconColor.withOpacity(0.16), shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 19),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10.5, color: _textMuted, height: 1.2),
                  ),
                ],
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.info_outline, size: 13, color: Colors.white.withOpacity(0.28)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Semana -> (emoji, comparación). Contenido secundario, se deja solo en
  // español; el título de la tarjeta que lo envuelve sí está en i18n.
  static const List<_WeekRange> _babySizes = [
    _WeekRange(1, 4, 'una semilla de amapola 🌱'),
    _WeekRange(5, 6, 'una lenteja 🫘'),
    _WeekRange(7, 8, 'una frambuesa 🍇'),
    _WeekRange(9, 10, 'una aceituna 🫒'),
    _WeekRange(11, 13, 'una ciruela pasa 🍈'),
    _WeekRange(14, 15, 'una manzana 🍎'),
    _WeekRange(16, 17, 'un aguacate 🥑'),
    _WeekRange(18, 19, 'un pimiento 🫑'),
    _WeekRange(20, 21, 'un plátano 🍌'),
    _WeekRange(22, 23, 'una papaya 🥭'),
    _WeekRange(24, 25, 'una mazorca de maíz 🌽'),
    _WeekRange(26, 27, 'una coliflor 🥦'),
    _WeekRange(28, 29, 'una berenjena 🍆'),
    _WeekRange(30, 31, 'un repollo 🥬'),
    _WeekRange(32, 33, 'una piña 🍍'),
    _WeekRange(34, 35, 'un melón pequeño 🍈'),
    _WeekRange(36, 37, 'una lechuga romana 🥬'),
    _WeekRange(38, 42, 'una sandía pequeña 🍉'),
  ];

  String _babySizeFor(int weeks) {
    final w = weeks <= 0 ? 1 : weeks.clamp(1, 40);
    for (final range in _babySizes) {
      if (w >= range.start && w <= range.end) return range.label;
    }
    return _babySizes.last.label;
  }

  Widget _buildBabySizeCard(AppStrings s, int weeks) {
    final label = _babySizeFor(weeks);
    return _infoCard(
      title: s.pregnancyBabySizeTitle,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  // Dato curioso agrupado por trimestre — contenido secundario en español.
  String _factFor(int trimester) {
    switch (trimester) {
      case 1:
        return 'Durante el primer trimestre se forman los órganos principales del bebé. El corazón ya late alrededor de la semana 6, y el tubo neural (origen del cerebro y la médula espinal) se cierra en estas primeras semanas.';
      case 2:
        return 'En el segundo trimestre suelen empezar a sentirse los primeros movimientos del bebé. Los huesos se endurecen, los sentidos como el oído se desarrollan y el crecimiento se acelera notablemente.';
      default:
        return 'En el tercer trimestre el bebé gana peso rápidamente y los pulmones terminan de madurar en preparación para respirar aire fuera del útero. El bebé suele acomodarse cabeza abajo de cara al parto.';
    }
  }

  Widget _buildWeeklyFactCard(AppStrings s, int trimester) {
    return _infoCard(
      title: s.pregnancyWeeklyFactTitle,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          _factFor(trimester),
          style: const TextStyle(fontSize: 13, color: _textMuted, height: 1.45),
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _textMuted, letterSpacing: 0.3),
          ),
          child,
        ],
      ),
    );
  }
}

class _WeekRange {
  final int start;
  final int end;
  final String label;
  const _WeekRange(this.start, this.end, this.label);
}

/// Arco de fondo tenue + arco de progreso (semana/40) desde las 12 en
/// punto, en sentido horario, con extremos redondeados.
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;

  _ProgressRingPainter({required this.progress, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 10) / 2;
    const strokeWidth = 7.0;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [progressColor.withOpacity(0.5), progressColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.progressColor != progressColor;
}

// ---------------------------------------------------------------------
// Pantallas de detalle de las 3 tarjetas de datos (última regla / fecha
// de parto / cuenta atrás). Pedido de la usuaria: al tocar cada dato
// quiere ver más información, con consejos, una gráfica explicativa y
// más contexto — antes esas tarjetas solo mostraban el número, sin poder
// profundizar. Contenido explicativo y consejos se dejan solo en
// español (igual que el resto del contenido secundario de esta pantalla,
// como los datos curiosos por trimestre).
// ---------------------------------------------------------------------

enum _StatDetailType { lastPeriod, dueDate, dueIn }

class PregnancyStatDetailScreen extends StatelessWidget {
  final _StatDetailType type;
  final DateTime lmp;
  final DateTime dueDate;
  final int weeks;
  final int daysSince;
  final int weeksLeft;
  final Color primary;
  final bool isTwins;

  const PregnancyStatDetailScreen({
    super.key,
    required this.type,
    required this.lmp,
    required this.dueDate,
    required this.weeks,
    required this.daysSince,
    required this.weeksLeft,
    required this.primary,
    this.isTwins = false,
  });

  int get _totalWeeks => isTwins ? 37 : 40;
  int get _totalDays => isTwins ? 259 : 280;

  static const _bgColor = PregnancyTrackingScreen._bgColor;
  static const _cardColor = PregnancyTrackingScreen._cardColor;
  static const _textMuted = PregnancyTrackingScreen._textMuted;
  static const _gold = PregnancyTrackingScreen._gold;

  static const _monthShort = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  String _fmt(DateTime d) => '${d.day} ${_monthShort[d.month - 1]}';

  IconData get _icon => switch (type) {
        _StatDetailType.lastPeriod => Icons.water_drop,
        _StatDetailType.dueDate => Icons.child_care,
        _StatDetailType.dueIn => Icons.hourglass_bottom,
      };

  Color get _iconColor => switch (type) {
        _StatDetailType.lastPeriod => const Color(0xFFFF6B6B),
        _StatDetailType.dueDate => const Color(0xFF9775FA),
        _StatDetailType.dueIn => const Color(0xFF51CF66),
      };

  String get _title => switch (type) {
        _StatDetailType.lastPeriod => 'Última regla',
        _StatDetailType.dueDate => 'Fecha probable de parto',
        _StatDetailType.dueIn => 'Cuenta atrás',
      };

  String get _bigValue => switch (type) {
        _StatDetailType.lastPeriod => _fmt(lmp),
        _StatDetailType.dueDate => _fmt(dueDate),
        _StatDetailType.dueIn => '$weeksLeft semanas',
      };

  String get _explanation => switch (type) {
        _StatDetailType.lastPeriod =>
          'El embarazo se cuenta desde el primer día de tu última regla (FUM), no desde el día de la concepción. Es la convención médica estándar porque la mayoría de las mujeres recuerda esa fecha con más precisión que el día exacto de la ovulación.\n\n'
              'Por eso, en la "semana 4" de embarazo el bebé en realidad solo lleva alrededor de 2 semanas desde la concepción: las primeras 2 semanas del conteo son antes de que ocurriera la ovulación.',
        _StatDetailType.dueDate => isTwins
            ? 'Con mellizos/gemelos, la fecha se calcula a las 37 semanas (259 días) desde tu última regla, en vez de las 40 semanas de un embarazo único — un embarazo múltiple a término completo dura menos porque el espacio en el útero es más limitado.\n\n'
                'Es solo una fecha probable: muchos partos de mellizos ocurren incluso antes, entre las semanas 36 y 37.'
            : 'Se calcula con la Regla de Naegele: tu última regla + 280 días (40 semanas). Es solo una fecha probable, no una fecha exacta — se calcula así porque un embarazo a término dura en promedio 40 semanas desde la FUM.\n\n'
                'En la práctica, muy pocos bebés nacen exactamente ese día: la mayoría nace en una ventana de un par de semanas antes o después.',
        _StatDetailType.dueIn =>
          'Vas por la semana $weeks de $_totalWeeks. Esto representa aproximadamente el ${((weeks / _totalWeeks * 100).clamp(0, 100)).round()}% del embarazo. '
              '${isTwins ? 'El conteo total de un embarazo de mellizos a término son 37 semanas (259 días)' : 'El conteo total de un embarazo a término son 40 semanas (280 días)'} desde tu última regla.',
      };

  List<String> get _tips => switch (type) {
        _StatDetailType.lastPeriod => const [
            'Si no recuerdas la fecha exacta de tu última regla, la primera ecografía puede ajustar esta fecha con más precisión.',
            'Anotar tus ciclos en la app ayuda a que este cálculo sea más exacto en futuros embarazos.',
            'Un ciclo irregular puede hacer que la fecha real de concepción varíe unos días respecto a este cálculo estándar.',
          ],
        _StatDetailType.dueDate => isTwins
            ? const [
                'La mayoría de los embarazos de mellizos/gemelos llega a término entre las semanas 36 y 38 — muy pocos pasan de la semana 38.',
                'Muchos médicos recomiendan programar o inducir el parto de mellizos alrededor de la semana 37-38, aunque no haya complicaciones.',
                'Ten la maleta del hospital lista desde la semana 32-34: con mellizos el parto se adelanta con más frecuencia que en un embarazo único.',
                'Las citas de control suelen ser más frecuentes que en un embarazo único — tu médico vigilará de cerca el crecimiento de cada bebé.',
              ]
            : const [
                'Pretérmino: antes de la semana 37. A término temprano: semanas 37-38. A término completo: semanas 39-40.',
                'A término tardío: semana 41. Postérmino: semana 42 en adelante.',
                'Ten la maleta del hospital lista desde la semana 36, por si el parto se adelanta.',
                'Si llegas a la semana 41 sin señales de parto, tu médico probablemente hablará contigo sobre inducción.',
              ],
        _StatDetailType.dueIn => switch (weeks <= 13 ? 1 : (weeks <= 27 ? 2 : 3)) {
            1 => const [
                'Primer trimestre: es clave empezar (o continuar) el ácido fólico y agendar tu primera cita prenatal.',
                'Las náuseas y el cansancio son más comunes en estas semanas — suelen mejorar al entrar al segundo trimestre.',
                'Evita alcohol, tabaco y alimentos crudos o poco cocidos durante todo el embarazo.',
              ],
            2 => const [
                'Segundo trimestre: suele ser el más cómodo. Es un buen momento para la ecografía morfológica (semana 18-22).',
                'Empieza a sentirse el movimiento del bebé, normalmente entre las semanas 18 y 22.',
                'Buen momento para investigar clases de preparación al parto si te interesan.',
              ],
            _ => const [
                'Tercer trimestre: revisa o arma la maleta del hospital a partir de la semana 36.',
                'Las citas prenatales suelen ser más frecuentes en este tramo — cada 2 semanas y luego cada semana.',
                'Presta atención a los movimientos del bebé; avisa a tu médico si notas un cambio brusco en el patrón habitual.',
              ],
          },
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _headerBlock(),
                  const SizedBox(height: 20),
                  _sectionCard(title: 'Qué significa', child: Text(
                    _explanation,
                    style: const TextStyle(fontSize: 13.5, color: _textMuted, height: 1.5),
                  )),
                  const SizedBox(height: 16),
                  _sectionCard(title: 'Gráfica', child: _chart()),
                  const SizedBox(height: 16),
                  _sectionCard(title: 'Consejos', child: _tipsList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_iconColor.withOpacity(0.22), _cardColor],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: _iconColor.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(_icon, color: _iconColor, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            _bigValue,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            type == _StatDetailType.dueIn ? 'te faltan para conocer a tu bebé' : _title,
            style: const TextStyle(fontSize: 12.5, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _textMuted, letterSpacing: 0.3),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _tipsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tip in _tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 15, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chart() {
    return switch (type) {
      _StatDetailType.lastPeriod =>
        _TimelineChart(lmp: lmp, dueDate: dueDate, daysSince: daysSince, totalDays: _totalDays, accent: _iconColor, gold: _gold),
      _StatDetailType.dueDate => _BirthDistributionChart(accent: _iconColor, gold: _gold, isTwins: isTwins),
      _StatDetailType.dueIn => _TrimesterProgressChart(weeks: weeks, totalWeeks: _totalWeeks, accent: primary),
    };
  }
}

/// Gráfica de línea de tiempo: FUM -> concepción aprox. -> hoy -> parto,
/// para la tarjeta "Última regla". Todo con widgets declarativos
/// (Stack + LayoutBuilder), sin CustomPainter.
class _TimelineChart extends StatelessWidget {
  final DateTime lmp;
  final DateTime dueDate;
  final int daysSince;
  final int totalDays;
  final Color accent;
  final Color gold;

  const _TimelineChart({
    required this.lmp,
    required this.dueDate,
    required this.daysSince,
    required this.totalDays,
    required this.accent,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    final totalDaysD = totalDays.toDouble();
    final conceptionFrac = 14 / totalDaysD;
    final todayFrac = (daysSince / totalDaysD).clamp(0.0, 1.0);

    return LayoutBuilder(builder: (context, constraints) {
      const dotSize = 12.0;
      final width = constraints.maxWidth;
      Widget dot(double frac, Color color) {
        final left = (width * frac).clamp(dotSize / 2, width - dotSize / 2) - dotSize / 2;
        return Positioned(
          left: left,
          top: -4,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          ),
        );
      }

      Widget labelBelow(double frac, String line1, String line2, {required bool secondRow}) {
        const labelWidth = 58.0;
        final left = (width * frac).clamp(labelWidth / 2, width - labelWidth / 2) - labelWidth / 2;
        return Positioned(
          left: left,
          top: secondRow ? 44 : 24,
          child: SizedBox(
            width: labelWidth,
            child: Column(
              children: [
                Text(line1, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                Text(line2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: PregnancyTrackingScreen._textMuted)),
              ],
            ),
          ),
        );
      }

      // Las 4 etiquetas se reparten en 2 filas alternadas, pero el orden
      // de asignación de fila se calcula según la posición horizontal
      // real (ordenando por frac), no según el orden fijo FUM/Concepción/
      // Hoy/Parto. Así, sea cual sea la semana de embarazo, dos puntos
      // que caigan cerca uno del otro (p. ej. "Hoy" pegado a "FUM" al
      // inicio, o pegado a "Parto" cerca del final) siempre terminan en
      // filas distintas y no se superponen.
      final points = <(double, String, String)>[
        (0.0, 'FUM', 'día 0'),
        (conceptionFrac, 'Concepción', '~día 14'),
        (todayFrac, 'Hoy', 'día $daysSince'),
        (1.0, 'Parto', 'día $totalDays'),
      ]..sort((a, b) => a.$1.compareTo(b.$1));

      return SizedBox(
        height: 88,
        child: Stack(
          children: [
            Positioned(
              left: 6,
              right: 6,
              top: 2,
              child: Container(height: 3, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
            ),
            Positioned(
              left: 6,
              top: 2,
              width: (width - 12) * todayFrac,
              child: Container(height: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
            ),
            dot(0, accent),
            dot(conceptionFrac, gold),
            dot(todayFrac, accent),
            dot(1, Colors.white.withOpacity(0.4)),
            for (int i = 0; i < points.length; i++)
              labelBelow(points[i].$1, points[i].$2, points[i].$3, secondRow: i.isOdd),
          ],
        ),
      );
    });
  }
}

/// Gráfica de barras con la distribución aproximada de en qué semana
/// suelen nacer los bebés, para la tarjeta "Fecha de parto". Valores
/// referenciales (no son datos médicos exactos), pensados solo para dar
/// contexto de que la fecha calculada es una probabilidad, no una fecha
/// fija.
class _BirthDistributionChart extends StatelessWidget {
  final Color accent;
  final Color gold;
  final bool isTwins;

  const _BirthDistributionChart({required this.accent, required this.gold, this.isTwins = false});

  static const _weeksSingle = [37, 38, 39, 40, 41, 42];
  static const _pctsSingle = [5, 15, 25, 25, 20, 10];

  // Distribución referencial de mellizos/gemelos: se concentra bastante
  // antes que en un embarazo único, la mayoría nace entre las semanas 35 y
  // 38 (muy pocos llegan a la 39).
  static const _weeksTwins = [33, 34, 35, 36, 37, 38, 39];
  static const _pctsTwins = [5, 10, 15, 20, 25, 20, 5];

  List<int> get _weeks => isTwins ? _weeksTwins : _weeksSingle;
  List<int> get _pcts => isTwins ? _pctsTwins : _pctsSingle;
  int get _peakWeek => isTwins ? 37 : 40;

  @override
  Widget build(BuildContext context) {
    final maxPct = _pcts.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < _weeks.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${_pcts[i]}%', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Container(
                          height: 70 * (_pcts[i] / maxPct),
                          decoration: BoxDecoration(
                            color: _weeks[i] == _peakWeek ? gold : accent.withOpacity(0.55),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('sem\n${_weeks[i]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: PregnancyTrackingScreen._textMuted, height: 1.2)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isTwins
              ? 'Distribución aproximada y referencial de la semana de nacimiento de mellizos/gemelos — la mayoría nace entre las semanas 36 y 38.'
              : 'Distribución aproximada y referencial de la semana de nacimiento — la mayoría de los bebés nace entre las semanas 39 y 41.',
          style: const TextStyle(fontSize: 11, color: PregnancyTrackingScreen._textMuted, height: 1.4),
        ),
      ],
    );
  }
}

/// Barra segmentada por trimestre con un marcador en la semana actual,
/// para la tarjeta "Cuenta atrás".
class _TrimesterProgressChart extends StatelessWidget {
  final int weeks;
  final int totalWeeks;
  final Color accent;

  const _TrimesterProgressChart({required this.weeks, required this.totalWeeks, required this.accent});

  @override
  Widget build(BuildContext context) {
    final frac = (weeks / totalWeeks).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          return SizedBox(
            height: 36,
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Expanded(flex: 13, child: Container(height: 10, decoration: const BoxDecoration(color: Color(0xFFFF6B6B), borderRadius: BorderRadius.horizontal(left: Radius.circular(6))))),
                      const SizedBox(width: 1.5),
                      Expanded(flex: 14, child: Container(height: 10, color: const Color(0xFF9775FA))),
                      const SizedBox(width: 1.5),
                      Expanded(flex: 13, child: Container(height: 10, decoration: const BoxDecoration(color: Color(0xFF51CF66), borderRadius: BorderRadius.horizontal(right: Radius.circular(6))))),
                    ],
                  ),
                ),
                Positioned(
                  left: (width * frac).clamp(6.0, width - 6.0) - 6,
                  top: 0,
                  child: Column(
                    children: [
                      Icon(Icons.arrow_drop_down, color: accent, size: 22),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        const Row(
          children: [
            Expanded(child: Text('1er trimestre', style: TextStyle(fontSize: 9.5, color: PregnancyTrackingScreen._textMuted))),
            Expanded(child: Text('2do trimestre', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: PregnancyTrackingScreen._textMuted))),
            Expanded(child: Text('3er trimestre', textAlign: TextAlign.end, style: TextStyle(fontSize: 9.5, color: PregnancyTrackingScreen._textMuted))),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Estás en la semana $weeks de $totalWeeks — ${(frac * 100).round()}% del camino recorrido.',
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

