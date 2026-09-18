import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import 'app_open_controller.dart';
import 'settings_service.dart';

/// URL del Worker de Cloudflare que envía el correo de verificación con
/// nuestra propia plantilla (ver cloudflare-worker/worker.js). Se actualiza
/// aquí tras cada `wrangler deploy` si el nombre/subdominio cambiara.
/// Reactivado 2026-09 tras comprar y verificar el dominio cicloplus.com.
const String _kVerifyEmailWorkerUrl =
    'https://cicloplus-verify-email.cicloplus-app.workers.dev';

/// Misma app de Worker que _kVerifyEmailWorkerUrl, pero en la ruta que
/// envía el correo de restablecimiento de contraseña (sin necesitar sesión
/// iniciada, a diferencia de la verificación) — ver cloudflare-worker/worker.js.
const String _kResetPasswordWorkerUrl =
    'https://cicloplus-verify-email.cicloplus-app.workers.dev/reset-password';

/// Excepción con un mensaje ya listo para mostrar en pantalla (en español,
/// sin jerga técnica), para que la UI no tenga que traducir errores.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Método con el que la persona inició sesión — usado solo para mostrarlo
/// en la pantalla "Gestionar cuenta" (ver AuthService.currentSignInProvider).
enum SignInProvider { email, google, facebook }

