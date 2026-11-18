import 'package:flutter/material.dart';

import '../cicloplus_host.dart';
import '../cicloplus_links.dart';
import '../data/store.dart';
import '../strings.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/michi_jokes.dart';
import '../widgets/ui.dart';
import 'extras.dart';
import 'michi_extras.dart';
import 'michi_more.dart';
import 'michi_wardrobe.dart';
import 'more.dart';
import 'register.dart';
import 'shell.dart';

/// Buscador de la app: escribes lo que necesitas ("ovulación", "pareja",
/// "pin", "informe para el médico"…) y te lleva directo. Michi solo pone la
/// carita y una frase; lo importante son las funciones del ciclo. Solo
/// aparecen las que sirven para su objetivo.
class _Entry {
  const _Entry(this.icon, this.title, this.desc, this.keys, this.open, {this.goals});
  final IconData icon;
  final String Function() title;
  final String Function() desc;
  final String keys; // palabras clave en español e inglés
  final void Function(BuildContext) open;
  final Set<String>? goals; // null = todas

  bool get visible => goals == null || goals!.contains(AppStore.instance.goal);
}

void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));
void _tab(BuildContext c, int t) {
  Navigator.of(c).popUntil((r) => r.isFirst);
  ShellState.current?.go(t);
}

const _cycle = {'track', 'conceive'};

