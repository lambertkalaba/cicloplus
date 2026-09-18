import 'package:flutter/material.dart';

import '../data/pregnancy_week_info.dart';
import '../services/settings_service.dart' show SettingsService, themeById;
import 'pregnancy_tracking_screen.dart' show pregnancyDayImagePath;

/// "Simulacro" del embarazo: deja a la madre mover una rueda de semanas
/// (1 a 40) para adelantar o retroceder en el tiempo y ver, para esa
/// semana concreta, la foto del bebé, una imagen de cómo va creciendo la
/// barriga, una explicación del desarrollo y un consejo — sin depender de
/// la fecha real de hoy. Pedido explícito de la usuaria: quiere poder
/// "verlo adelantado" para conocer todo el recorrido del embarazo, no
/// solo el día actual.
///
/// Se abre desde un botón en PregnancyTrackingScreen. La semana inicial es
/// la semana actual real (calculada igual que en esa pantalla), pero a
/// partir de ahí es un estado propio e independiente — mover la rueda
/// aquí NUNCA cambia la fecha real de última regla guardada.
class PregnancySimulatorScreen extends StatefulWidget {
  final DateTime lmp;
  final String themeId;

  /// true si es un embarazo múltiple (mellizos/gemelos) — ver
  /// PregnancySettings.isTwins. Limita la rueda de semanas a 37 en vez de
  /// 40, que es la duración total usada en PregnancyTrackingScreen para
  /// este caso.
  final bool isTwins;

  const PregnancySimulatorScreen({super.key, required this.lmp, required this.themeId, this.isTwins = false});

  @override
  State<PregnancySimulatorScreen> createState() => _PregnancySimulatorScreenState();
}

class _PregnancySimulatorScreenState extends State<PregnancySimulatorScreen> {
  static const _bgColor = Color(0xFF0F0F14);
  static const _cardColor = Color(0xFF1A1A22);
  static const _textMuted = Color(0xFFA7A6B3);
  static const _gold = Color(0xFFFFC078);

