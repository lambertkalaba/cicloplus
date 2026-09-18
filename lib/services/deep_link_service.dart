import 'dart:async';

import 'package:app_links/app_links.dart';

import 'pending_link_service.dart';

/// Escucha el enlace de invitación (cicloplus://link?code=XXXX) que
/// codifica el QR de "Invitar a un socio" (ver InvitePartnerScreen). Al
/// escanearlo con la cámara NORMAL del móvil (no hace falta ninguna
/// cámara dentro de la app — eso fue lo que rompió el arranque la vez que
/// se probó con mobile_scanner, ver historial en pubspec.yaml y
/// android/app/build.gradle.kts), Android abre CicloPlus directamente con
/// este enlace si ya está instalada.
///
/// Solo guarda el código en PendingLinkCode — no navega ni vincula nada
/// por su cuenta: la pantalla de "pega tu código" que corresponda sigue
/// exigiendo que la persona confirme tocando "Vincularme", igual que si
/// lo hubiera pegado a mano.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {
      // Sin enlace inicial o error leyéndolo al arrancar: no es grave, la
      // persona simplemente no verá el código precargado esta vez y puede
      // pegarlo a mano como siempre.
    }
    _sub ??= _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void _handle(Uri uri) {
    final code = uri.queryParameters['code']?.trim();
    if (code != null && code.isNotEmpty) {
      PendingLinkCode.instance.set(code);
    }
  }
}