final List<_Entry> _entries = [
  _Entry(Icons.edit_note_rounded, () => tr('Registrar mi día', 'Log my day'), () => tr('Regla, síntomas, ánimo, flujo y notas', 'Period, symptoms, mood, flow and notes'),
      'registrar apuntar regla periodo sangrado flujo sintomas dolor colicos animo humor log period bleeding flow symptoms pain cramps mood note',
      (c) => _push(c, RegisterScreen(day: DateTime.now()))),
  _Entry(Icons.calendar_month_rounded, () => tr('Calendario', 'Calendar'), () => tr('Tus días, regla prevista y días fértiles', 'Your days, predicted period and fertile days'),
      'calendario fechas mes dias prevision prediccion calendar dates month days prediction', (c) => _tab(c, 1)),
  _Entry(Icons.water_drop_rounded, () => tr('Periodo y ciclo', 'Period & cycle'), () => tr('Duración de tu regla y de tu ciclo', 'Length of your period and cycle'),
      'periodo regla ciclo duracion irregular retraso cuando me viene period cycle length late irregular', (c) => _push(c, const PeriodCycleScreen()),
      goals: _cycle),
  _Entry(Icons.notifications_active_rounded, () => tr('Recordatorios', 'Reminders'), () => tr('Avisos de regla, ovulación, píldora, agua…', 'Period, ovulation, pill, water alerts…'),
      'recordatorio aviso notificacion alarma pildora anticonceptivo agua dormir reminder alert notification alarm pill water',
      (c) => _tab(c, 2)),
  _Entry(Icons.bar_chart_rounded, () => tr('Análisis del ciclo', 'Cycle analysis'), () => tr('Ciclo, síntomas y estado de ánimo', 'Cycle, symptoms and mood'),
      'analisis estadisticas graficos numeros media promedio analysis statistics charts average', (c) => _push(c, const AnalysisScreen()),
      goals: _cycle),
  _Entry(Icons.show_chart_rounded, () => tr('Tendencias y bienestar', 'Trends & wellbeing'), () => tr('Energía, ánimo, sueño y dolor', 'Energy, mood, sleep and pain'),
      'tendencias bienestar energia sueño dormir cansancio trends wellbeing energy sleep tired', (c) => _push(c, const TrendsScreen())),
  _Entry(Icons.picture_as_pdf_rounded, () => tr('Informe del ciclo', 'Cycle report'), () => tr('Resumen completo para ti o para tu médico', 'Full summary for you or your doctor'),
      'informe resumen medico doctor ginecologo pdf exportar compartir report summary doctor gynecologist export', (c) => _push(c, const ReportScreen()),
      goals: _cycle),
  _Entry(Icons.history_rounded, () => tr('Cronología', 'Timeline'), () => tr('Todo lo que has registrado, día a día', 'Everything you logged, day by day'),
      'cronologia historial pasado anterior registros timeline history past logs', (c) => _push(c, const TimelineScreen())),
  _Entry(Icons.favorite_border_rounded, () => tr('Mi salud', 'My health'), () => tr('Peso, temperatura, autoexamen y más', 'Weight, temperature, self-exam and more'),
      'salud peso tension mamas autoexamen health weight blood pressure breast exam', (c) => _push(c, const MyHealthScreen())),
  _Entry(Icons.science_rounded, () => tr('Test de ovulación', 'Ovulation test'), () => tr('Apunta tus tiras de LH', 'Log your LH strips'),
      'test ovulacion lh tira fertil quedarme embarazada ovulation test strip', (c) => CP.openOvulationTest(c), goals: {'conceive'}),
  _Entry(Icons.thermostat_rounded, () => tr('Temperatura basal', 'Basal temperature'), () => tr('Tu temperatura cada mañana', 'Your temperature every morning'),
      'temperatura basal termometro grados basal temperature thermometer', (c) => CicloYo.field(c, 'temperature'), goals: {'conceive'}),
  _Entry(Icons.spa_rounded, () => tr('Fertilidad', 'Fertility'), () => tr('Tus días fértiles y tu ovulación', 'Your fertile days and ovulation'),
      'fertilidad fertil ovulacion concebir quedarme embarazada bebe fertility fertile ovulation conceive get pregnant',
      (c) => CicloYo.summary(c, 'fertility'), goals: {'conceive'}),
  _Entry(Icons.child_friendly_rounded, () => tr('Mi embarazo', 'My pregnancy'), () => tr('Cómo está tu bebé semana a semana', 'How your baby is doing week by week'),
      'embarazo bebe semana parto fecha tamaño pregnancy baby week due date size', (c) => CP.openPregnancy(c), goals: {'pregnancy'}),
  _Entry(Icons.people_alt_rounded, () => tr('Mi pareja', 'My partner'), () => tr('Invita a tu pareja y compartid el ciclo', 'Invite your partner and share your cycle'),
      'pareja novio novia marido esposo compartir invitar codigo vincular chat deseos partner boyfriend husband share invite code link',
      (c) => CP.openPartner(c)),
  _Entry(Icons.lock_rounded, () => tr('Bloqueo con PIN o huella', 'PIN or fingerprint lock'), () => tr('Protege la app con tu PIN', 'Protect the app with your PIN'),
      'pin bloqueo contraseña huella face id privacidad seguridad lock password fingerprint privacy security', (c) => CP.togglePin(c)),
  _Entry(Icons.settings_rounded, () => tr('Configuración', 'Settings'), () => tr('Idioma, tema, avisos discretos, copia de seguridad…', 'Language, theme, discreet alerts, backup…'),
      'configuracion ajustes idioma lengua tema color copia seguridad exportar importar backup datos discreto perimenopausia settings language theme backup export import data discreet perimenopause',
      (c) => openCicloSettings(c)),
  _Entry(Icons.face_3_rounded, () => tr('Tu avatar', 'Your avatar'), () => tr('Elige cómo te ves en la pantalla de inicio', 'Choose how you appear on the home screen'),
      'avatar foto perfil imagen cara avatar photo profile picture', (c) => showAvatarPicker(c)),
  _Entry(Icons.account_circle_rounded, () => tr('Mi cuenta', 'My account'), () => tr('Correo, sesión y datos de la cuenta', 'Email, session and account details'),
      'cuenta correo email sesion cerrar sesion borrar cuenta account email sign out delete account', (c) => CP.openAccount(c)),
  _Entry(Icons.workspace_premium_rounded, () => tr('CicloPlus Premium', 'CicloPlus Premium'), () => tr('Funciones extra', 'Extra features'),
      'premium suscripcion pagar quitar anuncios subscription pay remove ads', (c) => CP.openPremium(c)),
  _Entry(Icons.air_rounded, () => tr('Respira con Michi', 'Breathe with Michi'), () => tr('Un minuto para calmarte', 'One minute to calm down'),
      'respirar respiracion calma ansiedad estres nervios relajarme breathe breathing calm anxiety stress relax', (c) => _push(c, const MichiBreatheScreen())),
  _Entry(Icons.menu_book_rounded, () => tr('Diario', 'Diary'), () => tr('Cuéntale tu día a Michi', 'Tell Michi about your day'),
      'diario notas escribir sentimientos diary notes write feelings', (c) => _push(c, const MichiDiaryScreen())),
  _Entry(Icons.flag_rounded, () => tr('Retos', 'Challenges'), () => tr('Pequeños hábitos de 7 días', 'Small 7-day habits'),
      'retos habitos agua caminar dormir challenges habits', (c) => _push(c, const MichiChallengeScreen())),
  _Entry(Icons.emoji_events_rounded, () => tr('Logros', 'Badges'), () => tr('Lo que has conseguido', 'What you have achieved'),
      'logros medallas premios insignias badges achievements', (c) => _push(c, const MichiBadgesScreen())),
  _Entry(Icons.mail_outline_rounded, () => tr('Cartas de Michi', 'Letters from Michi'), () => tr('Tu resumen de cada mes', 'Your summary of each month'),
      'carta cartas resumen mes letter summary month', (c) => _push(c, const MichiLetterScreen())),
  _Entry(Icons.checkroom_rounded, () => tr('Armario de Michi', "Michi's wardrobe"), () => tr('Elige qué se pone Michi', 'Choose what Michi wears'),
      'armario ropa vestir michi gato wardrobe clothes', (c) => _push(c, const MichiWardrobeScreen())),
  _Entry(Icons.sentiment_very_satisfied_rounded, () => tr('Chiste de Michi', "Michi's joke"), () => tr('Uno al día para sonreír', 'One a day to make you smile'),
      'chiste broma reir gracioso risa joke funny laugh', (c) => MichiJokes.show(c)),
  _Entry(Icons.medical_services_outlined, () => tr('Kit para la regla', 'Period kit'), () => tr('Consejos para los días de dolor', 'Tips for painful days'),
      'kit dolor colicos calambres regla duele remedio pain cramps hurts remedy', (c) => showMichiPeriodKit(c), goals: _cycle),
];

