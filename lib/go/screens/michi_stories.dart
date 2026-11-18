import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/store.dart';
import '../strings.dart';
import '../widgets/ui.dart';

/// "Cuentos de Michi": un cuento por capítulos. Cada día que registras se
/// desbloquea un capítulo nuevo (el primero es gratis). No se pierden nunca,
/// aunque se rompa la racha.
enum StoryFx { petals, sparkles, bubbles, rain, hearts, stars, candy, balloons, leaves, snow, sun, tropical }

class StoryChapter {
  final String Function() title;
  final String Function() text;
  final String bg; // postal de fondo (jpg)
  final String pose; // postura de Michi (png)
  final StoryFx fx;
  const StoryChapter(this.title, this.text, this.bg, this.pose, this.fx);
}

class MichiStories {
  MichiStories._();

  static const _readKey = 'michi_story_read';

  static final chapters = <StoryChapter>[
    StoryChapter(() => tr('Una carta bajo la puerta', 'A letter under the door'),
        () => tr('Una mañana, Michi encontró una carta bajo la puerta. Tenía un dibujo de la luna y decía: «Quien cuide con cariño a su persona favorita, podrá visitarme». Michi te miró… y supo que esa persona eras tú.',
            'One morning, Michi found a letter under the door. It had a drawing of the moon and said: "Whoever lovingly looks after their favourite person may come and visit me." Michi looked at you… and knew that person was you.'),
        'post_garden', 'michi_letter', StoryFx.sparkles),
    StoryChapter(() => tr('La mochila', 'The backpack'),
        () => tr('Michi preparó su mochila: un ovillo, tres galletas de pescado y una foto tuya. «Para no sentirme solo», susurró. Y salió al jardín con la cola bien alta.',
            'Michi packed his backpack: a ball of yarn, three fish biscuits and a photo of you. "So I don\'t feel alone," he whispered. And he went out into the garden with his tail held high.'),
        'post_garden', 'michi_motivated', StoryFx.petals),
    StoryChapter(() => tr('El jardín que habla', 'The talking garden'),
        () => tr('En el jardín, las flores se giraron para saludarlo. Una margarita le dijo: «Para llegar a la luna, sigue el río y nunca te rindas». Michi le dio las gracias con un ronroneo.',
            'In the garden, the flowers turned to greet him. A daisy told him: "To reach the moon, follow the river and never give up." Michi thanked her with a purr.'),
        'post_garden', 'michi_flowers', StoryFx.petals),
    StoryChapter(() => tr('La mariposa perdida', 'The lost butterfly'),
        () => tr('Una mariposa lloraba porque no encontraba a su familia. Michi la acompañó hasta el rosal más grande, donde la esperaban. «La bondad siempre vuelve», le dijo la mariposa.',
            'A butterfly was crying because she couldn\'t find her family. Michi walked with her to the biggest rose bush, where they were waiting. "Kindness always comes back," the butterfly told him.'),
        'post_garden', 'michi_flower', StoryFx.sparkles),
    StoryChapter(() => tr('El puente del río', 'The river bridge'),
        () => tr('El puente de madera crujía y a Michi le temblaban las patitas. Respiró hondo, como tú le enseñaste, y paso a paso lo cruzó. Los peces aplaudieron con sus aletas.',
            'The wooden bridge creaked and Michi\'s little paws were shaking. He took a deep breath, just like you taught him, and crossed it step by step. The fish clapped their fins.'),
        'post_bridge', 'cat_walk', StoryFx.bubbles),
    StoryChapter(() => tr('La tormenta', 'The storm'),
        () => tr('De pronto empezó a llover. Michi se refugió bajo una hoja enorme y pensó en ti. «Las tormentas también pasan», se dijo. Y al rato salió un arcoíris.',
            'Suddenly it started to rain. Michi sheltered under a huge leaf and thought of you. "Storms pass too," he told himself. And soon a rainbow appeared.'),
        'post_bridge', 'michi_tired', StoryFx.rain),
    StoryChapter(() => tr('La colina de los globos', 'Balloon hill'),
        () => tr('En la colina había globos de todos los colores. Michi saltó y saltó hasta atrapar uno rosa. Con él, flotó un ratito por encima de las nubes.',
            'On the hill there were balloons of every colour. Michi jumped and jumped until he caught a pink one. Holding it, he floated above the clouds for a little while.'),
        'post_hill', 'cat_play', StoryFx.balloons),
    StoryChapter(() => tr('Una nueva amiga', 'A new friend'),
        () => tr('Allí conoció a Luna, una gatita blanca que coleccionaba estrellas. «¿Vas al palacio de la luna? ¡Yo te enseño el camino!». Desde ese día viajaron juntos.',
            'There he met Luna, a little white cat who collected stars. "Are you going to the moon palace? I\'ll show you the way!" From that day on, they travelled together.'),
        'post_hill', 'michi_happy', StoryFx.hearts),
    StoryChapter(() => tr('El castillo en las nubes', 'The castle in the clouds'),
        () => tr('El castillo estaba hecho de nubes de algodón. El rey Nube les ofreció chocolate caliente y les contó un secreto: «La luna brilla más cuando alguien la espera».',
            'The castle was made of cotton clouds. King Cloud offered them hot chocolate and told them a secret: "The moon shines brighter when someone is waiting for it."'),
        'post_castle', 'michi_crown', StoryFx.sparkles),
    StoryChapter(() => tr('La siesta real', 'The royal nap'),
        () => tr('Después de tanto caminar, Michi y Luna durmieron en una cama de nubes. Michi soñó contigo y sonrió en sueños. Descansar también es parte del viaje.',
            'After so much walking, Michi and Luna slept on a bed of clouds. Michi dreamed of you and smiled in his sleep. Resting is part of the journey too.'),
        'post_castle', 'michi_bed', StoryFx.stars),
    StoryChapter(() => tr('La playa rosa', 'The pink beach'),
        () => tr('Al despertar, una nube los dejó en una playa de arena rosa. Las olas sonaban como un ronroneo gigante. Michi metió las patitas en el agua y se rió.',
            'When they woke up, a cloud set them down on a beach of pink sand. The waves sounded like a giant purr. Michi dipped his paws in the water and laughed.'),
        'post_beach', 'michi_calm', StoryFx.bubbles),
    StoryChapter(() => tr('La caracola que canta', 'The singing seashell'),
        () => tr('Luna encontró una caracola que cantaba canciones antiguas. Una decía: «Cada día que te cuidas es un paso hacia la luna». Michi se la aprendió de memoria.',
            'Luna found a seashell that sang old songs. One of them went: "Every day you look after yourself is a step towards the moon." Michi learned it by heart.'),
        'post_beach', 'michi_party', StoryFx.sparkles),
    StoryChapter(() => tr('El bosque de caramelos', 'The candy forest'),
        () => tr('Los árboles eran de piruleta y el río de batido de fresa. Michi probó un poquito de todo… ¡y le dolió la barriga! Aprendió que lo dulce, mejor en pequeñas dosis.',
            'The trees were lollipops and the river was a strawberry milkshake. Michi tried a little of everything… and got a tummy ache! He learned that sweet things are best in small doses.'),
        'post_candy', 'michi_snack', StoryFx.candy),
    StoryChapter(() => tr('El laberinto', 'The maze'),
        () => tr('En el centro del bosque había un laberinto. Michi se perdió, pero miró tu foto, se tranquilizó y encontró la salida.',
            'In the middle of the forest there was a maze. Michi got lost, but he looked at your photo, calmed down and found the way out.'),
        'post_candy', 'cat_walk', StoryFx.petals),
    StoryChapter(() => tr('El lago de las estrellas', 'The starry lake'),
        () => tr('Llegaron a un lago donde se reflejaban mil estrellas. Un barquito de papel los esperaba. Remaron en silencio, escuchando el agua.',
            'They reached a lake that reflected a thousand stars. A little paper boat was waiting for them. They rowed in silence, listening to the water.'),
        'post_lake', 'michi_calm', StoryFx.stars),
    StoryChapter(() => tr('La estrella fugaz', 'The shooting star'),
        () => tr('Una estrella fugaz cayó cerca del barco. Michi la atrapó con cuidado y pidió un deseo: «Que mi persona favorita sea siempre feliz».',
            'A shooting star fell near the boat. Michi caught it carefully and made a wish: "May my favourite person always be happy."'),
        'post_lake', 'michi_motivated', StoryFx.stars),
    StoryChapter(() => tr('Luna se despide', 'Luna says goodbye'),
        () => tr('Luna tenía que volver con su familia. Se abrazaron fuerte. «Las amigas de verdad siempre se encuentran», le dijo. Michi le regaló su estrella.',
            'Luna had to go back to her family. They hugged tightly. "True friends always find each other," she said. Michi gave her his star.'),
        'post_lake', 'michi_heart', StoryFx.hearts),
    StoryChapter(() => tr('La escalera de luz', 'The staircase of light'),
        () => tr('Al final del lago apareció una escalera de luz que subía al cielo. Tenía cien escalones. Michi los subió uno a uno, sin prisa, como se hacen las cosas importantes.',
            'At the end of the lake, a staircase of light appeared, climbing up to the sky. It had a hundred steps. Michi climbed them one by one, unhurried, the way important things are done.'),
        'post_moon', 'cat_walk', StoryFx.sparkles),
    StoryChapter(() => tr('El palacio de la luna', 'The moon palace'),
        () => tr('La Luna lo recibió con una sonrisa enorme. «Has llegado porque nunca dejaste de cuidar a tu persona», le dijo. Y le regaló un poquito de su brillo.',
            'The Moon welcomed him with a huge smile. "You made it because you never stopped looking after your person," she said. And she gave him a little of her glow.'),
        'post_moon', 'michi_crown', StoryFx.stars),
    StoryChapter(() => tr('De vuelta a casa', 'Back home'),
        () => tr('Michi volvió a casa justo a tiempo para verte. Te dio el brillo de la luna con un ronroneo. Desde entonces, cuando te cuidas, ese brillo está dentro de ti. Fin 🌙',
            'Michi got home just in time to see you. He gave you the moon\'s glow with a purr. Ever since, whenever you look after yourself, that glow is inside you. The end 🌙'),
        'post_garden', 'michi_heart', StoryFx.hearts),
  ];