  static const _monthShort = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  late int _currentRealWeek;
  late int _week;
  int get _totalWeeks => widget.isTwins ? 37 : 40;
  // Apariencia de las fotos de barriga ('default' | 'black'), elegida por la
  // usuaria y persistida vía SettingsService — pedido explícito: además de
  // la serie original, existe una segunda serie con una mujer negra
  // (assets/pregnancy_belly_black/) y debe poder elegirse desde aquí.
  String _bellyAppearance = 'default';
  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final rawDaysSince = todayMidnight.difference(DateTime(widget.lmp.year, widget.lmp.month, widget.lmp.day)).inDays;
    final daysSince = rawDaysSince < 0 ? 0 : rawDaysSince;
    _currentRealWeek = ((daysSince / 7).floor() + 1).clamp(1, _totalWeeks);
    _week = _currentRealWeek;
    _loadBellyAppearance();
  }

  Future<void> _loadBellyAppearance() async {
    final saved = await _settings.loadBellyAppearance();
    if (mounted) setState(() => _bellyAppearance = saved);
  }

  void _setBellyAppearance(String value) {
    if (value == _bellyAppearance) return;
    setState(() => _bellyAppearance = value);
    _settings.saveBellyAppearance(value);
  }

  // Día representativo (0-indexado desde la LMP) para la semana elegida:
  // usamos un punto intermedio de la semana (día 3 de 0-6) para la foto
  // del bebé, en vez del primer día, para que se vea más representativo.
  //
  // _brokenDaySlots: en este dispositivo concreto, ciertos índices de día
  // renderizan mal de forma reproducible (solo se ve una porción del
  // círculo, el resto queda negro/cortado) sin importar qué bytes de
  // imagen tengan — es un bug del pipeline Flutter/Skia ligado al índice,
  // no al contenido del archivo. Confirmado para el día 16/17 (semana 3),
  // el día 10 (semana 2) y el día 3 (semana 1). Como workaround, cuando
  // el día representativo cae en uno de estos índices "malditos", lo
  // desplazamos a un día vecino seguro (con la misma foto copiada a ese
  // nuevo día) en vez de usar el índice roto.
  static const Map<int, int> _brokenDaySlots = {
    3: 6, // semana 1
    10: 13, // semana 2
    16: 19, // semana 3 (y el 17, su vecino, también está roto)
    17: 19,
  };

  int _representativeDaysSince(int week) {
    final raw = (week - 1) * 7 + 3;
    return _brokenDaySlots[raw] ?? raw;
  }

  String _formatDate(DateTime d) => '${d.day} ${_monthShort[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final primary = Color(themeById(widget.themeId).primary);
    final info = pregnancyWeekInfoFor(_week);
    final weekStartDate = widget.lmp.add(Duration(days: (_week - 1) * 7));

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _buildWeekSliderCard(primary, weekStartDate),
                  const SizedBox(height: 16),
                  _buildImagesRow(primary),
                  const SizedBox(height: 10),
                  _buildAppearancePicker(primary),
                  const SizedBox(height: 16),
                  _buildTextCard(
                    icon: Icons.auto_awesome,
                    iconColor: _gold,
                    title: 'Cómo se desarrolla tu bebé',
                    text: info.development,
                  ),
                  const SizedBox(height: 16),
                  _buildTextCard(
                    icon: Icons.favorite,
                    iconColor: primary,
                    title: 'Consejo para esta semana',
                    text: info.tip,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Simulacro del embarazo',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
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
    );
  }

  Widget _buildWeekSliderCard(Color primary, DateTime weekStartDate) {
    final isCurrentWeek = _week == _currentRealWeek;
    final size = pregnancyWeekInfoFor(_week).size;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('Semana', style: TextStyle(fontSize: 13, color: _textMuted)),
              const SizedBox(width: 8),
              Text(
                '$_week',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0),
              ),
              Text(' / $_totalWeeks', style: const TextStyle(fontSize: 15, color: _textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'aprox. ${_formatDate(weekStartDate)}',
            style: const TextStyle(fontSize: 12.5, color: _textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            // Antes de la semana 4 (implantación) todavía no hay un
            // embrión con un tamaño comparable a algo, así que se muestra
            // la frase tal cual en vez de forzar el prefijo "Del tamaño de".
            _week >= 4 ? 'Del tamaño de $size' : size,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primary,
              inactiveTrackColor: Colors.white.withOpacity(0.12),
              thumbColor: primary,
              overlayColor: primary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _week.toDouble(),
              min: 1,
              max: _totalWeeks.toDouble(),
              divisions: _totalWeeks - 1,
              label: 'Semana $_week',
              onChanged: (v) => setState(() => _week = v.round()),
            ),
          ),
          if (!isCurrentWeek)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextButton.icon(
                onPressed: () => setState(() => _week = _currentRealWeek),
                icon: Icon(Icons.today, size: 16, color: primary),
                label: Text('Volver a hoy (semana $_currentRealWeek)', style: TextStyle(color: primary, fontSize: 12.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagesRow(Color primary) {
    final daysSince = _representativeDaysSince(_week);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _imageCard(
            label: 'Tu bebé',
            // Las fotos día a día ya traen su propia viñeta circular
            // (fondo negro + círculo), así que un círculo aquí encaja con
            // el contenido en vez de recortarlo.
            circular: true,
            child: Image.asset(pregnancyDayImagePath(daysSince), fit: BoxFit.cover),
            primary: primary,
            // Pedido explícito: al tocar la foto del bebé, verla completa
            // (a pantalla completa, con zoom) en vez de solo el recorte
            // circular chiquito de la tarjeta.
            onTap: () => _openFullImage(
              // Usamos la carpeta "_full" (versión ampliada y con nitidez
              // mejorada) en vez de la miniatura chiquita de la tarjeta,
              // para que no se vea borrosa al agrandarla a pantalla
              // completa. Mismo nombre de archivo, solo cambia la carpeta.
              pregnancyDayImagePath(daysSince).replaceFirst(
                'assets/pregnancy_days/',
                'assets/pregnancy_days_full/',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _imageCard(
            label: 'Tu barriga',
            // La foto de barriga es un retrato normal (no viene con
            // viñeta circular): un círculo le cortaba la cabeza y las
            // piernas. Con una tarjeta redondeada se ve la foto completa
            // de hombros a cadera, igual que en un recorte cuadrado.
            circular: false,
            child: Image.asset(
              pregnancyBellyImagePath(_week, appearance: _bellyAppearance),
              fit: BoxFit.cover,
              // Pedido explícito: no importa que se corte la cara, lo que
              // debe verse bien es la barriga. bottomCenter prioriza la
              // mitad de abajo de la foto (barriga) en vez del centro —
              // igual para las dos series (clara/morena), aunque tengan
              // encuadres de origen ligeramente distintos, para que el
              // resultado se vea igual de bien en ambas.
              alignment: Alignment.bottomCenter,
              // La barriga se genera semana a semana como un proyecto
              // aparte (ver tarea de generación de imágenes); mientras
              // una semana concreta no tenga foto todavía, mostramos un
              // resumen visual simple en vez de romper la pantalla.
              errorBuilder: (context, error, stackTrace) => _bellyFallback(primary),
            ),
            primary: primary,
          ),
        ),
      ],
    );
  }

  // Selector pequeño para elegir qué serie de fotos de barriga usar. Dos
  // opciones nada más (por ahora): 'default' (serie original) y 'black'
  // (segunda serie generada a pedido de la usuaria). Centrado, discreto,
  // debajo de las fotos — no es un ajuste que necesite su propia pantalla.
  Widget _buildAppearancePicker(Color primary) {
    Widget chip(String value, String label) {
      final selected = _bellyAppearance == value;
      return GestureDetector(
        onTap: () => _setBellyAppearance(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(0.18) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? primary : Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? primary : _textMuted,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip('default', 'Piel clara'),
        const SizedBox(width: 10),
        chip('black', 'Piel morena'),
      ],
    );
  }

  Widget _bellyFallback(Color primary) {
    // Círculo que crece con la semana (1/40 a 40/40) como aproximación
    // visual simple mientras no exista todavía la foto real de esa semana.
    final growth = (_week / _totalWeeks).clamp(0.15, 1.0);
    return Container(
      color: const Color(0xFF20202A),
      alignment: Alignment.center,
      child: Container(
        width: 90 * growth,
        height: 90 * growth,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary.withOpacity(0.55), _gold.withOpacity(0.55)],
          ),
        ),
      ),
    );
  }

  Widget _imageCard({
    required String label,
    required Widget child,
    required Color primary,
    bool circular = true,
    VoidCallback? onTap,
  }) {
    const rectRadius = 22.0;
    final frame = AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(rectRadius + 3),
          gradient: LinearGradient(colors: [primary.withOpacity(0.6), _gold.withOpacity(0.4)]),
        ),
        child: circular
            ? ClipOval(
                child: Container(color: const Color(0xFF20202A), child: child),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(rectRadius),
                child: Container(color: const Color(0xFF20202A), child: child),
              ),
      ),
    );
    return Column(
      children: [
        onTap == null
            ? frame
            : GestureDetector(onTap: onTap, child: frame),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Abre la foto del bebé a pantalla completa (fondo negro, con zoom vía
  // InteractiveViewer) cuando la usuaria toca la tarjeta circular chiquita.
  // Pedido explícito: quiere poder ver la foto completa, no solo el
  // recorte pequeño de la tarjeta.
  void _openFullImage(String assetPath) {
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
                        // Las fotos fuente son miniaturas pequeñas (~114px),
                        // así que forzamos el Image a ocupar todo el
                        // espacio disponible (SizedBox.expand) para que
                        // BoxFit.contain la agrande hasta llenar la
                        // pantalla en vez de mostrarla en su tamaño
                        // original diminuto.
                        child: SizedBox.expand(
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
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

  Widget _buildTextCard({required IconData icon, required Color iconColor, required String title, required String text}) {
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
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _textMuted, letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontSize: 13.5, color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }
}