String _norm(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

List<_Entry> _search(String q) {
  final words = _norm(q).split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
  final list = _entries.where((e) => e.visible).toList();
  if (words.isEmpty) return const [];
  final scored = <(_Entry, int)>[];
  for (final e in list) {
    final title = _norm(e.title());
    final hay = '$title ${_norm(e.desc())} ${e.keys}';
    var score = 0;
    for (final w in words) {
      if (title.contains(w)) {
        score += 5;
      } else if (hay.split(' ').any((k) => k.startsWith(w))) {
        score += 3;
      } else if (hay.contains(w)) {
        score += 1;
      }
    }
    if (score > 0) scored.add((e, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return scored.map((x) => x.$1).toList();
}

class MichiSearchScreen extends StatefulWidget {
  const MichiSearchScreen({super.key});

  @override
  State<MichiSearchScreen> createState() => _MichiSearchScreenState();
}

class _MichiSearchScreenState extends State<MichiSearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<String> get _suggestions => switch (AppStore.instance.goal) {
        'pregnancy' => [tr('Mi embarazo', 'My pregnancy'), tr('Mi pareja', 'My partner'), tr('Recordatorios', 'Reminders'), tr('Respira con Michi', 'Breathe with Michi')],
        'conceive' => [tr('Test de ovulación', 'Ovulation test'), tr('Fertilidad', 'Fertility'), tr('Temperatura basal', 'Basal temperature'), tr('Calendario', 'Calendar')],
        _ => [tr('Registrar mi día', 'Log my day'), tr('Calendario', 'Calendar'), tr('Informe del ciclo', 'Cycle report'), tr('Recordatorios', 'Reminders')],
      };

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim();
    final results = _search(q);
    return Scaffold(
      backgroundColor: C.pinkBg,
      appBar: AppBar(
        backgroundColor: C.pinkBg,
        foregroundColor: C.pinkDark,
        elevation: 0,
        title: Text(tr('Buscar', 'Search'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Michi solo acompaña: carita pequeña y una frase.
          Row(children: [
            const Img('michi_happy', size: 54, fallback: Icons.pets_rounded),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  q.isEmpty
                      ? tr('¿Qué buscas? Dímelo y te llevo 🐾', "What are you looking for? Tell me and I'll take you there 🐾")
                      : results.isEmpty
                          ? tr('Mmm… no lo encuentro. Prueba con otra palabra 🐾', "Hmm… I can't find it. Try another word 🐾")
                          : tr('¡Lo encontré! Toca para ir 🐾', 'Found it! Tap to go 🐾'),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: C.text),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _q,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (results.isNotEmpty) results.first.open(context);
            },
            decoration: InputDecoration(
              hintText: tr('Ej. ovulación, pareja, informe…', 'E.g. ovulation, partner, report…'),
              prefixIcon: Icon(Icons.search_rounded, color: C.pink),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _q.clear()),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pinkLine)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pinkLine)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: C.pink, width: 1.6)),
            ),
          ),
          const SizedBox(height: 14),
          if (q.isEmpty) ...[
            Text(tr('Lo más usado', 'Most used'), style: TextStyle(fontWeight: FontWeight.w900, color: C.pinkDark)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s, style: TextStyle(fontWeight: FontWeight.w800, color: C.pinkDark)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: C.pinkLine),
                  onPressed: () => setState(() {
                    _q.text = s;
                    _q.selection = TextSelection.collapsed(offset: s.length);
                  }),
                ),
            ]),
          ] else
            for (final e in results)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: card(),
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: C.pinkSoft, borderRadius: BorderRadius.circular(12)),
                    child: Icon(e.icon, color: C.pink),
                  ),
                  title: Text(e.title(), style: const TextStyle(fontWeight: FontWeight.w900, color: C.text)),
                  subtitle: Text(e.desc()),
                  trailing: Icon(Icons.chevron_right_rounded, color: C.pink),
                  onTap: () => e.open(context),
                ),
              ),
        ],
      ),
    );
  }
}
