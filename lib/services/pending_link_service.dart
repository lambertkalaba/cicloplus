import 'package:flutter/foundation.dart';

/// Guarda EN MEMORIA (nunca en disco: un código viejo no debe sobrevivir a
/// un reinicio real de la app) el código de invitación que llegó por un
/// enlace (ver DeepLinkService), para que la primera pantalla de "pega tu
/// código" que se construya — Ver seguimiento de tu pareja
/// (PartnerViewerHomeScreen) o Invitar a un socio si ya hay cuenta
/// (InvitePartnerScreen) — lo rellene sola en su campo de texto. La
/// persona sigue teniendo que tocar "Vincularme" para confirmar: esto
/// nunca vincula nada por su cuenta.
class PendingLinkCode extends ChangeNotifier {
  PendingLinkCode._();
  static final PendingLinkCode instance = PendingLinkCode._();

  String? _code;

  /// Solo para comprobar si hay algo pendiente sin consumirlo todavía
  /// (usado por el listener, que decide él mismo cuándo consumir).
  String? get code => _code;

  void set(String code) {
    _code = code;
    notifyListeners();
  }

  /// Lee el código pendiente y lo borra a la vez, para que nunca se use
  /// dos veces (por ejemplo si la persona pasa de la pantalla anónima a
  /// una cuenta completa dentro de la misma sesión de la app).
  String? consume() {
    final c = _code;
    _code = null;
    return c;
  }
}