/// Maneja registro, inicio de sesión y sesión actual usando Firebase
/// Authentication (para el correo/contraseña) y Cloud Firestore (para
/// guardar la fecha de registro de cada cuenta, que usa SubscriptionService
/// para calcular la prueba gratis de 7 días).
///
/// Antes de conectar Firebase, esta misma clase guardaba las cuentas
/// localmente en el dispositivo. Las pantallas (AuthScreen, AuthGate)
/// llaman a los mismos métodos (signUp/signIn/signOut/currentUser) y no
/// necesitaron cambiar nada.
class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _usersCollection = 'users';

  String _validateEmail(String email) {
    final trimmed = email.trim().toLowerCase();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
    if (!valid) throw AuthException('Ese correo no parece válido. Revísalo e inténtalo de nuevo.');
    return trimmed;
  }

  void _validatePassword(String password) {
    if (password.length < 6) {
      throw AuthException('La contraseña debe tener al menos 6 caracteres.');
    }
  }

  /// Traduce los códigos de error de Firebase a mensajes claros en español,
  /// sin jerga técnica — para que cualquier persona entienda qué pasó.
  AuthException _mapFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return AuthException('Ya existe una cuenta con ese correo. Intenta iniciar sesión.');
      case 'invalid-email':
        return AuthException('Ese correo no parece válido. Revísalo e inténtalo de nuevo.');
      case 'weak-password':
        return AuthException('La contraseña debe tener al menos 6 caracteres.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException('Correo o contraseña incorrectos.');
      case 'too-many-requests':
        return AuthException('Demasiados intentos. Espera un momento y vuelve a intentarlo.');
      case 'network-request-failed':
        return AuthException('No hay conexión a internet. Revisa tu conexión e inténtalo de nuevo.');
      case 'requires-recent-login':
        return AuthException('Por seguridad, vuelve a confirmar tu identidad e inténtalo de nuevo.');
      case 'account-exists-with-different-credential':
        return AuthException(
          'Ya tienes una cuenta con ese correo, registrada con otro método (correo y contraseña, Google o Facebook). Inicia sesión con el método que usaste la primera vez.',
        );
      default:
        return AuthException('Algo salió mal (${e.code}). Inténtalo de nuevo.');
    }
  }

  /// Crea una cuenta nueva en Firebase Authentication y guarda su fecha de
  /// registro en Firestore (necesaria para calcular la prueba gratis).
  Future<AppUser> signUp({required String email, required String password, String? name}) async {
    final cleanEmail = _validateEmail(email);
    _validatePassword(password);

    final fb.User fbUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      fbUser = credential.user!;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }

    // Se guarda el nombre también en el propio usuario de Firebase Auth
    // (displayName) — así el Worker de verificación puede personalizar el
    // correo ("Hola Marta:") y resendVerificationEmail puede recuperarlo
    // más adelante sin depender de que SettingsService lo tenga a mano.
    // No crítico si falla (seguimos con el registro igual).
    final cleanName = name?.trim() ?? '';
    if (cleanName.isNotEmpty) {
      try {
        await fbUser.updateDisplayName(cleanName);
      } catch (e) {
        debugPrint('CicloPlus: no se pudo guardar el nombre en Firebase Auth: $e');
      }
    }

    // A partir de aquí la cuenta de Firebase Auth YA existe — si guardar su
    // documento en Firestore falla (sin conexión, permisos, etc.), eso no
    // es un FirebaseAuthException y antes se colaba sin traducir hasta el
    // catch-all genérico de la pantalla, mostrando un error de "algo salió
    // mal" aunque la cuenta sí se hubiera creado (y un reintento fallaba
    // luego con "correo ya en uso", muy confuso). Se avisa aquí con un
    // mensaje claro sobre qué pasó de verdad.
    final createdAt = DateTime.now();
    try {
      await _db.collection(_usersCollection).doc(fbUser.uid).set({
        'email': cleanEmail,
        'createdAt': createdAt.toIso8601String(),
      });
    } catch (_) {
      throw AuthException(
        'Tu cuenta se creó, pero no se pudo terminar de configurar (revisa tu conexión). Cierra la app y vuelve a iniciar sesión con tu correo y contraseña.',
      );
    }

    // Correo/contraseña es el único método que NO confirma por sí solo que
    // el correo es real (a diferencia de Google/Facebook, que ya lo
    // verifican ellos): sin esto, cualquiera podría registrarse con un
    // correo inventado o ajeno. Se envía el enlace de confirmación de
    // Firebase; AuthGate bloquea el acceso a la app hasta que se confirme
    // (ver isCurrentUserEmailVerified/EmailVerificationScreen). No crítico
    // si falla el envío (p. ej. sin red en este instante) — la persona
    // puede pedir que se reenvíe desde esa misma pantalla de bloqueo.
    try {
      await _sendVerificationEmailViaBackend(name: cleanName.isNotEmpty ? cleanName : null);
    } catch (e) {
      debugPrint('CicloPlus: no se pudo enviar el correo de verificación: $e');
    }

    // Ver SettingsService.seedGardenBloomOnAccountCreation: que el jardín
    // de Hoy arranque en floración máxima en vez de marchito, como primera
    // impresión de la cuenta recién creada.
    try {
      await AppOpenController.instance.seedBloomForNewAccount();
    } catch (e) {
      debugPrint('CicloPlus: no se pudo sembrar la floración del jardín (signUp): $e');
    }

    return AppUser(id: fbUser.uid, email: cleanEmail, createdAt: createdAt);
  }

  /// Inicia sesión con una cuenta existente.
  Future<AppUser> signIn({required String email, required String password}) async {
    final cleanEmail = _validateEmail(email);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final fbUser = credential.user!;
      return _loadAppUser(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  /// Pide al Worker de Cloudflare (misma app que la verificación, ruta
  /// /reset-password) que genere el enlace de restablecimiento y lo envíe
  /// con nuestra propia plantilla lila vía Resend, en vez del correo
  /// genérico de Firebase. No necesita sesión iniciada (a diferencia de la
  /// verificación) porque en este punto la persona no ha iniciado sesión
  /// todavía.
  ///
  /// Decisión explícita del usuario (2026-09): a diferencia de antes, SÍ
  /// se revela si la cuenta existe o no (valor de retorno `true`/`false`),
  /// para poder avisar con claridad "esa cuenta no existe" en vez de un
  /// mensaje genérico — asumiendo el riesgo de que alguien use este
  /// formulario para averiguar qué correos tienen cuenta en CicloPlus.
  /// Solo se lanza AuthException en casos claros de error (correo con
  /// formato inválido, sin conexión, etc.), nunca por "cuenta no
  /// encontrada" (eso ahora se indica devolviendo `false`).
  Future<bool> sendPasswordResetEmail(String email) async {
    final cleanEmail = _validateEmail(email);
    try {
      final resp = await http.post(
        Uri.parse(_kResetPasswordWorkerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': cleanEmail}),
      );
      if (resp.statusCode != 200) {
        debugPrint(
          'CicloPlus: el Worker de restablecimiento devolvió ${resp.statusCode}: ${resp.body}',
        );
        throw AuthException(
          'No se pudo enviar el correo de restablecimiento. Inténtalo de nuevo.',
        );
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['exists'] != false;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('CicloPlus: fallo al pedir el restablecimiento de contraseña: $e');
      throw AuthException(
        'No se pudo enviar el correo de restablecimiento. Inténtalo de nuevo.',
      );
    }
  }

  /// Inicia sesión (o crea la cuenta, si es la primera vez) usando Google.
  /// A diferencia de signUp/signIn con correo, Google ya confirma que el
  /// correo es real, así que no hace falta pedir contraseña — Firebase crea
  /// la cuenta automáticamente en el primer inicio de sesión.
  ///
  /// Si la persona todavía no tiene un nombre guardado (primera vez), se
  /// usa el nombre de su cuenta de Google como valor inicial — puede
  /// cambiarlo después desde Configuración > Datos, igual que si se
  /// hubiera registrado con correo.
  Future<AppUser> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // La persona cerró el selector de cuenta sin elegir ninguna — no
        // es un error real, solo canceló.
        throw AuthException('Inicio de sesión cancelado.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return _loadOrCreateSocialUser(userCredential.user!, fallbackName: googleUser.displayName);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  /// Común a Google y Facebook: si es la primera vez que esta persona
  /// inicia sesión (no existe su documento en Firestore todavía), crea el
  /// documento de usuario igual que signUp, y guarda `fallbackName` (nombre
  /// que entrega Google/Facebook) como nombre de perfil local — igual que
  /// el nombre del registro por correo, ese campo vive en SharedPreferences
  /// (SettingsService), no en este documento de Firestore. Solo lo guarda
  /// si todavía no había ninguno (no pisa un nombre que la persona ya
  /// haya personalizado en Configuración en otro dispositivo/sesión).
  Future<AppUser> _loadOrCreateSocialUser(fb.User fbUser, {String? fallbackName}) async {
    final docRef = _db.collection(_usersCollection).doc(fbUser.uid);
    try {
      final doc = await docRef.get();

      if (!doc.exists) {
        final createdAt = DateTime.now();
        await docRef.set({
          'email': fbUser.email ?? '',
          'createdAt': createdAt.toIso8601String(),
        });
        if (fallbackName != null && fallbackName.trim().isNotEmpty) {
          final settings = SettingsService();
          final existingName = await settings.loadProfileName();
          if (existingName == null || existingName.isEmpty) {
            await settings.saveProfileName(fallbackName);
          }
        }
        // Ver el mismo bloque en signUp() — misma primera impresión de
        // jardín en floración máxima para cuentas nuevas de Google/Facebook.
        // No hace falta enviar correo de confirmación aquí: esos proveedores
        // ya confirman el correo ellos mismos antes de dar el token.
        try {
          await AppOpenController.instance.seedBloomForNewAccount();
        } catch (e) {
          debugPrint('CicloPlus: no se pudo sembrar la floración del jardín (social): $e');
        }
        return AppUser(id: fbUser.uid, email: fbUser.email ?? '', createdAt: createdAt);
      }
    } catch (e) {
      // Igual que en signUp: en este punto Google/Facebook YA autenticó a
      // la persona (Firebase Auth ya tiene la sesión abierta) — un fallo
      // de Firestore aquí no debe disfrazarse de "algo salió mal" genérico.
      if (e is AuthException) rethrow;
      throw AuthException(
        'Iniciaste sesión, pero no se pudo terminar de configurar tu cuenta (revisa tu conexión). Vuelve a intentarlo.',
      );
    }

    return _loadAppUser(fbUser);
  }

  /// Sesión anónima (sin correo ni contraseña) para quien solo quiere ver
  /// el embarazo de su pareja (ver AuthScreen > "¿Solo quieres ver el
  /// embarazo de tu pareja?" y PartnerViewerHomeScreen). Firebase le asigna
  /// un uid real igual que cualquier otra cuenta — firestore.rules solo
  /// exige `request.auth != null`, así que esta cuenta puede aceptar un
  /// código de invitación y leer `pregnancy/data` exactamente igual que una
  /// cuenta con correo, sin necesitar registro.
  ///
  /// Requiere que el proveedor "Anonymous" esté habilitado en Firebase
  /// Console > Authentication > Sign-in method.
  Future<AppUser> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final fbUser = credential.user!;
      return AppUser(id: fbUser.uid, email: '', createdAt: fbUser.metadata.creationTime ?? DateTime.now());
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  /// true si la sesión activa es una cuenta anónima (ver signInAnonymously)
  /// — AuthGate lo usa para decidir si mostrar la app completa o solo la
  /// vista de socio/pareja de solo lectura.
  bool get isCurrentUserAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// true si NO hace falta confirmar el correo para entrar a la app: ya sea
  /// porque Firebase confirma que sí lo confirmó (`emailVerified`), porque
  /// no hay ninguna sesión activa, o porque el proveedor no usa correo
  /// propio de CicloPlus (Google/Facebook ya lo confirman ellos antes de dar
  /// el token; la sesión anónima de socio/pareja no tiene correo). Lee el
  /// valor que Firebase Auth ya tiene en caché localmente — para el dato
  /// más reciente (por si se confirmó el correo hace un momento en otra
  /// pestaña/dispositivo) hay que llamar antes a [reloadAndCheckEmailVerified].
  bool get isCurrentUserEmailVerified {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return true;
    if (fbUser.isAnonymous) return true;
    if (currentSignInProvider() != SignInProvider.email) return true;
    return fbUser.emailVerified;
  }

  /// Pide al Worker de Cloudflare (cloudflare-worker/worker.js) que genere
  /// el enlace de verificación y lo envíe con nuestra propia plantilla (con
  /// botón) vía Resend, en vez de dejar que Firebase mande su correo
  /// automático sin botón y con más riesgo de caer en spam. Se autentica
  /// mandando el token de la sesión actual — el Worker solo manda el
  /// correo a la dirección de ESA cuenta, nunca a otra. Reactivado 2026-09
  /// tras comprar y verificar cicloplus.com en Resend.
  Future<void> _sendVerificationEmailViaBackend({String? name}) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      throw AuthException('No hay ninguna sesión activa.');
    }
    final idToken = await fbUser.getIdToken();
    // Si no se pasa un nombre explícito (p. ej. al reenviar desde
    // EmailVerificationScreen), se usa el displayName que quedó guardado
    // en Firebase Auth durante signUp — así el correo sigue personalizado.
    final effectiveName = (name?.trim().isNotEmpty ?? false) ? name!.trim() : fbUser.displayName;
    final resp = await http.post(
      Uri.parse(_kVerifyEmailWorkerUrl),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (effectiveName != null && effectiveName.isNotEmpty) 'name': effectiveName,
      }),
    );
    if (resp.statusCode != 200) {
      debugPrint(
        'CicloPlus: el Worker de verificación devolvió ${resp.statusCode}: ${resp.body}',
      );
      throw AuthException(
        'No se pudo enviar el correo de verificación. Inténtalo de nuevo.',
      );
    }
  }

  // Método alternativo, en desuso desde que se verificó el dominio (se deja
  // comentado por si algún día se quita el dominio y hace falta volver al
  // envío nativo de Firebase sin coste):
  //
  // Future<void> _sendVerificationEmailNative() async {
  //   final fbUser = _auth.currentUser;
  //   if (fbUser == null) {
  //     throw AuthException('No hay ninguna sesión activa.');
  //   }
  //   try {
  //     await fbUser.sendEmailVerification();
  //   } on fb.FirebaseAuthException catch (e) {
  //     throw _mapFirebaseError(e);
  //   } catch (e) {
  //     debugPrint('CicloPlus: no se pudo enviar el correo de verificación: $e');
  //     throw AuthException(
  //       'No se pudo enviar el correo de verificación. Inténtalo de nuevo.',
  //     );
  //   }
  // }

  /// Vuelve a pedirle a Firebase el estado más reciente de la cuenta (por si
  /// la persona ya confirmó el correo y el caché local de `currentUser`
  /// todavía no se había enterado) y devuelve si ya se puede pasar. Se usa
  /// desde el botón "Ya confirmé mi correo" de EmailVerificationScreen.
  Future<bool> reloadAndCheckEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {
      // Sin red u otro fallo pasajero: se informa como "todavía no
      // confirmado" en vez de lanzar, para que el botón simplemente no
      // avance en vez de mostrar un error técnico en esta pantalla de espera.
    }
    return isCurrentUserEmailVerified;
  }

  /// Reenvía el correo de confirmación — botón "Reenviar correo" de
  /// EmailVerificationScreen, para cuando no llegó o se borró sin querer.
  Future<void> resendVerificationEmail() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      throw AuthException('No hay ninguna sesión activa.');
    }
    try {
      await _sendVerificationEmailViaBackend();
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<void> signOut() async {
    // Cierra también la sesión de Google/Facebook si estaba activa —
    // si no, la próxima vez que la persona toque "Continuar con Google"
    // podría volver a entrar sin que se le pida elegir cuenta.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Borra la cuenta por completo y de forma irreversible: el documento de
  /// Firestore (`users/{uid}`, que incluye la fecha de registro usada para
  /// la prueba gratis) y la propia cuenta en Firebase Authentication. Cierra
  /// también la sesión de Google/Facebook si estaba activa, igual que
  /// `signOut`.
  ///
  /// Los registros del ciclo (colección `days`) y los ajustes locales
  /// (SharedPreferences) NO se borran aquí — la pantalla que llama a este
  /// método debe borrarlos antes (StorageService.deleteAll +
  /// SettingsService.clearAll), para que "Borrar cuenta" borre
  /// absolutamente todo y no deje nada huérfano.
  ///
  /// Requiere que la sesión se haya reautenticado recientemente (ver
  /// `reauthenticate`) — si no, Firebase lanza `requires-recent-login` y
  /// esto falla con un AuthException claro en vez de un error críptico.
  Future<void> deleteAccount() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      throw AuthException('No hay ninguna sesión activa.');
    }

    try {
      await _db.collection(_usersCollection).doc(fbUser.uid).delete();
      await fbUser.delete();
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  /// Devuelve el usuario con sesión activa, o null si nadie ha iniciado sesión.
  /// Firebase recuerda la sesión entre aperturas de la app automáticamente.
  Future<AppUser?> currentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _loadAppUser(fbUser);
  }

  /// Con qué método inició sesión la persona actual — para mostrarlo en la
  /// pantalla "Gestionar cuenta" (por ejemplo "Google" en vez del correo
  /// técnico del proveedor). Se lee de `providerData`, que Firebase llena
  /// automáticamente según el método usado (password/google.com/
  /// facebook.com); no requiere guardar nada aparte.
  SignInProvider currentSignInProvider() {
    final fbUser = _auth.currentUser;
    if (fbUser == null || fbUser.providerData.isEmpty) return SignInProvider.email;
    final providerId = fbUser.providerData.first.providerId;
    switch (providerId) {
      case 'google.com':
        return SignInProvider.google;
      case 'facebook.com':
        return SignInProvider.facebook;
      default:
        return SignInProvider.email;
    }
  }

  /// Combina los datos de Firebase Auth (id, correo) con la fecha de
  /// registro guardada en Firestore, para armar el AppUser que usa el
  /// resto de la app.
  Future<AppUser> _loadAppUser(fb.User fbUser) async {
    Map<String, dynamic>? data;
    // Antes, si esta consulta a Firestore fallaba (sin red al abrir la
    // app, por ejemplo), se lanzaba AuthException aquí — y como
    // AuthGate._restoreSession no tenía try/catch alrededor de
    // currentUser(), la app se quedaba colgada en la pantalla de carga
    // para siempre, aunque Firebase Auth SÍ sabe localmente (sin red)
    // que la sesión sigue activa. Se corrige tratando el fallo de
    // Firestore como "no crítico" igual que el bloque de más abajo:
    // seguimos con la fecha de creación que ya trae Firebase Auth
    // (fbUser.metadata.creationTime, exacta y disponible sin conexión)
    // en vez de bloquear la entrada a la app.
    bool firestoreUnavailable = false;
    try {
      final doc = await _db.collection(_usersCollection).doc(fbUser.uid).get();
      data = doc.data();
    } catch (_) {
      firestoreUnavailable = true;
    }

    DateTime createdAt;
    if (data != null && data['createdAt'] != null) {
      createdAt = DateTime.parse(data['createdAt'] as String);
    } else {
      // Si por algún motivo no existe el documento (p. ej. la cuenta se
      // creó antes de que existiera esta lógica) o Firestore no respondió,
      // usamos la fecha de creación que Firebase Auth ya trae, y la
      // guardamos para la próxima vez (solo si el problema no fue
      // justamente de conexión, para no intentar otra llamada de red que
      // sabemos que va a fallar).
      createdAt = fbUser.metadata.creationTime ?? DateTime.now();
      if (!firestoreUnavailable) {
        try {
          await _db.collection(_usersCollection).doc(fbUser.uid).set({
            'email': fbUser.email,
            'createdAt': createdAt.toIso8601String(),
          }, SetOptions(merge: true));
        } catch (_) {
          // No crítico: seguimos con la fecha calculada aunque no se haya
          // podido guardar todavía — se reintentará la próxima vez que se
          // cargue esta cuenta, sin bloquear el inicio de sesión de ahora.
        }
      }
    }

    return AppUser(id: fbUser.uid, email: fbUser.email ?? '', createdAt: createdAt);
  }

  /// Vuelve a confirmar la identidad de la persona con sesión activa, antes
  /// de una acción destructiva e irreversible (borrar todos los datos).
  /// Según el proveedor con el que inició sesión:
  /// - email/contraseña: reautentica con la contraseña que introduce ahora.
  /// - Google/Facebook: repite el flujo de login de ese proveedor — no hay
  ///   contraseña de CicloPlus que pedir, así que "demostrar que es ella"
  ///   equivale a volver a iniciar sesión con la misma cuenta social.
  ///
  /// Lanza AuthException con un mensaje ya listo para mostrar si la
  /// contraseña es incorrecta, se cancela el login social, o no hay sesión
  /// activa. Si todo va bien, no devuelve nada (no lanzar == éxito).
  Future<void> reauthenticate({String? password}) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      throw AuthException('No hay ninguna sesión activa.');
    }

    final provider = currentSignInProvider();
    try {
      switch (provider) {
        case SignInProvider.email:
          if (password == null || password.isEmpty) {
            throw AuthException('Introduce tu contraseña para continuar.');
          }
          final credential = fb.EmailAuthProvider.credential(
            email: fbUser.email ?? '',
            password: password,
          );
          await fbUser.reauthenticateWithCredential(credential);
          break;

        case SignInProvider.google:
          final googleUser = await GoogleSignIn().signIn();
          if (googleUser == null) {
            throw AuthException('Confirmación cancelada.');
          }
          final googleAuth = await googleUser.authentication;
          final credential = fb.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await fbUser.reauthenticateWithCredential(credential);
          break;

        case SignInProvider.facebook:
          // El inicio de sesión con Facebook se retiró de la app (ver
          // auth_screen.dart); las cuentas antiguas vinculadas a Facebook ya
          // no pueden reautenticarse por esta vía.
          throw AuthException('El inicio de sesión con Facebook ya no está disponible. Contacta con soporte para recuperar tu cuenta.');
      }
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }
}
