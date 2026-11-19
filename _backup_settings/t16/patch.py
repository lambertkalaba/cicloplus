import re, sys, os
root = sys.argv[1]
live = open(os.path.join(os.path.dirname(__file__), 'live.dart'), encoding='utf8').read()
p = os.path.join(root, 'lib/go/widgets/avatar_picker.dart')
s = open(p, encoding='utf8').read()
if 'avatar_maker.dart' not in s:
    s = s.replace("import 'ui.dart';", "import 'avatar_maker.dart';\nimport 'ui.dart';", 1)
s = s.replace("static bool isLook(String id) => looks.any((l) => l.id == id);",
              "static bool isLook(String id) => looks.any((l) => l.id == id) || CustomLook.parse(id) != null;")
s = s.replace("static String image(String id, [String? p]) => isLook(id) ? 'av_${id}_${p ?? pose}' : id;",
              "static String image(String id, [String? p]) =>\n      CustomLook.parse(id) != null ? '$id~${p ?? pose}' : isLook(id) ? 'av_${id}_${p ?? pose}' : id;")
# AvatarImg: avatares hechos por ella
s = s.replace("""    if (!name.startsWith('av_')) return Img(name, size: size, fallback: Icons.face_3);""",
"""    if (name.contains('~')) {
      final i = name.lastIndexOf('~');
      return CustomAvatarImg(id: name.substring(0, i), pose: name.substring(i + 1), size: size);
    }
    if (!name.startsWith('av_')) return Img(name, size: size, fallback: Icons.face_3);""")
# Tarjeta "Crea tu avatar" al principio de la hoja
anchor = """            const SizedBox(height: 14),
            Text(tr('Piel', 'Skin'),"""
card = """            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => showAvatarMaker(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [C.pinkSoft, Colors.white]),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: C.pink, width: 1.5),
                ),
                child: Row(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: C.pinkLine)),
                    child: ClipOval(
                      child: CustomAvatarImg(
                          id: CustomLook.parse(AppStore.instance.avatarId) != null ? AppStore.instance.avatarId : CustomLook.defaultId,
                          pose: 'a',
                          size: 64),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('✨ Crea tu avatar', '✨ Create your avatar'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.pinkDark)),
                      const SizedBox(height: 2),
                      Text(tr('Elige tu piel, tu peinado y el color de tu pelo.', 'Choose your skin, hairstyle and hair colour.'),
                          style: const TextStyle(fontSize: 12.5, color: C.muted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: C.pink),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text(tr('O elige uno ya hecho', 'Or pick a ready-made one'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: C.text)),
            const SizedBox(height: 14),
            Text(tr('Piel', 'Skin'),"""
assert anchor in s, 'anchor'
if 'showAvatarMaker(context)' not in s:
    s = s.replace(anchor, card, 1)
# LiveAvatar nuevo
a = s.index('/// El avatar de la pantalla Hoy')
b = s.index('/// Fila de Configuración: elegir el color de la app')
s = s[:a] + live + '\n\n' + s[b:]
open(p, 'w', encoding='utf8').write(s)

# Hoy: tocar el avatar la hace saludar; el lápiz abre la hoja.
p = os.path.join(root, 'lib/go/screens/today.dart')
s = open(p, encoding='utf8').read()
old = ": LiveAvatar(id: av, size: 140),"
new = """: Stack(clipBehavior: Clip.none, children: [
                    LiveAvatar(id: av, size: 140, onEdit: () => showAvatarPicker(context)),
                    Positioned(
                      right: 8,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: () => showAvatarPicker(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: C.pink.withValues(alpha: 0.3), blurRadius: 6)]),
                          child: Icon(Icons.edit_rounded, size: 16, color: C.pink),
                        ),
                      ),
                    ),
                  ]),"""
if old in s: s = s.replace(old, new, 1)
open(p, 'w', encoding='utf8').write(s)

# Shell: con "atrás" en Hoy, el avatar dice adiós y se cierra la app.
p = os.path.join(root, 'lib/go/screens/shell.dart')
s = open(p, encoding='utf8').read()
if 'AvatarBus' not in s:
    s = s.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';", 1)
    s = s.replace("import '../widgets/ui.dart';", "import '../widgets/avatar_maker.dart';\nimport '../widgets/ui.dart';", 1)
    s = s.replace("""    return Scaffold(
      key: _scaffold,""", """    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _back(),
      child: Scaffold(
      key: _scaffold,""", 1)
    s = s.replace("""        onPlus: () => openRegister(),
      ),
    );
  }
}""", """        onPlus: () => openRegister(),
      ),
    ),
    );
  }

  bool _leaving = false;

  /// Atrás: desde otra pestaña vuelve a Hoy; en Hoy el avatar dice adiós.
  void _back() {
    if (_tab != 0) {
      go(0);
      return;
    }
    if (_leaving) return;
    _leaving = true;
    AvatarBus.bye.value++;
    Future.delayed(const Duration(milliseconds: 1700), () {
      _leaving = false;
      SystemNavigator.pop();
    });
  }
}""", 1)
open(p, 'w', encoding='utf8').write(s)
print('ok')