  /// Días distintos con algo registrado (nunca baja).
  static int get loggedDays => AppStore.instance.logs.values.where((l) => !l.isEmpty).length;

  /// Capítulos desbloqueados: el primero gratis y uno más por cada día registrado.
  static int get unlocked => math.min(chapters.length, loggedDays + 1);

  static Future<Set<int>> read() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_readKey) ?? const []).map(int.tryParse).whereType<int>().toSet();
  }

  static Future<void> markRead(int i) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getStringList(_readKey) ?? <String>[]).toSet()..add('$i');
    await p.setStringList(_readKey, s.toList());
  }

  /// ¿Hay un capítulo desbloqueado sin leer?
  static Future<bool> hasNew() async {
    final r = await read();
    for (var i = 0; i < unlocked; i++) {
      if (!r.contains(i)) return true;
    }
    return false;
  }
}

// ───────────────────────────── Estantería ─────────────────────────────

class MichiStoriesScreen extends StatefulWidget {
  const MichiStoriesScreen({super.key});

  @override
  State<MichiStoriesScreen> createState() => _MichiStoriesScreenState();
}

class _MichiStoriesScreenState extends State<MichiStoriesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  Set<int> _read = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await MichiStories.read();
    if (mounted) setState(() => _read = r);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _open(int i) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (_, __, ___) => MichiStoryReader(start: i),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: child),
      ),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final ch = MichiStories.chapters;
    final un = MichiStories.unlocked;
    final next = un < ch.length;
    return Scaffold(
      backgroundColor: C.t(0xFFFFF4F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            backgroundColor: const Color(0xFF6B4FB8),
            foregroundColor: Colors.white,
            title: Text(tr('Cuentos de Michi', "Michi's stories"), style: const TextStyle(fontWeight: FontWeight.w900)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Image.asset('assets/go/post_moon.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [const Color(0xFF3B2A78).withOpacity(0.55), const Color(0xFF3B2A78).withOpacity(0.15), C.t(0xFFFFF4F8)],
                      stops: const [0, 0.6, 1],
                    ),
                  ),
                ),
                const Positioned.fill(child: IgnorePointer(child: StoryParticles(fx: StoryFx.stars, count: 14))),
                Positioned(
                  right: 18,
                  bottom: 6,
                  child: AnimatedBuilder(
                    animation: _float,
                    builder: (_, c) => Transform.translate(offset: Offset(0, -6 * Curves.easeInOut.transform(_float.value)), child: c),
                    child: const Img('michi_letter', size: 110, fallback: Icons.pets_rounded),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 22,
                  right: 140,
                  child: Text(tr('El viaje de Michi a la Luna', "Michi's journey to the Moon"),
                      style: const TextStyle(fontSize: 21, height: 1.15, fontWeight: FontWeight.w900, color: Color(0xFF3B2A78))),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('$un de ${ch.length} capítulos', '$un of ${ch.length} chapters'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.muted)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: un / ch.length,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFEDE4FB),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF7B4FD6)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  next
                      ? tr('Cada día que registras se abre un capítulo nuevo 📖', 'Every day you log opens a new chapter 📖')
                      : tr('¡Has llegado al final del cuento! 🌙', "You've reached the end of the story! 🌙"),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF6B4FB8)),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ChapterCard(
                  index: i,
                  chapter: ch[i],
                  locked: i >= un,
                  isNew: i < un && !_read.contains(i),
                  onTap: i < un ? () => _open(i) : null,
                ),
                childCount: ch.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.index, required this.chapter, required this.locked, required this.isNew, this.onTap});
  final int index;
  final StoryChapter chapter;
  final bool locked;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x33B79CEB),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                ColorFiltered(
                  colorFilter: locked
                      ? const ColorFilter.matrix([0.33, 0.33, 0.33, 0, 20, 0.33, 0.33, 0.33, 0, 20, 0.33, 0.33, 0.33, 0, 30, 0, 0, 0, 1, 0])
                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: Image.asset('assets/go/${chapter.bg}.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: C.lavenderSoft)),
                ),
                if (!locked)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(padding: const EdgeInsets.only(bottom: 4), child: Img(chapter.pose, size: 74, fallback: Icons.pets_rounded)),
                  )
                else
                  Container(
                    color: Colors.black.withOpacity(0.25),
                    child: const Center(child: Text('🔒', style: TextStyle(fontSize: 34))),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Capítulo ${index + 1}', 'Chapter ${index + 1}'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF7B4FD6))),
                const SizedBox(height: 2),
                Text(locked ? '· · ·' : chapter.title(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, height: 1.15, fontWeight: FontWeight.w900, color: C.text)),
              ]),
            ),
          ]),
          if (isNew)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: C.pink, borderRadius: BorderRadius.circular(10)),
                child: Text(tr('¡Nuevo!', 'New!'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ───────────────────────────── Lector ─────────────────────────────

class MichiStoryReader extends StatefulWidget {
  const MichiStoryReader({super.key, required this.start});
  final int start;

  @override
  State<MichiStoryReader> createState() => _MichiStoryReaderState();
}

class _MichiStoryReaderState extends State<MichiStoryReader> with TickerProviderStateMixin {
  late final PageController _pc = PageController(initialPage: widget.start);
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  late final AnimationController _zoom = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
  late final AnimationController _type = AnimationController(vsync: this);
  late int _page = widget.start;
  final int _unlocked = MichiStories.unlocked;

  @override
  void initState() {
    super.initState();
    _startPage(_page);
  }

  void _startPage(int i) {
    if (i >= _unlocked) return;
    final len = MichiStories.chapters[i].text().characters.length;
    _type.duration = Duration(milliseconds: (len * 32).clamp(1200, 9000));
    _type.forward(from: 0);
    MichiStories.markRead(i);
  }

  @override
  void dispose() {
    _pc.dispose();
    _bob.dispose();
    _zoom.dispose();
    _type.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_type.isAnimating) {
      _type.value = 1; // primero termina de escribir
      return;
    }
    // Una página más que las desbloqueadas: la de "vuelve mañana".
    final last = math.min(_unlocked, MichiStories.chapters.length - 1);
    if (_page < last) {
      _pc.nextPage(duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = MichiStories.chapters;
    final pages = math.min(_unlocked + 1, ch.length);
    return Scaffold(
      backgroundColor: const Color(0xFF241A45),
      body: PageView.builder(
        controller: _pc,
        itemCount: pages,
        onPageChanged: (i) {
          setState(() => _page = i);
          _startPage(i);
        },
        itemBuilder: (context, i) => AnimatedBuilder(
          animation: _pc,
          builder: (context, child) {
            // Efecto de pasar página: gira un poco en 3D y se aleja.
            var d = 0.0;
            if (_pc.hasClients && _pc.position.haveDimensions) d = (_pc.page ?? _page.toDouble()) - i;
            d = d.clamp(-1.0, 1.0);
            return Transform(
              alignment: d > 0 ? Alignment.centerRight : Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(d * 0.9)
                ..scale(1 - d.abs() * 0.08),
              child: Opacity(opacity: (1 - d.abs() * 0.6).clamp(0.0, 1.0), child: child),
            );
          },
          child: i < _unlocked ? _chapterPage(i) : _lockedPage(i),
        ),
      ),
    );
  }

  Widget _chapterPage(int i) {
    final c = MichiStories.chapters[i];
    final text = c.text();
    final top = MediaQuery.of(context).padding.top;
    return Stack(fit: StackFit.expand, children: [
      // Fondo con zoom lento (efecto Ken Burns).
      AnimatedBuilder(
        animation: _zoom,
        builder: (_, child) => Transform.scale(
          scale: 1.08 + 0.08 * Curves.easeInOut.transform(_zoom.value),
          alignment: Alignment(-0.3 + 0.6 * _zoom.value, 0),
          child: child,
        ),
        child: Image.asset('assets/go/${c.bg}.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF3B2A78))),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.35), Colors.transparent, Colors.black.withOpacity(0.15), const Color(0xFF241A45).withOpacity(0.85)],
            stops: const [0, 0.25, 0.5, 1],
          ),
        ),
      ),
      Positioned.fill(child: IgnorePointer(child: StoryParticles(key: ValueKey('fx$i'), fx: c.fx))),
      // Cabecera
      Positioned(
        top: top + 6,
        left: 8,
        right: 16,
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(tr('Capítulo ${i + 1}', 'Chapter ${i + 1}'),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, shadows: [Shadow(blurRadius: 6, color: Colors.black54)])),
          ),
          Text('${i + 1}/${MichiStories.chapters.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
      ),
      // Michi
      Positioned(
        left: 0,
        right: 0,
        bottom: 300,
        child: Center(
          child: AnimatedBuilder(
            animation: _bob,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_bob.value);
              return Transform.translate(
                offset: Offset(0, -10 * t),
                child: Transform.rotate(angle: math.sin(t * math.pi) * 0.04, child: child),
              );
            },
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _bob.forward(from: 0);
              },
              child: Img(c.pose, size: 170, fallback: Icons.pets_rounded),
            ),
          ),
        ),
      ),
      // Texto del cuento
      Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: GestureDetector(
          onTap: _next,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(c.title(), style: const TextStyle(fontSize: 20, height: 1.15, fontWeight: FontWeight.w900, color: Color(0xFF3B2A78))),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: SingleChildScrollView(
                  child: AnimatedBuilder(
                    animation: _type,
                    builder: (_, __) {
                      final chars = text.characters;
                      final n = (chars.length * _type.value).round();
                      return Text.rich(
                        TextSpan(children: [
                          TextSpan(text: chars.take(n).toString()),
                          // El resto invisible para que el texto no salte al escribirse.
                          TextSpan(text: chars.skip(n).toString(), style: const TextStyle(color: Colors.transparent)),
                        ]),
                        style: const TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600, color: C.text),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedBuilder(
                  animation: _type,
                  builder: (_, __) => AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _type.isCompleted ? 1 : 0.35,
                    child: Text(
                      _page >= MichiStories.chapters.length - 1 && _unlocked >= MichiStories.chapters.length
                          ? tr('Cerrar el libro ›', 'Close the book ›')
                          : tr('Seguir ›', 'Next ›'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.pink),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _lockedPage(int i) {
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF241A45), Color(0xFF6B4FB8)]),
        ),
      ),
      const Positioned.fill(child: IgnorePointer(child: StoryParticles(fx: StoryFx.stars))),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedBuilder(
              animation: _bob,
              builder: (_, c) => Transform.translate(offset: Offset(0, -8 * Curves.easeInOut.transform(_bob.value)), child: c),
              child: Img(MichiStories.loggedDays > 0 ? 'michi_bed' : 'cat_wave', size: 170, fallback: Icons.pets_rounded),
            ),
            const SizedBox(height: 18),
            Text(tr('Continuará…', 'To be continued…'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              tr('Michi descansa para seguir su viaje. Registra tu día mañana y leerás el capítulo ${i + 1}.',
                  'Michi is resting before continuing his journey. Log your day tomorrow to read chapter ${i + 1}.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15.5, height: 1.4, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 26),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.pink, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12)),
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(tr('Hasta mañana 🌙', 'See you tomorrow 🌙'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ───────────────────────────── Efectos ─────────────────────────────

/// Partículas que flotan sobre la ilustración (pétalos, estrellas, burbujas…).
class StoryParticles extends StatefulWidget {
  const StoryParticles({super.key, required this.fx, this.count = 18});
  final StoryFx fx;
  final int count;

  @override
  State<StoryParticles> createState() => _StoryParticlesState();
}

class _P {
  _P(math.Random r)
      : x = r.nextDouble(),
        phase = r.nextDouble(),
        speed = 0.5 + r.nextDouble(),
        size = 0.7 + r.nextDouble() * 0.7,
        sway = r.nextDouble() * 2 * math.pi,
        glyph = r.nextInt(3);
  final double x, phase, speed, size, sway;
  final int glyph;
}

class _StoryParticlesState extends State<StoryParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final List<_P> _ps = List.generate(widget.count, (i) => _P(math.Random(i * 31 + widget.fx.index)));

  static const _glyphs = {
    StoryFx.petals: ['🌸', '🌷', '🍃'],
    StoryFx.sparkles: ['✨', '⭐', '✨'],
    StoryFx.bubbles: ['🫧', '🫧', '💧'],
    StoryFx.rain: ['💧', '💧', '💧'],
    StoryFx.hearts: ['💗', '💕', '💖'],
    StoryFx.stars: ['⭐', '✨', '🌟'],
    StoryFx.candy: ['🍬', '🍭', '🍓'],
    StoryFx.balloons: ['🎈', '🎈', '🎀'],
    StoryFx.leaves: ['🍂', '🍁', '🍃'],
    StoryFx.snow: ['❄️', '❄️', '✨'],
    StoryFx.sun: ['☀️', '✨', '🌼'],
    StoryFx.tropical: ['🌺', '🌴', '🌸'],
  };

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fx = widget.fx;
    // Suben: burbujas, corazones y globos. Bajan: pétalos y lluvia. Titilan: estrellas y destellos.
    final up = fx == StoryFx.bubbles || fx == StoryFx.hearts || fx == StoryFx.balloons;
    final twinkle = fx == StoryFx.stars || fx == StoryFx.sparkles || fx == StoryFx.sun;
    final rain = fx == StoryFx.rain;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      return AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(clipBehavior: Clip.none, children: [
          for (final p in _ps) _particle(p, w, h, up, twinkle, rain),
        ]),
      );
    });
  }

  Widget _particle(_P p, double w, double h, bool up, bool twinkle, bool rain) {
    final g = _glyphs[widget.fx]![p.glyph];
    final t = (_c.value * p.speed * (rain ? 3 : 1) + p.phase) % 1.0;
    double x, y, op, rot = 0;
    if (twinkle) {
      x = p.x * w;
      y = (p.phase * 0.85) * h;
      op = 0.25 + 0.75 * (0.5 + 0.5 * math.sin((t * 2 + p.sway) * math.pi * 2));
    } else {
      final yy = up ? 1.05 - t * 1.15 : -0.05 + t * 1.15;
      y = yy * h;
      x = p.x * w + (rain ? -t * 30 : math.sin(t * math.pi * 4 + p.sway) * 22);
      op = (math.sin(t * math.pi)).clamp(0.0, 1.0);
      rot = rain ? 0.3 : math.sin(t * math.pi * 2 + p.sway) * 0.6;
    }
    final size = (rain ? 12.0 : 18.0) * p.size;
    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: op.clamp(0.0, 1.0),
        child: Transform.rotate(angle: rot, child: Text(g, style: TextStyle(fontSize: size))),
      ),
    );
  }
}
